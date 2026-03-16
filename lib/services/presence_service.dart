import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  // Call this when the app is resumed or opened
  static Future<void> updatePresence(String userId, bool isOnline) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).set({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Ignore errors if strictly offline or perm issues
    }
  }

  // Stream another user's presence
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getPresenceStream(String userId) {
    return _firestore.collection(_usersCollection).doc(userId).snapshots();
  }
}
