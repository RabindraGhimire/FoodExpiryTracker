import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firstproject/services/food_firebase.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // <-- Scanner package

class FoodsPage extends StatefulWidget {
  const FoodsPage({super.key, required bool showAddForm});

  @override
  State<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends State<FoodsPage> {
  final FirestoreService firestoreService = FirestoreService();
  bool isScanning = false;

  void _startScanner() async {
    setState(() {
      isScanning = true;
    });

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(
          onScanned: (barcode) {
            _showAddOrEditFoodDialog(context, name: barcode);
          },
        ),
      ),
    );

    setState(() {
      isScanning = false;
    });
  }

  void _showAddOrEditFoodDialog(BuildContext context,
      {String? docId,
      String? name,
      DateTime? purchaseDate,
      DateTime? expiryDate,
      int? quantity,
      String? note}) {
    final nameController = TextEditingController(text: name);
    final quantityController = TextEditingController(text: quantity?.toString() ?? '1');
    final noteController = TextEditingController(text: note);

    DateTime selectedPurchaseDate = purchaseDate ?? DateTime.now();
    DateTime? selectedExpiryDate = expiryDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              docId == null ? "Add Food Item" : "Edit Food Item",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.teal),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInputField(nameController, "Food Name"),
                  const SizedBox(height: 10),
                  _buildDatePickerTile(
                    title: "Purchase Date: ${DateFormat.yMMMd().format(selectedPurchaseDate)}",
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedPurchaseDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setModalState(() => selectedPurchaseDate = picked);
                      }
                    },
                  ),
                  _buildDatePickerTile(
                    title: selectedExpiryDate == null
                        ? "Select Expiry Date"
                        : "Expiry Date: ${DateFormat.yMMMd().format(selectedExpiryDate!)}",
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedExpiryDate ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setModalState(() => selectedExpiryDate = picked);
                      }
                    },
                  ),
                  _buildInputField(quantityController, "Quantity", keyboardType: TextInputType.number),
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
                  final quantity = int.tryParse(quantityController.text.trim()) ?? 1;
                  final note = noteController.text.trim();

                  if (name.isEmpty || selectedExpiryDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all required fields")),
                    );
                    return;
                  }

                  try {
                    if (docId == null) {
                      await firestoreService.addFullFoodItem(
                        name: name,
                        purchaseDate: selectedPurchaseDate,
                        expiryDate: selectedExpiryDate!,
                        quantity: quantity,
                        note: note,
                      );
                    } else {
                      await firestoreService.updateFoodItem(
                        docId: docId,
                        name: name,
                        purchaseDate: selectedPurchaseDate,
                        expiryDate: selectedExpiryDate!,
                        quantity: quantity,
                        note: note,
                      );
                    }

                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Food "$name" saved')),
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
        },
      ),
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

  Future<bool> _confirmDelete(BuildContext context) async {
    bool confirm = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion", style: TextStyle(color: Colors.red)),
        content: const Text("Are you sure you want to delete this food item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              confirm = true;
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    return confirm;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
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
              child: const Icon(Icons.fastfood, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'My Foods',
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

          final foods = snapshot.data!.docs;

          if (foods.isEmpty) {
            return const Center(child: Text("No food items found"));
          }

          return ListView.builder(
            itemCount: foods.length,
            itemBuilder: (context, index) {
              final docId = foods[index].id;
              final data = foods[index].data() as Map<String, dynamic>;

              final name = data['name'] ?? '';
              final purchaseDate = (data['purchaseDate'] as Timestamp).toDate();
              final expiryDate = (data['expiryDate'] as Timestamp).toDate();
              final quantity = data['quantity'] ?? 1;
              final note = data['note'] ?? '';

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
                confirmDismiss: (_) => _confirmDelete(context),
                onDismissed: (_) async {
                  await firestoreService.deleteFoodItem(docId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Food item deleted successfully")),
                  );
                },
                child: GestureDetector(
                  onLongPress: () {
                    _showAddOrEditFoodDialog(
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
                        "Qty: $quantity | Exp: ${DateFormat.yMMMd().format(expiryDate)}",
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'scanner',
            onPressed: _startScanner,
            backgroundColor: Colors.pink,
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'manual',
            onPressed: () => _showAddOrEditFoodDialog(context),
            backgroundColor: Colors.teal,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class BarcodeScannerPage extends StatelessWidget {
  final Function(String) onScanned;

  const BarcodeScannerPage({super.key, required this.onScanned});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Barcode")),
      body: MobileScanner(
        onDetect: (barcodeCapture) {
          final barcode = barcodeCapture.barcodes.first.rawValue;
          if (barcode != null) {
            onScanned(barcode);
          }
        },
      ),
    );
  }
}
