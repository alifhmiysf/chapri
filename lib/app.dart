import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/splash_page.dart';

class ChapriApp extends StatefulWidget {
  const ChapriApp({super.key});

  @override
  State<ChapriApp> createState() => _ChapriAppState();
}

class _ChapriAppState extends State<ChapriApp> with WidgetsBindingObserver {
  dynamic _authSubscription;
  Timer? _heartbeatTimer;

  Future<void> setOnlineStatus(bool isOnline) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
          'activeRoom': null, // default null di root app
        });
      } catch (e) {
        debugPrint("Gagal memperbarui status online: $e");
      }
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        FirebaseFirestore.instance.collection('users').doc(uid).update({
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Dengarkan perubahan login
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        setOnlineStatus(true);
        _startHeartbeat();
      } else {
        setOnlineStatus(false);
        _stopHeartbeat();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _stopHeartbeat();
    setOnlineStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (FirebaseAuth.instance.currentUser == null) return;

    if (state == AppLifecycleState.resumed) {
      // User kembali ke Chapri → online
      setOnlineStatus(true);
      _startHeartbeat();
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.inactive ||
               state == AppLifecycleState.detached) {
      // User minimize / pindah aplikasi / tutup → offline
      setOnlineStatus(false);
      _stopHeartbeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chapri Messenger',
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
    );
  }
}
