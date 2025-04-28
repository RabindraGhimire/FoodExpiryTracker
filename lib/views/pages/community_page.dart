import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // To get the user's location

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  Position? _currentPosition;
  List<Map<String, String>> _foodItems = [
    {'name': 'Milk', 'expiry': '2025-04-28', 'location': 'Copenhagen', 'condition': 'Good'},
    {'name': 'Bread', 'expiry': '2025-04-24', 'location': 'Copenhagen', 'condition': 'Fresh'},
  ];

  // Fetch user's location
  void _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location services are disabled")));
      return;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location permission denied")));
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community Food Sharing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Location display and button to get user's location
            _currentPosition == null
                ? ElevatedButton(
                    onPressed: _getCurrentLocation,
                    child: Text('Get My Location'),
                  )
                : Text(
                    'Location: Lat: ${_currentPosition!.latitude}, Long: ${_currentPosition!.longitude}'),
            SizedBox(height: 20),
            // List of shared food items
            Expanded(
              child: ListView.builder(
                itemCount: _foodItems.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(_foodItems[index]['name']!),
                      subtitle: Text('Expiry Date: ${_foodItems[index]['expiry']}'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          // Logic for interaction, e.g., contacting the person sharing
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Contact for ${_foodItems[index]['name']}'),
                              content: Text('Do you want to claim this food?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Logic for claiming the food
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('You claimed ${_foodItems[index]['name']}')));
                                    Navigator.pop(context);
                                  },
                                  child: Text('Claim'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text('Claim'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
