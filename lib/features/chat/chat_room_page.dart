import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Digunakan untuk format jam kirim chat

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
  
  // Menyimpan data pesan teks yang sedang dibalas (Reply)
  String? replyingMessageText;

  String getChatRoomId(String user1, String user2) {
    if (user1.compareTo(user2) > 0) {
      return "${user1}_$user2";
    } else {
      return "${user2}_$user1";
    }
  }

  // Format Timestamp Firestore menjadi waktu (Contoh: 20:15)
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "...";
    var format = DateFormat('HH:mm');
    return format.format(timestamp.toDate());
  }

  // Format status waktu terakhir dilihat (Last Seen)
  String formatLastSeen(Timestamp? timestamp) {
    if (timestamp == null) return "Offline";
    var format = DateFormat('HH:mm');
    return "Terakhir dilihat ${format.format(timestamp.toDate())}";
  }

  void sendMessage() async {
    if (messageController.text.trim().isEmpty || currentUserId == null) return;

    String chatRoomId = getChatRoomId(currentUserId!, widget.receiverId);
    String messageText = messageController.text.trim();
    
    String? finalReplyText = replyingMessageText;
    setState(() => replyingMessageText = null);
    
    messageController.clear(); 

    // 1. Simpan pesan baru ke sub-koleksi messages
    await FirebaseFirestore.instance
        .collection('chat_rooms') 
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(), 
      'replyTo': finalReplyText, 
    });

    // 2. Sinkronkan ke dokumen utama untuk riwayat di ChatPage
    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .set({
      'participants': [currentUserId, widget.receiverId], 
      'lastMessage': messageText,                         
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); 
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
        titleSpacing: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.receiverId).snapshots(),
          builder: (context, userSnapshot) {
            String statusText = "Offline";
            bool isOnline = false;

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              isOnline = userData['isOnline'] ?? false;
              statusText = isOnline ? "Online" : formatLastSeen(userData['lastSeen'] as Timestamp?);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12, 
                    color: isOnline ? Colors.green : Colors.grey.shade600,
                    fontWeight: isOnline ? FontWeight.bold : FontWeight.normal,
                  ),
                )
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms') 
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
                    final String? textReply = data['replyTo'];

                    return GestureDetector(
                      onDoubleTap: () {
                        setState(() {
                          replyingMessageText = data['text'];
                        });
                      },
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // KOMPONEN BOX BALASAN PESAN (REPLY)
                              if (textReply != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  margin: const EdgeInsets.only(bottom: 6), // DI SINI SUDAH FIX BEBAS ERROR
                                  decoration: BoxDecoration(
                                    color: isMe ? Colors.blue.shade700 : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    textReply,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: isMe ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                              
                              Text(
                                data['text'] ?? "",
                                style: TextStyle(color: isMe ? Colors.white : Colors.black),
                              ),
                              const SizedBox(height: 4),
                              
                              // INDIKATOR JAM KIRIM CHAT
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    formatTimestamp(data['timestamp'] as Timestamp?),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe ? Colors.white70 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // PRATINJAU BANNER ATAS SEBELUM PESAN DIKIRIM (REPLYING MODE)
          if (replyingMessageText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  const Icon(Icons.reply, color: Colors.blue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Membalas: $replyingMessageText",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => setState(() => replyingMessageText = null),
                  )
                ],
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
                    icon: const Icon(Icons.send, color: Colors.white),
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