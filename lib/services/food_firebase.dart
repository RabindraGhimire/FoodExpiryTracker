import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final CollectionReference foods =
      FirebaseFirestore.instance.collection('foods');

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
      'userId': user.uid,
      'name': name,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'quantity': quantity,
      'note': note,
      'timestamp': Timestamp.now(),
      'isShared': false,
      'isClaimed': false,
      'claimedBy': null,
      'ownerName': user.email ?? 'Anonymous',
      'ownerEmail': user.email,
      'sharedAt': null,
      'location': null,
      'address': null
    });
  }

  Stream<QuerySnapshot> getFoods() {
    final userId = currentUserId;
    if (userId == null) return const Stream.empty();

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
  }) async {
    await foods.doc(docId).update({
      'name': name,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'quantity': quantity,
      'note': note,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteFoodItem(String docId) async {
    await foods.doc(docId).delete();
  }

  // Community Features
  Future<void> shareFoodItem({
    required String docId,
    required Map<String, dynamic> locationData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final batch = FirebaseFirestore.instance.batch();
    
    // Update food document
    final foodRef = foods.doc(docId);
    batch.update(foodRef, {
      'isShared': true,
      'isClaimed': false,
      'claimedBy': null,
      'sharedAt': Timestamp.now(),
      ...locationData,
    });

    // Create community listing
    final communityRef = FirebaseFirestore.instance.collection('community').doc(docId);
    batch.set(communityRef, {
      'userId': user.uid,
      'foodId': docId,
      'sharedAt': Timestamp.now(),
      ...locationData,
    });

    await batch.commit();
  }

  Future<void> unshareFoodItem(String docId) async {
    final batch = FirebaseFirestore.instance.batch();
    
    // Update food document
    batch.update(foods.doc(docId), {
      'isShared': false,
      'isClaimed': false,
      'claimedBy': null,
      'sharedAt': null,
    });

    // Remove from community
    batch.delete(FirebaseFirestore.instance.collection('community').doc(docId));

    await batch.commit();
  }

  Future<void> claimFoodItem(String docId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    try {
      final doc = await foods.doc(docId).get();
      if (!doc.exists) throw Exception('Item not found');

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] == userId) throw Exception('Cannot claim your own item');
      if (data['isClaimed'] == true) throw Exception('Item already claimed');
      if (data['isShared'] != true) throw Exception('Item not shared');

      // Create copy for claimant
      // This creates a new document in the claimant's 'foods' collection
      await foods.add({
        'userId': userId,
        // Remove 'userId' from the copied data to avoid conflicts, then spread the rest
        ...data..removeWhere((key, _) => key == 'userId'), 
        'timestamp': Timestamp.now(),
        'isShared': false, // The claimant's copy is not shared
        'isClaimed': false, // The claimant's copy is not claimed by anyone else
        'claimedBy': null,
        'sharedAt': null,
      });

      // Update original item to mark it as claimed
      // This keeps the original item in the owner's 'foods' collection but marks it as claimed
      await foods.doc(docId).update({
        'isClaimed': true,
        'claimedBy': userId,
      });
    } on FirebaseException catch (e) {
      debugPrint('Claim failed: ${e.message}');
      rethrow;
    }
  }

  /// Confirms that a shared food item has been picked up by the claimant.
  /// This method is called by the original owner of the food item.
  /// It deletes the original food item from the owner's 'foods' collection
  /// and removes its listing from the 'community' collection.
  Future<void> confirmPickupByOwner(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final foodDocRef = foods.doc(docId);
    // Explicitly cast the data to Map<String, dynamic>?
    final foodData = (await foodDocRef.get()).data() as Map<String, dynamic>?;

    // Verify ownership: Only the owner can confirm pickup of their shared item
    if (foodData?['userId'] != user.uid) {
      throw Exception('Not authorized to confirm pickup for this item');
    }

    final batch = FirebaseFirestore.instance.batch();
    
    // 1. Delete the listing from the 'community' collection
    batch.delete(FirebaseFirestore.instance.collection('community').doc(docId));
    
    // 2. Delete the original food item from the owner's 'foods' collection
    // This effectively "transfers" it by removing the original and leaving the claimant's copy.
    batch.delete(foodDocRef);

    await batch.commit();
  }

  Stream<QuerySnapshot> getCommunityFoods() {
    try {
    return foods
        .where('isShared', isEqualTo: true)
        .where('isClaimed', isEqualTo: false)
        .where('location', isNull: false)
        .orderBy('expiryDate', descending: false)
        .snapshots();
  } catch (e) {
    print('Firestore query error: $e');
    rethrow;
  }
  }

  // Helper Methods
  Future<Map<String, dynamic>?> getFoodItem(String docId) async {
    final doc = await foods.doc(docId).get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  
}
