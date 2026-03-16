import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import 'notification_service.dart';

class ChatService {
  static const String _chatCollection = 'chats';
  static const String _chatDoc = 'main_chat';
  static const String _messagesCollection = 'messages';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _messagesRef => _firestore
      .collection(_chatCollection)
      .doc(_chatDoc)
      .collection(_messagesCollection);

  // Background listener for notifications
  void startBackgroundListener(String currentUser) {
    _messagesRef.snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final msgData = change.doc.data();
          if (msgData != null && msgData['senderId'] != currentUser) {
            // Only notify for VERY recent messages to prevent spam on app start
            final timestamp = msgData['timestamp'] as Timestamp?;
            if (timestamp != null &&
                DateTime.now().difference(timestamp.toDate()).inMinutes < 1) {
              
              final isText = msgData['type'] == 'text';
              final senderName = msgData['senderId'] == 'hossam' ? 'Hossam' : 'Maria';
              final content = isText ? msgData['content'] : 'Sent an attachment 📸🎙️';

              NotificationService().showNotification(
                id: change.doc.id.hashCode,
                title: 'New message from $senderName',
                body: content,
              );
            }
          }
        }
      }
    });
  }

  // Real-time stream of messages
  Stream<List<MessageModel>> getMessagesStream() {
    return _messagesRef
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Send a text message
  Future<void> sendTextMessage({
    required String senderId,
    required String text,
  }) async {
    await _messagesRef.add(MessageModel(
      id: '',
      senderId: senderId,
      type: MessageType.text,
      content: text,
      timestamp: DateTime.now(),
      isSeen: false,
    ).toMap());
  }

  // Send an image message
  Future<void> sendImageMessage({
    required String senderId,
    required String imageUrl,
  }) async {
    await _messagesRef.add(MessageModel(
      id: '',
      senderId: senderId,
      type: MessageType.image,
      content: imageUrl,
      timestamp: DateTime.now(),
      isSeen: false,
    ).toMap());
  }

  // Send a voice message
  Future<void> sendVoiceMessage({
    required String senderId,
    required String audioUrl,
    required int durationSeconds,
  }) async {
    await _messagesRef.add(MessageModel(
      id: '',
      senderId: senderId,
      type: MessageType.voice,
      content: audioUrl,
      timestamp: DateTime.now(),
      voiceDuration: durationSeconds,
      isSeen: false,
    ).toMap());
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    await _messagesRef.doc(messageId).delete();
  }

  // Mark a message as seen
  Future<void> markAsSeen(String messageId) async {
    await _messagesRef.doc(messageId).update({'isSeen': true});
  }
}
