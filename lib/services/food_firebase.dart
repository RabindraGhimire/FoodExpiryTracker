import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final CollectionReference foods =
      FirebaseFirestore.instance.collection('foods');

  // Get current user ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Core Food Item Operations
  Future<void> addFullFoodItem({
  required String name,
  required DateTime purchaseDate,
  required DateTime expiryDate,
  required int quantity,
  required String note,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User not logged in');

  await foods.add({
    'userId': user.uid, // Essential for security rules
    'name': name,
    'purchaseDate': Timestamp.fromDate(purchaseDate),
    'expiryDate': Timestamp.fromDate(expiryDate),
    'quantity': quantity,
    'note': note,
    'timestamp': Timestamp.now(),
    'isShared': false, // Matches security rule field name
    'claimedBy': null, // Use null for unclaimed items
    'ownerName': user.displayName ?? 'Anonymous', // Pre-fill owner info
    'ownerEmail': user.email,
    'sharedAt': null, // Will be set when sharing
    'location': null, // For community items
    'address': null   // For community items
  });
}

  Stream<QuerySnapshot> getFoods() {
    final userId = currentUserId;
    if (userId == null) {
      debugPrint('No user logged in');
      return const Stream.empty();
    }

    return foods
        .where('userId', isEqualTo: userId)
        .orderBy('expiryDate', descending: false)
        .snapshots();
  }

  Future<void> updateFoodItem({
    required String docId,
    required String name,
    required DateTime purchaseDate,
    required DateTime expiryDate,
    required int quantity,
    required String note,
  }) {
    return foods.doc(docId).update({
      'name': name,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'quantity': quantity,
      'note': note,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteFoodItem(String docId) {
    return foods.doc(docId).delete();
  }

  // Community Features
  Future<void> shareFoodItem({
    required String docId,
    required Map<String, dynamic> locationData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    await foods.doc(docId).update({
      'shared': true,
      'ownerName': user.displayName ?? user.email,
      'ownerEmail': user.email,
      'isClaimed': false,
      'claimedBy': null,
      ...locationData,
    });
  }

  Future<void> unshareFoodItem(String docId) async {
    final doc = await foods.doc(docId).get();
    if (!doc.exists) throw Exception('Item not found');

    final data = doc.data() as Map<String, dynamic>;
    if (data['userId'] != currentUserId) throw Exception('Not item owner');

    await foods.doc(docId).update({
      'shared': false,
      'isClaimed': false,
      'claimedBy': null,
      'ownerName': null,
      'ownerEmail': null,
    });
  }

  Future<void> claimFoodItem(String docId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final doc = await foods.doc(docId).get();
    if (!doc.exists) throw Exception('Item not found');

    final data = doc.data() as Map<String, dynamic>;
    if (data['userId'] == userId) throw Exception('Cannot claim your own item');
    if (data['isClaimed'] == true) throw Exception('Item already claimed');
    if (data['shared'] != true) throw Exception('Item not shared');

    // Create copy in claimant's pantry
    await foods.add({
      'userId': userId,
      'name': data['name'],
      'purchaseDate': data['purchaseDate'],
      'expiryDate': data['expiryDate'],
      'quantity': data['quantity'],
      'note': data['note'],
      'timestamp': Timestamp.now(),
      'shared': false,
      'isClaimed': false,
      'claimedBy': null,
      'ownerName': null,
      'ownerEmail': null,
    });

    // Mark original as claimed
    await foods.doc(docId).update({
      'isClaimed': true,
      'claimedBy': userId,
    });
  }
  
Stream<QuerySnapshot> getCommunityFoods() {
  try {
    return foods
        .where('shared', isEqualTo: true)
        .where('isClaimed', isEqualTo: false)
        .orderBy('expiryDate', descending: false)
        .snapshots();
  } catch (e, stacktrace) {
    debugPrint("Firestore Error: $e");
    debugPrint("Stacktrace: $stacktrace");
    rethrow;
  }
}

  // Helper Methods
  Future<Map<String, dynamic>?> getFoodItem(String docId) async {
    final doc = await foods.doc(docId).get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  Future<void> markAsPickedUp(String docId) async {
    await FirebaseFirestore.instance.collection('community').doc(docId).delete();
    await FirebaseFirestore.instance.collection('foods').doc(docId).update({
      'isShared': false,
      'claimedBy': FieldValue.delete(),
    });
  }

  Future<void> updateSharedStatus(String docId, bool isShared) async {
    await FirebaseFirestore.instance.collection('foods').doc(docId).update({
      'isShared': isShared,
    });
  }
}