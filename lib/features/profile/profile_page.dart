import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_page.dart';
import 'package:chapri/features/welcome/welcome_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  DateTime? lastBackPressTime;

  late final Stream<DocumentSnapshot> _userProfileStream;

  @override
  void initState() {
    super.initState();
    if (currentUserId != null) {
      _userProfileStream = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .snapshots();
    }
  }

  void _logout() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal logout: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handlePopInvoked(bool didPop) async {
    if (didPop) return;

    final now = DateTime.now();
    if (lastBackPressTime == null || now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
      lastBackPressTime = now;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tekan sekali lagi untuk keluar"), duration: Duration(seconds: 2)),
        );
      }
      return;
    }

    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _handlePopInvoked(didPop),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x0F008BED), Color(0x08FFFFFF)],
            ),
          ),
          child: SafeArea(
            child: currentUserId == null
                ? const Center(child: Text("User tidak terautentikasi"))
                : StreamBuilder<DocumentSnapshot>(
                    stream: _userProfileStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                      final String name = userData['name'] ?? 'No Name';
                      final String username = userData['username'] ?? 'username';
                      final String photoUrl = (userData['photoUrl'] ?? "").toString();

                      return Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.28),
                                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.35))),
                                ),
                                child: Row(
                                  children: [
                                    _buildProfileImage(photoUrl, name),
                                    const SizedBox(width: 18),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text("@$username")])),
                                    IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())), icon: const Icon(Icons.edit, color: Color(0xFF008BED))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                                ),
                                child: ListView(
                                  children: [
                                    _buildMenuRow(icon: Icons.person, title: "Edit Profile", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()))),
                                    _buildMenuRow(icon: Icons.notifications, title: "Notifications"),
                                    _buildMenuRow(icon: Icons.lock, title: "Privacy"),
                                    const Divider(),
                                    _buildMenuRow(icon: Icons.logout, title: "Logout", titleColor: Colors.red, onTap: _logout),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(String photoUrl, String name) => Stack(
    clipBehavior: Clip.none,
    children: [
      CircleAvatar(radius: 44, backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null, child: photoUrl.isEmpty ? Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)) : null),
      Positioned(right: -6, bottom: -6, child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())), child: const CircleAvatar(radius: 16, backgroundColor: Color(0xFF008BED), child: Icon(Icons.camera_alt, size: 16, color: Colors.white)))),
    ],
  );

  Widget _buildMenuRow({required IconData icon, required String title, VoidCallback? onTap, Color? titleColor}) => ListTile(
    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF008BED))),
    title: Text(title, style: TextStyle(color: titleColor ?? Colors.black87, fontWeight: FontWeight.w600)),
    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    onTap: onTap,
  );
}