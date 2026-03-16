import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Upload image and return download URL
  Future<String> uploadImage(File imageFile) async {
    final String fileName = 'images/${_uuid.v4()}.jpg';
    final Reference ref = _storage.ref().child(fileName);

    final UploadTask uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // Upload audio and return download URL
  Future<String> uploadAudio(File audioFile) async {
    final String fileName = 'audio/${_uuid.v4()}.m4a';
    final Reference ref = _storage.ref().child(fileName);

    final UploadTask uploadTask = ref.putFile(
      audioFile,
      SettableMetadata(contentType: 'audio/m4a'),
    );

    final TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
