import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:firstproject/services/food_firebase.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final Map<String, bool> _expandedItems = {};
  Position? _currentPosition;
  bool _locationEnabled = false;
  bool _locationLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      setState(() => _locationLoading = true);
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationEnabled = false;
          _locationLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && 
            permission != LocationPermission.always) {
          setState(() {
            _locationEnabled = false;
            _locationLoading = false;
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _locationEnabled = true;
        _locationLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationEnabled = false;
        _locationLoading = false;
      });
      debugPrint('Location error: $e');
    }
  }

  List<QueryDocumentSnapshot> _sortByDistance(List<QueryDocumentSnapshot> docs) {
  if (_currentPosition == null) return List.from(docs);

  final sortedList = List<QueryDocumentSnapshot>.from(docs);
  try {
    sortedList.sort((a, b) {
      final geoA = a['location'] as GeoPoint?;
      final geoB = b['location'] as GeoPoint?;

      final distA = _calculateDistance(geoA);
      final distB = _calculateDistance(geoB);

      return distA.compareTo(distB);
    });
  } catch (e) {
    debugPrint('Error sorting by distance: $e');
  }
  return sortedList;
}

  double _calculateDistance(GeoPoint? geoPoint) {
    if (_currentPosition == null || geoPoint == null) return double.infinity;
    
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      geoPoint.latitude,
      geoPoint.longitude,
    ) / 1000; // Convert to kilometers
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Pantry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showCommunityGuidelines,
            tooltip: 'Community Guidelines',
          ),
          if (_locationLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            )
          else if (!_locationEnabled)
            IconButton(
              icon: const Icon(Icons.location_off),
              onPressed: _getUserLocation,
              tooltip: 'Enable Location',
            ),
        ],
      ),
      body: _buildCommunityList(),
    );
  }

  Widget _buildCommunityList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getCommunityFoods(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final sortedDocs = _sortByDistance(snapshot.data!.docs);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
  try {
    final doc = sortedDocs[index];
    final data = doc.data() as Map<String, dynamic>;
    final geoPoint = data['location'] as GeoPoint?;
    final distance = _calculateDistance(geoPoint);
    return _buildCommunityItem(doc.id, data, distance);
  } catch (e) {
    debugPrint('Error processing community item: $e');
    return ListTile(
      title: const Text('Error loading item'),
      subtitle: Text(e.toString()),
    );
  }
},
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_locationEnabled && !_locationLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const Icon(Icons.location_off, size: 40, color: Colors.orange),
                  const SizedBox(height: 8),
                  const Text('Location Services Disabled'),
                  TextButton(
                    onPressed: _getUserLocation,
                    child: const Text('Enable Location for Sorting'),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Icon(Icons.people_alt_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'No Shared Items Available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Share items from your pantry to help the community',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCommunityItem(String docId, Map<String, dynamic> data, double distance) {
    final expiryDate = data['expiryDate'] is Timestamp
        ? (data['expiryDate'] as Timestamp).toDate()
        : DateTime.now().add(const Duration(days: 1));
    final daysRemaining = expiryDate.difference(DateTime.now()).inDays;
    final isClaimed = data['isClaimed'] ?? false;
    final isMyItem = _currentUser?.uid != null &&
        _currentUser!.uid == data['userId'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIndicator(daysRemaining, isClaimed),
                const Spacer(),
                if (isMyItem)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showItemOptions(docId),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data['name'] ?? 'Unnamed Item',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildDetailItem(
                  icon: Icons.person_outline,
                  text: data['ownerName']?.toString() ?? 'Anonymous',
                ),
                _buildDetailItem(
                  icon: Icons.calendar_today,
                  text: DateFormat.yMMMd().format(expiryDate),
                ),
                _buildDetailItem(
                  icon: Icons.library_books,
                  text: 'Qty: ${data['quantity']?.toString() ?? '1'}',
                ),
              ],
            ),
            if (data['address'] != null && data['address'].toString().isNotEmpty) ...[
  const SizedBox(height: 8),
  GestureDetector(
    onTap: () {
      setState(() {
        _expandedItems[docId] = !(_expandedItems[docId] ?? false);
      });
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                data['address'],
                style: TextStyle(color: Colors.grey[600]),
                overflow: (_expandedItems[docId] ?? false) 
                    ? TextOverflow.visible 
                    : TextOverflow.ellipsis,
                maxLines: (_expandedItems[docId] ?? false) ? null : 1,
              ),
            ),
            Icon(
              (_expandedItems[docId] ?? false)
                  ? Icons.expand_less
                  : Icons.expand_more,
              size: 16,
              color: Colors.grey[600],
            ),
          ],
        ),
        if (distance != double.infinity)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.near_me, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${distance.toStringAsFixed(1)} km away',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  ),
],
            if (data['note']?.toString().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                'Note: ${data['note']}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            if (data['contactNote']?.toString().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                'Contact Note: ${data['contactNote']}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            _buildActionButton(docId, data, isClaimed, isMyItem),
          ],
        ),
      ),
    );
  }

  // Helper widget to display an icon and text, using Expanded
  Widget _buildDetailItem({required IconData icon, required String text}) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded( // Inner Expanded ensures text takes remaining space in its row
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(int daysRemaining, bool isClaimed) {
    final status = isClaimed
        ? {'text': 'Claimed', 'color': Colors.grey}
        : daysRemaining < 0
            ? {'text': 'Expired', 'color': Colors.red}
            : daysRemaining <= 3
                ? {'text': '$daysRemaining days left', 'color': Colors.orange}
                : {'text': '$daysRemaining days left', 'color': Colors.green};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (status['color'] as Color).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status['text'] as String,
        style: TextStyle(
          color: status['color'] as Color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String docId,
    Map<String, dynamic> data,
    bool isClaimed,
    bool isMyItem,
  ) {
    if (isClaimed) {
      final claimedByMe = data['claimedBy'] == _currentUser?.uid;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              claimedByMe ? Icons.check_circle : Icons.block,
              color: claimedByMe ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              claimedByMe ? 'Claimed by you' : 'Claimed by another user',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (isMyItem) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.edit, size: 18),
        label: const Text('Manage Item'),
        onPressed: () => _showItemOptions(docId),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.shopping_basket, size: 18),
          label: const Text('Claim Item'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _handleClaimItem(docId, data['name']?.toString() ?? 'Item'),
        ),
        if (data['address'] != null && (data['location'] is GeoPoint)) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('View on Map'),
            onPressed: () => _openMaps(data),
          ),
        ],
      ],
    );
  }

  Future<void> _openMaps(Map<String, dynamic> data) async {
  try {
    final GeoPoint? geoPoint = data['location'] as GeoPoint?;
    if (geoPoint == null) {
      throw 'No location data available';
    }

    final String url = Platform.isIOS
        ? 'http://maps.apple.com/?daddr=${geoPoint.latitude},${geoPoint.longitude}&dirflg=d'  // Directions in Apple Maps
        : 'https://www.google.com/maps/dir/?api=1&destination=${geoPoint.latitude},${geoPoint.longitude}&travelmode=driving';  // Directions in Google Maps

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw 'Could not launch maps app';
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Map Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  
  void _handleClaimItem(String docId, String itemName) async {
    try {
      await _firestoreService.claimFoodItem(docId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully claimed $itemName!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error claiming item: $e'); // Added debugPrint
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showItemOptions(String docId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Remove from Community'),
            onTap: () {
              Navigator.pop(context);
              _handleUnshareItem(docId);
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _handleUnshareItem(String docId) async {
    try {
      await _firestoreService.unshareFoodItem(docId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item removed from community'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error unsharing item: $e'); // Added debugPrint
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCommunityGuidelines() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Community Guidelines'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('• Share only safe, unexpired items'),
              Text('• Clearly mark expiration dates'),
              Text('• Update item status promptly'),
              Text('• Be respectful to other members'),
              Text('• Coordinate pickups responsibly'),
              Text('• No partial/opened items'),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

