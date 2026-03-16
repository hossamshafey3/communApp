import '../models/message_model.dart';
import 'supabase_config.dart';

class ChatService {
  final _supabase = SupabaseConfig.client;

  // Real-time stream of messages
  Stream<List<MessageModel>> getMessagesStream() {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('timestamp', ascending: true)
        .map((data) => data
            .map((map) => MessageModel.fromMap(map, map['id'].toString()))
            .toList());
  }

  // Send a text message
  Future<void> sendTextMessage({
    required String senderId,
    required String text,
  }) async {
    await _supabase.from('messages').insert({
      'sender_id': senderId,
      'type': 'text',
      'content': text,
      'is_seen': false,
    });
  }

  // Send an image message
  Future<void> sendImageMessage({
    required String senderId,
    required String imageUrl,
  }) async {
     await _supabase.from('messages').insert({
      'sender_id': senderId,
      'type': 'image',
      'content': imageUrl,
      'is_seen': false,
    });
  }

  // Send a voice message
  Future<void> sendVoiceMessage({
    required String senderId,
    required String audioUrl,
    required int durationSeconds,
  }) async {
    await _supabase.from('messages').insert({
      'sender_id': senderId,
      'type': 'voice',
      'content': audioUrl,
      'voice_duration': durationSeconds,
      'is_seen': false,
    });
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    await _supabase.from('messages').delete().eq('id', messageId);
  }

  // Mark a message as seen
  Future<void> markAsSeen(String messageId) async {
    await _supabase.from('messages').update({'is_seen': true}).eq('id', messageId);
  }
}
