import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add Profile
  Future<void> addProfile({
    required String userId,
    required String firstname,
    required String lastname,
    required String email,
    required String contactno,
  }) async {
    await _db.collection('profiles').doc(userId).set({
      'firstname': firstname,
      'lastname': lastname,  // Added lastname
      'email': email,
      'contactno': contactno,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update Profile
  Future<void> updateProfile({
    required String docId,
    required String firstname,
    required String lastname,
    required String email,
    required String contactno,
  }) async {
    await _db.collection('profiles').doc(docId).update({
      'first_name': firstname,  // Added firstname
      'last_name': lastname,    // Added lastname
      'email': email,
      'contactno': contactno,  // Added contactno
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get Profile using user ID
  Stream<DocumentSnapshot> getProfile(String? userId) {
    if (userId == null) {
      return const Stream.empty();
    }
    return _db.collection('profiles').doc(userId).snapshots();
  }
}
