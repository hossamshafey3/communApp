

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
      senderId: map['sender_id'] ?? '',
      type: _typeFromString(map['type'] ?? 'text'),
      content: map['content'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      voiceDuration: map['voice_duration'],
      isSeen: map['is_seen'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'type': _typeToString(type),
      'content': content,
      'is_seen': isSeen,
      if (voiceDuration != null) 'voice_duration': voiceDuration,
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
