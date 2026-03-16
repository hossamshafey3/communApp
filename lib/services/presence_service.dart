import 'supabase_config.dart';

class PresenceService {
  static final _supabase = SupabaseConfig.client;

  // Call this when the app is resumed or opened
  static Future<void> updatePresence(String userId, bool isOnline) async {
    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Ignore errors
    }
  }

  // Stream another user's presence
  static Stream<List<Map<String, dynamic>>> getPresenceStream(String userId) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId);
  }
}
