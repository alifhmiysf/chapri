import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 1. Fungsi untuk mengambil data profil lama dari Firestore
  void _loadUserData() async {
    if (currentUserId == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          nameController.text = data['name'] ?? '';
          usernameController.text = data['username'] ?? '';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar("Gagal memuat data: $e", Colors.red);
    }
  }

  // 2. Fungsi untuk menyimpan perubahan data ke Firestore
  void _saveChanges() async {
    if (currentUserId == null) return;

    String newName = nameController.text.trim();
    String newUsername = usernameController.text.trim().toLowerCase();

    if (newName.isEmpty || newUsername.isEmpty) {
      _showSnackBar("Nama dan Username tidak boleh kosong!", Colors.orange);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Update dokumen user berdasarkan UID di Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'name': newName,
        'username': newUsername,
      });

      _showSnackBar("Profil berhasil diperbarui!", Colors.green);
      Navigator.pop(context); // Kembali ke halaman sebelumnya setelah berhasil
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar("Gagal menyimpan perubahan: $e", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Loading screen awal saat ambil data
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    child: Icon(
                      Icons.person,
                      size: 55,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Input Nama
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Input Username
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: "Username",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Display UID (Dibuat read-only / disabled karena ID bawaan akun tidak boleh diubah)
                  TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: "Chapri ID",
                      hintText: currentUserId ?? "Unknown ID",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Tombol Save Changes
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}