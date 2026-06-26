import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_page.dart';
import 'package:chapri/features/chat/chat_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  DateTime? lastBackPressTime;

  // Fungsi logout
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
          MaterialPageRoute(builder: (context) => const ChatPage()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal logout: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Logika back button
  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (lastBackPressTime == null ||
        now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
      lastBackPressTime = now;
      // Back pertama → kembali ke ChatPage
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tekan sekali lagi untuk keluar"),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    // Back kedua → keluar aplikasi
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: currentUserId == null
            ? const Center(child: Text("User tidak terautentikasi"))
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUserId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text("Gagal memuat profil"));
                  }

                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  String name = userData['name'] ?? 'No Name';
                  String username = userData['username'] ?? 'username';
                  bool isOnline = userData['isOnline'] ?? false;
                  Timestamp? lastSeen = userData['lastSeen'] as Timestamp?;

                  String statusText = isOnline
                      ? "Online"
                      : lastSeen != null
                          ? "Terakhir dilihat ${lastSeen.toDate().hour}:${lastSeen.toDate().minute.toString().padLeft(2, '0')}"
                          : "Offline";

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const CircleAvatar(
                          radius: 55,
                          child: Icon(Icons.person, size: 60),
                        ),
                        const SizedBox(height: 20),
                        Text(name,
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text("@$username",
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 10),
                        Text(statusText,
                            style: TextStyle(
                                color: isOnline ? Colors.green : Colors.grey,
                                fontSize: 14,
                                fontStyle: FontStyle.italic)),
                        const SizedBox(height: 25),
                        profileMenu(
                          icon: Icons.edit,
                          title: "Edit Profile",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const EditProfilePage()),
                            );
                          },
                        ),
                        profileMenu(icon: Icons.notifications, title: "Notifications"),
                        profileMenu(icon: Icons.lock, title: "Privacy"),
                        profileMenu(
                          icon: Icons.logout,
                          title: "Logout",
                          onTap: _logout,
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget profileMenu({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
