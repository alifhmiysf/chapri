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
  Map<String, dynamic>? userData;
  String? userId;
  bool isLoading = false;

  Future<void> searchUser() async {
    final String searchUsername = idController.text.trim().toLowerCase();
    if (searchUsername.isEmpty) return;

    setState(() {
      isLoading = true;
      userData = null;
      userId = null;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: searchUsername)
          .get();

      // Pastikan widget masih mounted sebelum menggunakan context atau setState
      if (!mounted) return;

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final foundData = doc.data();
        final foundId = doc.id;

        setState(() {
          userData = foundData;
          userId = foundId;
          isLoading = false;
        });

        // Tampilkan modal hasil pencarian — gunakan dialogContext di builder
        showDialog(
          context: context,
          builder: (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.person, size: 40, color: Colors.blue),
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
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Gunakan dialogContext agar tidak bergantung pada outer context setelah async
                        Navigator.of(dialogContext).pop(); // tutup modal
                        Navigator.of(dialogContext).push(
                          MaterialPageRoute(
                            builder: (_) => ChatRoomPage(
                              username: userData!['name'] ?? "No Name",
                              receiverId: userId!,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        "Start Chat →",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        // Pastikan masih mounted sebelum setState / snackbar
        if (!mounted) return;
        setState(() => isLoading = false);
        showErrorSnackBar("User tidak ditemukan");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showErrorSnackBar("Terjadi kesalahan: $e");
    }
  }

  void showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Ilustrasi kosong
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_search, size: 60, color: Colors.blue),
              ),

              const SizedBox(height: 25),

              const Text(
                "Find your friends",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Search by Chapri username to start chatting",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: idController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => searchUser(),
                decoration: InputDecoration(
                  hintText: "Example: alifahmi",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: searchUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Search",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
