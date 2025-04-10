import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FoodsPage extends StatefulWidget {
  const FoodsPage({super.key});

  @override
  _FoodsPageState createState() => _FoodsPageState();
}

class _FoodsPageState extends State<FoodsPage> {
  final List<Map<String, dynamic>> _foodList = [];

  void _addFoodItem() {
    TextEditingController foodNameController = TextEditingController();
    DateTime boughtDate = DateTime.now();
    DateTime? expiryDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Add Food Item"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: foodNameController,
                    decoration: InputDecoration(labelText: "Food Name"),
                    textCapitalization: TextCapitalization.words, // Auto-capitalizing
                  ),
                  SizedBox(height: 10),
                  ListTile(
                    title: Text("Bought Date: ${DateFormat('yyyy-MM-dd').format(boughtDate)}"),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: boughtDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setStateDialog(() {
                          boughtDate = pickedDate;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: Text(
                      "Expiry Date: ${expiryDate == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(expiryDate!)}",
                    ),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setStateDialog(() {
                          expiryDate = pickedDate;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (foodNameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please enter a Food Name")),
                      );
                      return;
                    }
                    if (expiryDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Expiry Date is required!")),
                      );
                      return;
                    }

                    setState(() {
                      _foodList.add({
                        'name': foodNameController.text,
                        'boughtDate': DateFormat('yyyy-MM-dd').format(boughtDate),
                        'expiryDate': DateFormat('yyyy-MM-dd').format(expiryDate!),
                      });
                    });

                    Navigator.of(context).pop();
                  },
                  child: Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteFoodItem(int index) {
    setState(() {
      _foodList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Food Tracker')),
      body: _foodList.isEmpty
          ? Center(child: Text("No food items added"))
          : ListView.builder(
              itemCount: _foodList.length,
              itemBuilder: (context, index) {
                final food = _foodList[index];
                DateTime expiryDate = DateFormat('yyyy-MM-dd').parse(food['expiryDate']!);
                DateTime today = DateTime.now();
                int daysLeft = expiryDate.difference(today).inDays;
                bool isExpired = daysLeft < 0 || daysLeft == 0;

                return Card(
                  margin: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      // Title with White Background
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          food['name']!,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Bought: ${food['boughtDate']}"),
                            Text("Expiry: ${food['expiryDate']}"),
                            if (!isExpired)
                              Text(
                                "Expires in $daysLeft days",
                                style: TextStyle(color: daysLeft <= 3 ? Colors.orange : Colors.green),
                              ),
                            if (isExpired)
                              Container(
                                padding: EdgeInsets.all(5),
                                margin: EdgeInsets.only(top: 5),
                                color: Colors.red,
                                child: Text(
                                  "EXPIRED",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteFoodItem(index),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFoodItem,
        child: Icon(Icons.add),
      ),
    );
  }
}
