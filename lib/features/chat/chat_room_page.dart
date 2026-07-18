import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TEMA STATE CONFIGURATION
enum ChatThemeMode { defaultLight, darkMode, pinkCloud }

class ChatThemeStyle {
  final Color backgroundColor;
  final Color senderBubbleColor;
  final Color receiverBubbleColor;
  final Color textColor;
  final Color appBarTextColor;

  ChatThemeStyle({
    required this.backgroundColor,
    required this.senderBubbleColor,
    required this.receiverBubbleColor,
    required this.textColor,
    required this.appBarTextColor,
  });

  factory ChatThemeStyle.getStyle(ChatThemeMode mode) {
    switch (mode) {
      case ChatThemeMode.darkMode:
        return ChatThemeStyle(
          backgroundColor: const Color(0xFF121212),
          senderBubbleColor: const Color(0xFF008BED),
          receiverBubbleColor: const Color(0xFF1E1E1E),
          textColor: Colors.white,
          appBarTextColor: Colors.white,
        );
      case ChatThemeMode.pinkCloud:
        return ChatThemeStyle(
          backgroundColor: const Color(0xFFFFF0F5),
          senderBubbleColor: const Color(0xFFFF91A4),
          receiverBubbleColor: const Color(0xFFFFD1DC),
          textColor: const Color(0xFF4A2E35),
          appBarTextColor: const Color(0xFF4A2E35),
        );
      case ChatThemeMode.defaultLight:
        return ChatThemeStyle(
          backgroundColor: const Color(0xFFF5F5F5),
          senderBubbleColor: const Color(0xFF008BED).withOpacity(0.18),
          receiverBubbleColor: Colors.black.withOpacity(0.05),
          textColor: Colors.black87,
          appBarTextColor: Colors.black87,
        );
    }
  }
}

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

  String? replyingMessageText;
  late final String chatRoomId;

  ChatThemeMode _currentTheme = ChatThemeMode.defaultLight;

  late final Stream<QuerySnapshot> _messagesStream;
  late final Stream<DocumentSnapshot> _receiverStatusStream;

  @override
  void initState() {
    super.initState();
    chatRoomId = getChatRoomId(currentUserId ?? "", widget.receiverId);
    _updateActiveRoom(chatRoomId);
    _loadSavedTheme();

    _messagesStream = FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();

    _receiverStatusStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverId)
        .snapshots();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt('chat_theme_${widget.receiverId}');
      if (savedThemeIndex != null && savedThemeIndex < ChatThemeMode.values.length) {
        if (!mounted) return;
        setState(() {
          _currentTheme = ChatThemeMode.values[savedThemeIndex];
        });
      }
    } catch (_) {
      // ignore errors silently
    }
  }

  Future<void> _saveTheme(ChatThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('chat_theme_${widget.receiverId}', mode.index);
    } catch (_) {
      // ignore
    }
  }

  String getChatRoomId(String user1, String user2) {
    return user1.compareTo(user2) > 0 ? "${user1}_$user2" : "${user2}_$user1";
  }

  void _updateActiveRoom(String? roomId) {
    if (currentUserId == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .update({'activeRoom': roomId}).catchError((_) {});
  }

  void sendMessage() async {
    final messageText = messageController.text.trim();
    if (messageText.isEmpty || currentUserId == null) return;

    final String? finalReplyText = replyingMessageText;

    messageController.clear();
    if (replyingMessageText != null) {
      setState(() => replyingMessageText = null);
    }

    try {
      final receiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverId)
          .get();

      bool isReceiverInRoom = false;
      if (receiverDoc.exists) {
        final receiverData = receiverDoc.data() as Map<String, dynamic>;
        isReceiverInRoom = receiverData['activeRoom'] == chatRoomId;
      }

      final batch = FirebaseFirestore.instance.batch();

      final msgRef = FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc();

      batch.set(msgRef, {
        'senderId': currentUserId,
        'receiverId': widget.receiverId,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'replyTo': finalReplyText,
        'edited': false,
        'isRead': isReceiverInRoom,
      });

      final roomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId);
      batch.set(roomRef, {
        'participants': [currentUserId, widget.receiverId],
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (_) {
      // optionally handle/log error
    }
  }

  Future<void> editMessage(String messageId, String oldText) async {
    final controller = TextEditingController(text: oldText);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Pesan"),
        content: TextField(
          controller: controller,
          maxLines: null,
          decoration: const InputDecoration(hintText: "Ubah pesan..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('chat_rooms')
                    .doc(chatRoomId)
                    .collection('messages')
                    .doc(messageId)
                    .update({'text': newText, 'edited': true});
              }
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Future<void> markMessagesAsReadBulk(List<DocumentReference> refs) async {
    if (currentUserId == null || refs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (var ref in refs) {
      batch.update(ref, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  void dispose() {
    _updateActiveRoom(null);
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeStyle = ChatThemeStyle.getStyle(_currentTheme);

    return Scaffold(
      backgroundColor: themeStyle.backgroundColor,
      body: Stack(
        children: [
          if (_currentTheme != ChatThemeMode.darkMode)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _currentTheme == ChatThemeMode.pinkCloud
                        ? [const Color(0xFFFFF0F5), const Color(0xFFFFE4E1)]
                        : [const Color(0xFFE8F3FF), const Color(0xFFFFFFFF)],
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(themeStyle),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            "Belum ada pesan. Mulai obrolan!",
                            style: TextStyle(color: themeStyle.textColor.withOpacity(0.6)),
                          ),
                        );
                      }

                      final chatDocs = snapshot.data!.docs;

                      final List<DocumentReference> unreadRefsForMe = [];
                      for (var change in snapshot.data!.docChanges) {
                        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
                          final data = change.doc.data() as Map<String, dynamic>?;
                          if (data != null && data['receiverId'] == currentUserId && data['isRead'] != true) {
                            unreadRefsForMe.add(change.doc.reference);
                          }
                        }
                      }

                      if (unreadRefsForMe.isNotEmpty) {
                        Future.microtask(() => markMessagesAsReadBulk(unreadRefsForMe));
                      }

                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: chatDocs.length,
                        itemBuilder: (context, index) {
                          final doc = chatDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final isMe = data['senderId'] == currentUserId;

                          return ChatBubbleItem(
                            key: ValueKey(doc.id),
                            data: data,
                            isMe: isMe,
                            currentTheme: _currentTheme,
                            themeStyle: themeStyle,
                            onDoubleTap: () {
                              setState(() {
                                replyingMessageText = data['text'];
                              });
                            },
                            onTap: isMe ? () => editMessage(doc.id, data['text'] ?? "") : null,
                          );
                        },
                      );
                    },
                  ),
                ),
                if (replyingMessageText != null) _buildReplyPreview(),
                _buildInputBar(themeStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ChatThemeStyle themeStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: Icon(Icons.arrow_back, color: themeStyle.appBarTextColor),
            splashRadius: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _receiverStatusStream,
              builder: (context, userSnapshot) {
                String statusText = "Offline";
                bool isOnline = false;

                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  isOnline = userData['isOnline'] ?? false;
                  if (isOnline) {
                    statusText = "Online";
                  } else {
                    final timestamp = userData['lastSeen'] as Timestamp?;
                    statusText = timestamp != null
                        ? "Terakhir dilihat ${DateFormat('HH:mm').format(timestamp.toDate())}"
                        : "Offline";
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.username,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeStyle.appBarTextColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isOnline ? Colors.green : themeStyle.appBarTextColor.withOpacity(0.6),
                        fontWeight: isOnline ? FontWeight.bold : FontWeight.normal,
                      ),
                    )
                  ],
                );
              },
            ),
          ),
          PopupMenuButton<ChatThemeMode>(
            icon: Icon(Icons.palette, color: themeStyle.appBarTextColor),
            onSelected: (ChatThemeMode mode) {
              setState(() {
                _currentTheme = mode;
              });
              _saveTheme(mode);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: ChatThemeMode.defaultLight, child: Text("☀️ Light Mode")),
              const PopupMenuItem(value: ChatThemeMode.darkMode, child: Text("🌙 Dark Mode")),
              const PopupMenuItem(value: ChatThemeMode.pinkCloud, child: Text("☁️ Pink Cloud")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white.withOpacity(0.6),
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
    );
  }

  Widget _buildInputBar(ChatThemeStyle themeStyle) {
    bool isDark = _currentTheme == ChatThemeMode.darkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  sendMessage();
                },
                style: TextStyle(color: themeStyle.textColor),
                decoration: InputDecoration(
                  hintText: "Type message...",
                  hintStyle: TextStyle(color: themeStyle.textColor.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: sendMessage,
              icon: const Icon(Icons.send, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubbleItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;
  final ChatThemeMode currentTheme;
  final ChatThemeStyle themeStyle;
  final VoidCallback onDoubleTap;
  final VoidCallback? onTap;

  const ChatBubbleItem({
    super.key,
    required this.data,
    required this.isMe,
    required this.currentTheme,
    required this.themeStyle,
    required this.onDoubleTap,
    required this.onTap,
  });

  String _formatTimestamp(Timestamp? timestamp) {
    final DateTime date = timestamp != null ? timestamp.toDate() : DateTime.now();
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final String? textReply = data['replyTo'];
    final bool edited = data['edited'] == true;
    final bool isRead = data['isRead'] == true;

    Color bubbleColor;
    if (currentTheme == ChatThemeMode.defaultLight) {
      bubbleColor = isMe ? Colors.blue.withOpacity(0.18) : Colors.black.withOpacity(0.05);
    } else {
      bubbleColor = isMe ? themeStyle.senderBubbleColor : themeStyle.receiverBubbleColor;
    }

    final innerReplyColor = themeStyle.textColor.withOpacity(0.06);

    Widget bubbleContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (textReply != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: innerReplyColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              textReply,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: themeStyle.textColor.withOpacity(0.6)),
            ),
          ),
        ],
        Text(
          data['text'] ?? "",
          style: TextStyle(color: themeStyle.textColor, fontSize: 15),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (edited) ...[
              Text("(edited)", style: TextStyle(fontSize: 9, color: themeStyle.textColor.withOpacity(0.5))),
              const SizedBox(width: 4),
            ],
            Text(
              _formatTimestamp(data['timestamp'] as Timestamp?),
              style: TextStyle(fontSize: 10, color: themeStyle.textColor.withOpacity(0.5)),
            ),
            if (isMe) ...[
              const SizedBox(width: 4),
              Icon(
                isRead ? Icons.done_all : Icons.done,
                size: 14,
                color: isRead ? Colors.blue : Colors.grey,
              ),
            ],
          ],
        ),
      ],
    );

    final isPinkTheme = currentTheme == ChatThemeMode.pinkCloud;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onDoubleTap: onDoubleTap,
        onTap: onTap,
        child: isPinkTheme
            ? Container(
                margin: const EdgeInsets.only(bottom: 14, top: 4),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: CloudBubblePainter(color: bubbleColor, isMe: isMe),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                      child: bubbleContent,
                    ),
                  ),
                ),
              )
            : Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: bubbleContent,
              ),
      ),
    );
  }
}

class CloudBubblePainter extends CustomPainter {
  final Color color;
  final bool isMe;

  CloudBubblePainter({required this.color, required this.isMe});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // 1. Base Kotak Tengah
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 8, size.width - 20, size.height - 16),
      const Radius.circular(20),
    ));

    // 2. Formasi Gumpalan Bulat (Awan Kartun)
    path.addOval(Rect.fromCircle(center: Offset(size.width * 0.3, 8), radius: 14));
    path.addOval(Rect.fromCircle(center: Offset(size.width * 0.5, 5), radius: 17));
    path.addOval(Rect.fromCircle(center: Offset(size.width * 0.7, 8), radius: 14));

    path.addOval(Rect.fromCircle(center: Offset(10, size.height * 0.4), radius: 12));
    path.addOval(Rect.fromCircle(center: Offset(10, size.height * 0.7), radius: 10));
    path.addOval(Rect.fromCircle(center: Offset(size.width - 10, size.height * 0.4), radius: 12));
    path.addOval(Rect.fromCircle(center: Offset(size.width - 10, size.height * 0.7), radius: 10));

    path.addOval(Rect.fromCircle(center: Offset(size.width * 0.4, size.height - 8), radius: 12));
    path.addOval(Rect.fromCircle(center: Offset(size.width * 0.6, size.height - 8), radius: 12));

    canvas.drawPath(path, paint);

    // 3. Ekor Balon Chat Bulat Kecil
    if (isMe) {
      canvas.drawCircle(Offset(size.width - 2, size.height - 6), 5, paint);
      canvas.drawCircle(Offset(size.width + 3, size.height - 2), 2.5, paint);
    } else {
      canvas.drawCircle(Offset(2, size.height - 6), 5, paint);
      canvas.drawCircle(Offset(-3, size.height - 2), 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CloudBubblePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isMe != isMe;
  }
}
