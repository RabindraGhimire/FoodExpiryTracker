import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firstproject/services/food_firebase.dart';
import 'package:firstproject/views/pages/foods_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Food Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // This will automatically refresh the StreamBuilder
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: firestoreService.getFoods(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 50, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Something went wrong!', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // This will automatically retry the stream
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/empty_fridge.png', height: 150),
                    const SizedBox(height: 20),
                    const Text(
                      'Your inventory is empty',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Add some food items to get started',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final foods = snapshot.data!.docs.map((doc) {
              return {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              };
            }).toList();

            final now = DateTime.now();
            final inOneWeek = now.add(const Duration(days: 7));

            // Calculate statistics
            final totalFoods = foods.length;
            final expiredFoods = foods.where((food) {
              final expiryDate = (food['expiryDate'] as Timestamp).toDate();
              return expiryDate.isBefore(now);
            }).length;

            final almostExpiredFoods = foods.where((food) {
              final expiryDate = (food['expiryDate'] as Timestamp).toDate();
              return expiryDate.isAfter(now) && expiryDate.isBefore(inOneWeek);
            }).length;

            final goodFoods = totalFoods - expiredFoods - almostExpiredFoods;

            // Get urgent foods (expiring soonest)
            List<Map<String, dynamic>> urgentFoods = foods.where((food) {
              final expiryDate = (food['expiryDate'] as Timestamp).toDate();
              return expiryDate.isAfter(now);
            }).toList();
            
            urgentFoods.sort((a, b) {
              final aDate = (a['expiryDate'] as Timestamp).toDate();
              final bDate = (b['expiryDate'] as Timestamp).toDate();
              return aDate.compareTo(bDate);
            });
            
            final top3UrgentFoods = urgentFoods.take(3).toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  _buildWelcomeSection(),
                  const SizedBox(height: 24),
                  
                  // Stats cards in a row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatCard(
                          context,
                          'Total Items',
                          totalFoods.toString(),
                          Icons.food_bank,
                          Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          context,
                          'Expired',
                          expiredFoods.toString(),
                          Icons.warning,
                          Colors.red,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          context,
                          'Expiring Soon',
                          almostExpiredFoods.toString(),
                          Icons.timer,
                          Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          context,
                          'Good',
                          goodFoods.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Urgent foods section
                  if (top3UrgentFoods.isNotEmpty) ...[
                    const Text(
                      'Urgent Items',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...top3UrgentFoods.map((food) => _buildFoodItemCard(context, food)).toList(),
                    const SizedBox(height: 16),
                  ],
                  
                  // View all button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => FoodsPage(showAddForm: true,)),
                        );
                      },
                      icon: const Icon(Icons.list_alt),
                      label: const Text('View All Items'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              )],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Add Food Page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FoodsPage(showAddForm: true)),
          );
        },
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting!',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Here's your food inventory status",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (title == 'Expired' && value != '0')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Alert',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItemCard(BuildContext context, Map<String, dynamic> food) {
    final expiryDate = (food['expiryDate'] as Timestamp).toDate();
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    final daysLeft = difference.inDays;
    
    Color statusColor;
    String statusText;
    
    if (expiryDate.isBefore(now)) {
      statusColor = Colors.red;
      statusText = 'Expired';
    } else if (daysLeft <= 3) {
      statusColor = Colors.orange;
      statusText = 'Urgent';
    } else if (daysLeft <= 7) {
      statusColor = Colors.amber;
      statusText = 'Soon';
    } else {
      statusColor = Colors.green;
      statusText = 'Good';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to edit page or show details
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fastfood,
                  size: 30,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food['name'] ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expires: ${DateFormat('MMM dd, yyyy').format(expiryDate)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  daysLeft < 0 ? 'Expired' : '$daysLeft days',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}