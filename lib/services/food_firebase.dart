import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final CollectionReference foods = FirebaseFirestore.instance.collection('foods');

  // Get current user ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // CREATE - Add full food item
  Future<void> addFullFoodItem({
    required String name,
    required DateTime purchaseDate,
    required DateTime expiryDate,
    required int quantity,
    required String note,
  }) {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    return foods.add({
      'userId': userId,
      'name': name,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'quantity': quantity,
      'note': note,
      'timestamp': Timestamp.now(),
    });
  }

  // READ - Get food items ordered by expiryDate for the current user
Stream<QuerySnapshot> getFoods() {
  final userId = currentUserId;
  if (userId == null) {
    debugPrint('No user is currently logged in');
    return const Stream.empty();
  }

  return foods
      .where('userId', isEqualTo: userId)
      .snapshots();
}

  // UPDATE - Update food item by document ID
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

  // DELETE - Delete food item by document ID
  Future<void> deleteFoodItem(String docId) {
    return foods.doc(docId).delete();
  }
}
