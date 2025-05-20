import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../models/post.dart';
import '../widgets/barcode_scanner_screen.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();

  File? _selectedImage;
  bool _isUploading = false;

  double _latitude = 0.0;
  double _longitude = 0.0;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _createPost() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showAuthError();
      return;
    }

    if (!_validateForm()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final userProfile =
          await FirebaseFirestore.instance
              .collection('profiles')
              .doc(user.uid)
              .get();

      final data = userProfile.data();
      final firstName = (data?['firstName']?.toString() ?? '').trim();
      final lastName = (data?['lastName']?.toString() ?? '').trim();
      final fullName = '$firstName $lastName'.trim();
      final photoURL = data?['photoURL']?.toString() ?? '';

      // Upload _selectedImage to your storage here if you want
      String imageUrl = '';

      final newPost = Post(
        id: '',
        name: _nameController.text,
        expiry: _expiryController.text,
        condition: _conditionController.text,
        latitude: _latitude,
        longitude: _longitude,
        likes: [],
        comments: [],
        timestamp: Timestamp.now(),
        claimed: false,
        userId: user.uid,
        category: 'Other',
        username: fullName.isNotEmpty ? fullName : 'Anonymous',
        userPhoto: photoURL,
        imageUrl: imageUrl,
      );

      await FirebaseFirestore.instance.collection('posts').add(newPost.toMap());
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: ${e.toString()}')),
      );
    }

    setState(() {
      _isUploading = false;
    });
  }

  bool _validateForm() {
    if (_nameController.text.isEmpty ||
        _expiryController.text.isEmpty ||
        _conditionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return false;
    }
    return true;
  }

  void _clearForm() {
    _nameController.clear();
    _expiryController.clear();
    _conditionController.clear();
    setState(() {
      _selectedImage = null;
    });
  }

  void _showAuthError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You need to be logged in to create a post'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _expiryController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _scanBarcode() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (scannedCode != null && scannedCode.isNotEmpty) {
      final match = RegExp(r'20\d{2}[01]\d[0-3]\d').firstMatch(scannedCode);
      if (match != null) {
        final rawDate = match.group(0)!;
        final formattedDate =
            '${rawDate.substring(0, 4)}-${rawDate.substring(4, 6)}-${rawDate.substring(6, 8)}';
        setState(() {
          _expiryController.text = formattedDate;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid expiry date found in code')),
        );
      }
    }
  }

  Future<void> _claimPost(Post post) async {
    final user = _auth.currentUser;
    if (user == null || post.claimed) return;

    await FirebaseFirestore.instance.collection('posts').doc(post.id).update({
      'claimed': true,
    });
  }

  Stream<List<Post>> _getPostsStream() {
    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Post.fromDocument(doc)).toList(),
        );
  }

  Widget _buildPostForm() {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage:
                      _auth.currentUser?.photoURL != null
                          ? NetworkImage(_auth.currentUser!.photoURL!)
                          : null,
                  child:
                      _auth.currentUser?.photoURL == null
                          ? const Icon(Icons.person, size: 28)
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'What food do you want to share?',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryController,
                    readOnly: true,
                    onTap: _selectExpiryDate,
                    decoration: InputDecoration(
                      hintText: 'Expiry Date',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _scanBarcode,
                  icon: Icon(Icons.qr_code_scanner, color: theme.primaryColor),
                  tooltip: 'Scan Expiry Date',
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _conditionController,
              decoration: InputDecoration(
                hintText: 'Storage Condition (e.g. Refrigerated)',
                prefixIcon: const Icon(Icons.info_outline),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined, color: Colors.white),
                  label: const Text(
                    'Add Image',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                if (_selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.file(
                      _selectedImage!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const Text(
                    'No image selected',
                    style: TextStyle(color: Colors.grey),
                  ),
                const Spacer(),
                _isUploading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                      onPressed: _createPost,
                      child: const Text(
                        'Post',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostItem(Post post) {
    final user = _auth.currentUser;
    final isOwnPost = user != null && post.userId == user.uid;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 26,
                backgroundImage:
                    post.userPhoto.isNotEmpty
                        ? NetworkImage(post.userPhoto)
                        : null,
                child:
                    post.userPhoto.isEmpty
                        ? const Icon(Icons.person, size: 28)
                        : null,
              ),
              title: Text(
                post.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                '${_formatTimestamp(post.timestamp)} ago',
                style: const TextStyle(color: Colors.grey),
              ),
              trailing:
                  isOwnPost
                      ? IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        onPressed: () => _deletePost(post),
                      )
                      : null,
            ),
            const SizedBox(height: 12),
            Text(
              post.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Expiry: ${post.expiry}',
              style: const TextStyle(fontSize: 15),
            ),
            Text(
              'Condition: ${post.condition}',
              style: const TextStyle(fontSize: 15),
            ),
            if (post.imageUrl.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  post.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 14),
            !post.claimed
                ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _claimPost(post),
                  child: const Text(
                    'Claim',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                )
                : Text(
                  'This item has been claimed',
                  style: TextStyle(
                    color: theme.primaryColorDark,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePost(Post post) async {
    await FirebaseFirestore.instance.collection('posts').doc(post.id).delete();
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inDays > 7) {
      return DateFormat('yyyy-MM-dd').format(timestamp.toDate());
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Community')),
      body: Column(
        children: [
          _buildPostForm(),
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: _getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final posts = snapshot.data!;
                if (posts.isEmpty) {
                  return const Center(child: Text('No posts yet'));
                }
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildPostItem(post);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
