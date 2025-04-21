import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference foods = FirebaseFirestore.instance.collection('foods');

  // CREATE - Add full food item
  Future<void> addFullFoodItem({
    required String name,
    required DateTime purchaseDate,
    required DateTime expiryDate,
    required int quantity,
    required String note,
  }) {
    return foods.add({
      'name': name,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'quantity': quantity,
      'note': note,
      'timestamp': Timestamp.now(),
    });
  }

  // READ - Get food items ordered by expiryDate
  Stream<QuerySnapshot> getFoods() {
    return foods.orderBy('expiryDate').snapshots();
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
