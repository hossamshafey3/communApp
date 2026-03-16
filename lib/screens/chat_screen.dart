import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/storage_service.dart';
import '../services/presence_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_bar.dart';

// The other person's display name given current user
String _otherUser(String me) =>
    me == 'hossam' ? 'Maria' : 'Hossam';

class ChatScreen extends StatefulWidget {
  final String currentUser;

  const ChatScreen({super.key, required this.currentUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final StorageService _storageService = StorageService();
  final ScrollController _scrollCtrl = ScrollController();
  bool _uploading = false;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onSendText(String text) async {
    try {
      await _chatService.sendTextMessage(
          senderId: widget.currentUser, text: text);
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to send message');
    }
  }

  Future<void> _onSendImage(File file) async {
    setState(() => _uploading = true);
    try {
      final url = await _storageService.uploadImage(file);
      await _chatService.sendImageMessage(
          senderId: widget.currentUser, imageUrl: url);
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to send image');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _onSendVoice(File file, int duration) async {
    setState(() => _uploading = true);
    try {
      final url = await _storageService.uploadAudio(file);
      await _chatService.sendVoiceMessage(
          senderId: widget.currentUser,
          audioUrl: url,
          durationSeconds: duration);
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to send voice message');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Messages list ────────────────────────────────
          Expanded(child: _buildMessageList()),
          // ── Upload indicator ─────────────────────────────
          if (_uploading)
            Container(
              color: const Color(0xFF111827),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Color(0xFF6C63FF), strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Uploading...',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                ],
              ),
            ),
          // ── Input bar ────────────────────────────────────
          ChatInputBar(
            onSendText: _onSendText,
            onSendImage: _onSendImage,
            onSendVoice: _onSendVoice,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF111827),
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: PresenceService.getPresenceStream(_otherUser(widget.currentUser).toLowerCase()),
              builder: (context, snapshot) {
                bool isOnline = false;
                String statusText = 'Offline';
                
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data();
                  isOnline = data?['isOnline'] ?? false;
                  if (!isOnline && data?['lastSeen'] != null) {
                    final lastSeen = (data!['lastSeen'] as Timestamp).toDate();
                    final diff = DateTime.now().difference(lastSeen);
                    if (diff.inMinutes < 60) {
                      statusText = 'Last seen ${diff.inMinutes}m ago';
                    } else if (diff.inHours < 24) {
                      statusText = 'Last seen ${diff.inHours}h ago';
                    } else {
                      statusText = 'Last seen ${lastSeen.day}/${lastSeen.month}';
                    }
                  } else if (isOnline) {
                    statusText = 'Online';
                  }
                }

                return Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF48CAE4), Color(0xFF6C63FF)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _otherUser(widget.currentUser)[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2ECC71),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF111827), width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _otherUser(widget.currentUser),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isOnline)
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2ECC71),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Online',
                                style: TextStyle(
                                    color: Color(0xFF2ECC71), fontSize: 12),
                              ),
                            ],
                          )
                        else
                          Text(
                            statusText,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5), fontSize: 11),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined,
              color: Color(0xFF6C63FF)),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined, color: Color(0xFF6C63FF)),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<List<MessageModel>>(
      stream: _chatService.getMessagesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    color: Colors.white38, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Connection error\nPlease check Firebase setup',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded,
                      color: Color(0xFF6C63FF), size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No messages yet',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Say hello! 👋',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 13),
                ),
              ],
            ),
          );
        }

        _scrollToBottom();
        
        // Mark unread incoming messages as seen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (var msg in messages) {
            if (msg.senderId != widget.currentUser && !msg.isSeen) {
              _chatService.markAsSeen(msg.id);
            }
          }
        });

        return ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final isMe = msg.senderId == widget.currentUser;
            // Show tail (avatar) on last message of a group from other person
            final bool showTail = !isMe &&
                (index == messages.length - 1 ||
                    messages[index + 1].senderId == widget.currentUser);
            return MessageBubble(
                message: msg, isMe: isMe, showTail: showTail);
          },
        );
      },
    );
  }
}
