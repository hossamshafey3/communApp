import 'dart:io';
import 'package:uuid/uuid.dart';
import 'supabase_config.dart';

class StorageService {
  final _supabase = SupabaseConfig.client;
  final Uuid _uuid = const Uuid();

  // Upload image and return public URL
  Future<String> uploadImage(File imageFile) async {
    final String path = 'images/${_uuid.v4()}.jpg';
    
    await _supabase.storage.from('attachments').upload(
          path,
          imageFile,
        );

    return _supabase.storage.from('attachments').getPublicUrl(path);
  }

  // Upload audio and return public URL
  Future<String> uploadAudio(File audioFile) async {
    final String path = 'audio/${_uuid.v4()}.m4a';
    
    await _supabase.storage.from('attachments').upload(
          path,
          audioFile,
        );

    return _supabase.storage.from('attachments').getPublicUrl(path);
  }
}
