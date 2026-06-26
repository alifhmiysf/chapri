import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../chat/chat_room_page.dart';

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final idController = TextEditingController();
  
  // Variabel untuk menyimpan data user yang ditemukan dari Firebase
  Map<String, dynamic>? userData;
  String? userId;
  bool isLoading = false;

  // Fungsi untuk mencari user langsung ke Cloud Firestore
  void searchUser() async {
    String searchUsername = idController.text.trim().toLowerCase();

    if (searchUsername.isEmpty) return;

    setState(() {
      isLoading = true;
      userData = null;
      userId = null;
    });

    try {
      // Mencari di koleksi 'users' yang field 'username'-nya sama dengan input
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: searchUsername)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Jika user ditemukan
        setState(() {
          userData = querySnapshot.docs.first.data();
          userId = querySnapshot.docs.first.id; // Ini mengambil UID dokumen user
          isLoading = false;
        });
      } else {
        // Jika user tidak ditemukan
        setState(() {
          isLoading = false;
        });
        showErrorSnackBar("User tidak ditemukan");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showErrorSnackBar("Terjadi kesalahan: $e");
    }
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Contact"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Search using Chapri Username",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: idController,
              // Mengubah input ke huruf kecil secara otomatis agar cocok dengan Firestore jika disimpan lowercase
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => searchUser(),
              decoration: InputDecoration(
                hintText: "Example: alifahmi",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: searchUser,
                child: isLoading 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text("Search"),
              ),
            ),
            const SizedBox(height: 30),

            // Tampilkan Card jika user berhasil ditemukan
            if (userData != null && userId != null)
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 35,
                        child: Icon(
                          Icons.person,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        userData!['name'] ?? "No Name",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "@${userData!['username'] ?? "username"}",
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Berpindah ke halaman ChatRoomPage dengan data asli Firebase
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatRoomPage(
                                  username: userData!['name'] ?? "No Name",
                                  receiverId: userId!, // UID dinamis hasil pencarian
                                ),
                              ),
                            );
                          },
                          child: const Text("Start Chat →"),
                        ),
                      )
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}