import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'schoolchildren' if (dart.library.html) 'dart:html' as html;

import 'core/theme/app_theme.dart';
import 'features/splash/splash_page.dart';

class ChapriApp extends StatefulWidget {
  const ChapriApp({super.key});

  @override
  State<ChapriApp> createState() => _ChapriAppState();
}

class _ChapriAppState extends State<ChapriApp> with WidgetsBindingObserver {
  dynamic _authSubscription;

  Future<void> setOnlineStatus(bool isOnline) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("Gagal memperbarui status online: $e");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        setOnlineStatus(true);
      } else {
        setOnlineStatus(false);
      }
    });

    if (kIsWeb) {
      _initWebListener();
    }
  }

  void _initWebListener() {
    try {
      html.window.onBeforeUnload.listen((event) {
        setOnlineStatus(false);
      });
    } catch (e) {
      debugPrint("Web listener gagal: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      setOnlineStatus(true);
    } else {
      setOnlineStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chapri Messenger',
      theme: AppTheme.lightTheme,
      home: const SplashPage(), // root aplikasi
    );
  }
}
