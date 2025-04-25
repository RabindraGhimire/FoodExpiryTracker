import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firstproject/services/food_firebase.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FoodsPage extends StatefulWidget {
  const FoodsPage({super.key});

  @override
  State<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends State<FoodsPage> {
  final FirestoreService firestoreService = FirestoreService();

  void _showAddFoodDialog(BuildContext context,
      {String? docId,
      String? name,
      DateTime? purchaseDate,
      DateTime? expiryDate,
      int? quantity,
      String? note}) {
    final TextEditingController nameController =
        TextEditingController(text: name);
    final TextEditingController quantityController =
        TextEditingController(text: quantity != null ? quantity.toString() : '1');
    final TextEditingController noteController =
        TextEditingController(text: note);

    DateTime purchaseDate0 = purchaseDate ?? DateTime.now();
    DateTime? expiryDate0 = expiryDate;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            docId == null ? "Add Food Item" : "Edit Food Item",
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.teal),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInputField(nameController, "Food Name"),
                const SizedBox(height: 10),
                _buildDatePickerTile(
                  title:
                      "Purchase Date: ${DateFormat.yMMMd().format(purchaseDate0)}",
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: purchaseDate0,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => purchaseDate0 = picked);
                    }
                  },
                ),
                _buildDatePickerTile(
                  title: expiryDate0 == null
                      ? "Select Expiry Date"
                      : "Expiry Date: ${DateFormat.yMMMd().format(expiryDate0!)}",
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          expiryDate0 ?? DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => expiryDate0 = picked);
                    }
                  },
                ),
                _buildInputField(quantityController, "Quantity",
                    keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                _buildInputField(noteController, "Note", maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final quantity =
                    int.tryParse(quantityController.text.trim()) ?? 1;
                final note = noteController.text.trim();

                if (name.isEmpty || expiryDate0 == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please fill all required fields")),
                  );
                  return;
                }

                try {
  if (docId == null) {
    await firestoreService.addFullFoodItem(
      name: name,
      purchaseDate: purchaseDate0,
      expiryDate: expiryDate0!,
      quantity: quantity,
      note: note,
    );
  } else {
    await firestoreService.updateFoodItem(
      docId: docId,
      name: name,
      purchaseDate: purchaseDate0,
      expiryDate: expiryDate0!,
      quantity: quantity,
      note: note,
    );
  }

  if (mounted) {
    Navigator.of(context).pop();
  }

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Food \"$name\" saved")),
    );
  }
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}

              },
              child: Text(docId == null ? "Save" : "Update"),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildDatePickerTile({required String title, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.teal)),
      trailing: const Icon(Icons.calendar_today, color: Colors.teal),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFff9a9e), Color(0xFFfad0c4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child:
                        const Icon(Icons.fastfood, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'My Pantry',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black38,
                              offset: Offset(1, 1),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Track your food items',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        elevation: 10,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.cyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getFoods(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final foodItems = snapshot.data!.docs;

          if (foodItems.isEmpty) {
            return const Center(child: Text("No food items found"));
          }

          return ListView.builder(
            itemCount: foodItems.length,
            itemBuilder: (context, index) {
              final docId = foodItems[index].id;
              final foodData = foodItems[index].data() as Map<String, dynamic>;
              final name = foodData['name'];
              final purchaseDate = (foodData['purchaseDate'] as Timestamp).toDate();
              final expiryDate = (foodData['expiryDate'] as Timestamp).toDate();
              final quantity = foodData['quantity'];
              final note = foodData['note'];

              final isExpired = expiryDate.isBefore(DateTime.now());

              return Dismissible(
                key: Key(docId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  bool confirm = false;
                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Confirm Deletion",
                          style: TextStyle(color: Colors.red)),
                      content: const Text(
                          "Are you sure you want to delete this food item?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("Cancel",
                              style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            confirm = true;
                            Navigator.of(context).pop();
                          },
                          style:
                              ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  );
                  return confirm;
                },
                onDismissed: (_) async {
                  await firestoreService.deleteFoodItem(docId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Food item deleted successfully")),
                  );
                },
                child: GestureDetector(
                  onLongPress: () {
                    _showAddFoodDialog(
                      context,
                      docId: docId,
                      name: name,
                      purchaseDate: purchaseDate,
                      expiryDate: expiryDate,
                      quantity: quantity,
                      note: note,
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      leading: Icon(Icons.fastfood,
                          color: isExpired ? Colors.red : Colors.teal),
                      title: Text(name),
                      subtitle: Text(
                          "Qty: $quantity | Exp: ${DateFormat.yMMMd().format(expiryDate)}"),
                      //trailing: const Icon(Icons.edit, color: Colors.grey),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFoodDialog(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
