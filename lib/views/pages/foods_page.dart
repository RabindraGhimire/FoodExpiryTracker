import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firstproject/services/food_firebase.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class FoodsPage extends StatefulWidget {
  const FoodsPage({super.key, required bool showAddForm});

  @override
  State<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends State<FoodsPage> {
  final FirestoreService firestoreService = FirestoreService();
  bool isScanning = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  Future<void> _scanExpiryDate(BuildContext context, Function(DateTime) onDateScanned) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(
          onScanned: (barcode) {
            // Try to parse the barcode as a date (common formats)
            DateTime? parsedDate;
            
            // Try YYYYMMDD format (common in barcodes)
            if (barcode.length == 8) {
              try {
                final year = int.parse(barcode.substring(0, 4));
                final month = int.parse(barcode.substring(4, 6));
                final day = int.parse(barcode.substring(6, 8));
                parsedDate = DateTime(year, month, day);
              } catch (e) {
                // Ignore parse errors
              }
            }
            
            // Try MMDDYY format
            if (parsedDate == null && barcode.length == 6) {
              try {
                final month = int.parse(barcode.substring(0, 2));
                final day = int.parse(barcode.substring(2, 4));
                final year = int.parse("20${barcode.substring(4, 6)}");
                parsedDate = DateTime(year, month, day);
              } catch (e) {
                // Ignore parse errors
              }
            }
            
            // Try DDMMYY format
            if (parsedDate == null && barcode.length == 6) {
              try {
                final day = int.parse(barcode.substring(0, 2));
                final month = int.parse(barcode.substring(2, 4));
                final year = int.parse("20${barcode.substring(4, 6)}");
                parsedDate = DateTime(year, month, day);
              } catch (e) {
                // Ignore parse errors
              }
            }

            if (parsedDate != null) {
              Navigator.of(context).pop();
              onDateScanned(parsedDate);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Couldn't parse date from barcode: $barcode"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ),
    );
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),),
          padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Draggable handle
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(5),
                  ),),
                  Text(
                      docId == null ? "Add Food Item" : "Edit Food Item",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  const SizedBox(height: 20),
                  
                  // Food Name Field
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Food Name",
                      prefixIcon: const Icon(Icons.fastfood),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                      filled: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 15),
                  
                  // Date Pickers Row
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 15),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  DateFormat.yMMMd().format(selectedPurchaseDate),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final result = await showModalBottomSheet<DateTime>(
                              context: context,
                              builder: (context) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text('Scan expiry date from barcode'),
                                    onTap: () async {
                                      await _scanExpiryDate(context, (date) {
                                        Navigator.of(context).pop(date);
                                      });
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.calendar_today),
                                    title: const Text('Select date manually'),
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: selectedExpiryDate ?? DateTime.now().add(const Duration(days: 7)),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        Navigator.of(context).pop(picked);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                            
                            if (result != null) {
                              setModalState(() => selectedExpiryDate = result);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 15),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.event_available,
                                  size: 18,
                                  color: selectedExpiryDate == null 
                                      ? Colors.grey 
                                      : Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  selectedExpiryDate == null
                                      ? "Expiry Date"
                                      : DateFormat.yMMMd().format(selectedExpiryDate!),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selectedExpiryDate == null 
                                        ? Colors.grey 
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  // Quantity Field
                  TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Quantity",
                      prefixIcon: const Icon(Icons.format_list_numbered),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Notes Field
                  TextFormField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Notes (optional)",
                      prefixIcon: const Icon(Icons.note),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final quantity = int.tryParse(quantityController.text.trim()) ?? 1;
                        final note = noteController.text.trim();

                        if (name.isEmpty || selectedExpiryDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please fill all required fields"),
                              behavior: SnackBarBehavior.floating,
                            ),
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
                              SnackBar(
                                content: Text('Food "$name" saved'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: $e"),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        docId == null ? "SAVE FOOD ITEM" : "UPDATE FOOD ITEM",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
              ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'My Pantry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.teal[700]!,
                        Colors.teal[400]!,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.kitchen,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: FoodSearchDelegate(firestoreService),
                    );
                  },
                ),
              ],
            ),
          ];
        },
        body: StreamBuilder<QuerySnapshot>(
          stream: firestoreService.getFoods(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final foods = snapshot.data!.docs;

            if (foods.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.food_bank,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "No food items yet",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Tap the + button to add your first item",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              itemCount: foods.length,
              itemBuilder: (context, index) {
                final docId = foods[index].id;
                final data = foods[index].data() as Map<String, dynamic>;

                final name = data['name'] ?? '';
                final purchaseDate = (data['purchaseDate'] as Timestamp).toDate();
                final expiryDate = (data['expiryDate'] as Timestamp).toDate();
                final quantity = data['quantity'] ?? 1;
                final note = data['note'] ?? '';

                final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
                final isExpired = daysUntilExpiry < 0;
                final isExpiringSoon = daysUntilExpiry <= 3 && !isExpired;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  child: Slidable(
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        SlidableAction(
                            onPressed: (context) async {
                              final shouldDelete = await _confirmDelete(context);
                              if (shouldDelete) {
                                await firestoreService.deleteFoodItem(docId);

                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Food item deleted"),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                });
                              }
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ],
                      ),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
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
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Food Icon with Status
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isExpired
                                      ? Colors.red[50]
                                      : isExpiringSoon
                                          ? Colors.orange[50]
                                          : Colors.teal[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.fastfood,
                                  color: isExpired
                                      ? Colors.red
                                      : isExpiringSoon
                                          ? Colors.orange
                                          : Colors.teal,
                                ),
                              ),
                              const SizedBox(width: 15),
                              
                              // Food Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Qty: $quantity • Purchased: ${DateFormat.yMMMd().format(purchaseDate)}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Expiry Info
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isExpired
                                      ? Colors.red[50]
                                      : isExpiringSoon
                                          ? Colors.orange[50]
                                          : Colors.teal[50],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isExpired
                                      ? "Expired"
                                      : isExpiringSoon
                                          ? "Expires soon"
                                          : "Exp: ${DateFormat.MMMd().format(expiryDate)}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isExpired
                                        ? Colors.red
                                        : isExpiringSoon
                                            ? Colors.orange
                                            : Colors.teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditFoodDialog(context),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text("Add Food"),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    bool confirm = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this food item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              confirm = true;
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    return confirm;
  }
}

class BarcodeScannerPage extends StatelessWidget {
  final Function(String) onScanned;

  const BarcodeScannerPage({super.key, required this.onScanned});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Barcode"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (barcodeCapture) {
              final barcode = barcodeCapture.barcodes.first.rawValue;
              if (barcode != null) {
                Navigator.of(context).pop();
                onScanned(barcode);
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.teal,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Align barcode within the frame",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FoodSearchDelegate extends SearchDelegate {
  final FirestoreService firestoreService;

  FoodSearchDelegate(this.firestoreService);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getFoods(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final foods = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase());
        }).toList();

        if (foods.isEmpty) {
          return Center(
            child: Text(
              "No results for '$query'",
              style: const TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          itemCount: foods.length,
          itemBuilder: (context, index) {
            final docId = foods[index].id;
            final data = foods[index].data() as Map<String, dynamic>;

            final name = data['name'] ?? '';
            final expiryDate = (data['expiryDate'] as Timestamp).toDate();
            final quantity = data['quantity'] ?? 1;

            return ListTile(
              leading: const Icon(Icons.fastfood),
              title: Text(name),
              subtitle: Text(
                "Qty: $quantity • Exp: ${DateFormat.yMMMd().format(expiryDate)}",
              ),
              onTap: () {
                close(context, null);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: Text(name)),
                      body: Center(
                        child: Text("Details for $name"),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}