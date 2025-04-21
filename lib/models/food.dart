import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String id;
  final String name;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final int quantity;
  final String note;

  FoodItem({
    required this.id,
    required this.name,
    required this.purchaseDate,
    required this.expiryDate,
    required this.quantity,
    required this.note,
  });

  factory FoodItem.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      id: doc.id,
      name: data['name'] ?? '',
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      quantity: data['quantity'] ?? 0,
      note: data['note'] ?? '',
    );
  }
}
