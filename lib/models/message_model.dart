import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, voice }

class MessageModel {
  final String id;
  final String senderId;
  final MessageType type;
  final String content; // text OR download URL
  final DateTime timestamp;
  final int? voiceDuration; // seconds
  final bool isSeen;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.type,
    required this.content,
    required this.timestamp,
    this.voiceDuration,
    this.isSeen = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return MessageModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      type: _typeFromString(map['type'] ?? 'text'),
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      voiceDuration: map['voiceDuration'],
      isSeen: map['isSeen'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'type': _typeToString(type),
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSeen': isSeen,
      if (voiceDuration != null) 'voiceDuration': voiceDuration,
    };
  }

  static MessageType _typeFromString(String s) {
    switch (s) {
      case 'image':
        return MessageType.image;
      case 'voice':
        return MessageType.voice;
      default:
        return MessageType.text;
    }
  }

  static String _typeToString(MessageType t) {
    switch (t) {
      case MessageType.image:
        return 'image';
      case MessageType.voice:
        return 'voice';
      default:
        return 'text';
    }
  }
}
