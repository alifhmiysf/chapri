import 'package:chapri/features/home/home_page.dart';
import 'package:chapri/features/welcome/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Fungsi untuk logout dari Firebase Auth
// Fungsi untuk logout dari Firebase Auth secara total
  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        // Mengarahkan ke halaman login dan menghapus seluruh stack halaman di belakangnya
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const WelcomePage(), // <-- Ganti LoginPage() sesuai dengan nama class halaman login-mu
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: currentUserId == null
          ? const Center(child: Text("User tidak terautentikasi"))
          : StreamBuilder<DocumentSnapshot>(
              // Mengambil stream data user secara real-time dari Firestore
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

                // Membaca data dari dokumen Firestore
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                String name = userData['name'] ?? 'No Name';
                String username = userData['username'] ?? 'username';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const CircleAvatar(
                        radius: 55,
                        child: Icon(
                          Icons.person,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Nama Dinamis
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      
                      // Username Dinamis
                      Text(
                        "@$username",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Box Chapri ID (Menggunakan UID asli user dari Firebase Auth)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Your Chapri ID",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentUserId!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16, // Ukuran disesuaikan karena UID Firebase cukup panjang
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            OutlinedButton.icon(
                              onPressed: () {
                                // Fungsi menyalin ID asli ke clipboard HP
                                Clipboard.setData(ClipboardData(text: currentUserId!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("ID copied to clipboard"),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text("Copy ID"),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Menu Edit Profile
                      profileMenu(
                        icon: Icons.edit,
                        title: "Edit Profile",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfilePage(),
                            ),
                          );
                        },
                      ),
                      
                      profileMenu(
                        icon: Icons.notifications,
                        title: "Notifications",
                      ),
                      
                      profileMenu(
                        icon: Icons.lock,
                        title: "Privacy",
                      ),
                      
                      // Menu Logout yang sudah berfungsi
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
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}