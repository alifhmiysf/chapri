import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRoomPage extends StatefulWidget {
  final String username;
  final String receiverId; 

  const ChatRoomPage({
    super.key,
    required this.username,
    required this.receiverId,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final messageController = TextEditingController();
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Membuat Chat Room ID yang konsisten antara 2 orang
  String getChatRoomId(String user1, String user2) {
    if (user1.compareTo(user2) > 0) {
      return "${user1}_$user2";
    } else {
      return "${user2}_$user1";
    }
  }

  // Fungsi untuk mengirim pesan ke Firestore
  void sendMessage() async {
    if (messageController.text.trim().isEmpty || currentUserId == null) return;

    String chatRoomId = getChatRoomId(currentUserId!, widget.receiverId);
    String messageText = messageController.text.trim();
    messageController.clear(); 

    // 1. Simpan pesan ke dalam sub-koleksi room chat tersebut
    await FirebaseFirestore.instance
        .collection('chat_rooms') // Disamakan menjadi 'chat_rooms' agar sinkron dengan ChatPage
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(), 
    });

    // 2. BAGIAN PENTING: Set/Update dokumen utama room chat agar lolos filter di ChatPage
    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .set({
      'participants': [currentUserId, widget.receiverId], // Array pencarian riwayat chat
      'lastMessage': messageText,                         // Menampilkan cuplikan pesan terakhir
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // Menggunakan merge agar tidak menimpa field lama yang sudah ada
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String chatRoomId = getChatRoomId(currentUserId ?? "", widget.receiverId);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.username,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Online",
              style: TextStyle(fontSize: 12, color: Colors.green),
            )
          ],
        ),
      ),
      body: Column(
        children: [
          // Bagian List Chat Menggunakan StreamBuilder Real-time
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms') // Disamakan menjadi 'chat_rooms'
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Belum ada pesan. Mulai obrolan!"));
                }

                final chatDocs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, 
                  padding: const EdgeInsets.all(16),
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    final data = chatDocs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          data['text'] ?? "",
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input Box Pengiriman Pesan
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Type message...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}