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

  // Ambil data profil lama dari Firestore saat halaman dimuat
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
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("Gagal memuat data: $e", Colors.red);
    }
  }

  // Simpan perubahan nama & username ke Firestore
  void _saveChanges() async {
    if (currentUserId == null) return;

    String newName = nameController.text.trim();
    String newUsername = usernameController.text.trim().toLowerCase();

    if (newName.isEmpty || newUsername.isEmpty) {
      _showSnackBar("Nama dan Username tidak boleh kosong!", Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'name': newName,
        'username': newUsername,
      });

      _showSnackBar("Profil berhasil diperbarui!", Colors.green);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("Gagal menyimpan perubahan: $e", Colors.red);
    }
  }

  // Helper: tampilkan snackbar
  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
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
    const themeBlue = Color(0xFF008BED);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: themeBlue),
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  children: [
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
                      builder: (context, snapshot) {
                        String previewName = "No Name";
                        String previewUsername = "username";

                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          previewName = data['name'] ?? "No Name";
                          previewUsername = data['username'] ?? "username";
                        }

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.95),
                                  Colors.white.withValues(alpha: 0.88),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Sederhana: hanya teks preview (avatar dihapus)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        previewName,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "@$previewUsername",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Name",
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "Your full name",
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: themeBlue, width: 1.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Username",
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        hintText: "username (lowercase)",
                        prefixIcon: const Icon(Icons.alternate_email),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: themeBlue, width: 1.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Chapri ID",
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: currentUserId ?? "Unknown ID",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
    );
  }
}
