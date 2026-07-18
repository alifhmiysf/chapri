import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_room_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = "";

  late final Stream<QuerySnapshot> _chatRoomsStream;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Map<String, Map<String, dynamic>> _userProfileCache = {};

  @override
  void initState() {
    super.initState();
    _userProfileCache = <String, Map<String, dynamic>>{};
    
    if (_currentUserId != null) {
      _chatRoomsStream = FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('participants', arrayContains: _currentUserId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x1A008BED), 
              Color(0x0D008BED), 
              Color(0xFFFFFFFF), 
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Chats",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) {
                            _searchController.clear();
                            _searchQuery = "";
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                        ),
                        child: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(color: const Color(0x0A008BED)),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.30),
                              Colors.white.withValues(alpha: 0.18),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Column(
                            children: [
                              if (_isSearching)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      autofocus: true,
                                      onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.search, color: Color(0xFF008BED)),
                                        hintText: "Search contacts",
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                                      ),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: _currentUserId == null
                                    ? const Center(child: Text("User tidak terautentikasi"))
                                    : StreamBuilder<QuerySnapshot>(
                                        stream: _chatRoomsStream,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                                            return const Center(child: CircularProgressIndicator());
                                          }
                                          if (snapshot.hasError) return const Center(child: Text("Gagal memuat"));
                                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

                                          final rawChatRooms = snapshot.data!.docs;

                                          return ListView.builder(
                                            padding: const EdgeInsets.only(bottom: 24),
                                            itemCount: rawChatRooms.length,
                                            // Gunakan ini (tanpa 'const')
                                            itemBuilder: (context, index) {
                                              final roomData = rawChatRooms[index].data() as Map<String, dynamic>;
                                              final List<dynamic> participants = roomData['participants'] ?? [];
                                              final String lastMessage = (roomData['lastMessage'] ?? "").toString();

                                              final String receiverId = participants.firstWhere((id) => id != _currentUserId, orElse: () => '');
                                              if (receiverId.isEmpty) return const SizedBox.shrink();

                                              return StreamBuilder<DocumentSnapshot>(
                                                stream: FirebaseFirestore.instance.collection('users').doc(receiverId).snapshots(),
                                                builder: (context, userSnapshot) {
                                                  Map<String, dynamic>? userData;
                                                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                                    userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                                    _userProfileCache[receiverId] = userData;
                                                  } else {
                                                    userData = _userProfileCache[receiverId];
                                                  }

                                                  if (userData == null) return const SizedBox.shrink();

                                                  final String name = userData['name'] ?? 'No Name';
                                                  final String username = (userData['username'] ?? "").toString();

                                                  if (_searchQuery.isNotEmpty && !name.toLowerCase().contains(_searchQuery) && !username.toLowerCase().contains(_searchQuery) && !lastMessage.toLowerCase().contains(_searchQuery)) {
                                                    return const SizedBox.shrink();
                                                  }

                                                  return _buildChatTile(context, userData, receiverId, lastMessage);
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.shade400), const SizedBox(height: 16), const Text("Belum ada obrolan aktif")]));
  }

  Widget _buildChatTile(BuildContext context, Map<String, dynamic> userData, String receiverId, String lastMessage) {
    final String name = userData['name'] ?? 'No Name';
    final bool isVerified = userData['isVerified'] == true;
    final String photoUrl = (userData['photoUrl'] ?? "").toString();

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomPage(username: name, receiverId: receiverId))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty ? Text(name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)) : null,
                ),
                if (isVerified) Positioned(right: -2, bottom: -2, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFF008BED), shape: BoxShape.circle), child: const Icon(Icons.check, size: 12, color: Colors.white))),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600))])),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}