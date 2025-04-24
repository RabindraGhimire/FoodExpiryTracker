import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirestoreService firestoreService = FirestoreService();

  void _showEditProfileDialog(BuildContext context,
      {String? docId,
      String? name,
      String? email,
      String? profilePictureUrl,
      String? bio}) {
    final TextEditingController nameController = TextEditingController(text: name);
    final TextEditingController emailController = TextEditingController(text: email);
    final TextEditingController bioController = TextEditingController(text: bio);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            docId == null ? "Create Profile" : "Edit Profile",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.teal),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInputField(nameController, "Name"),
                const SizedBox(height: 10),
                _buildInputField(emailController, "Email", keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 10),
                _buildInputField(bioController, "Bio", maxLines: 3),
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
                final email = emailController.text.trim();
                final bio = bioController.text.trim();

                if (name.isEmpty || email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all required fields")),
                  );
                  return;
                }

                Navigator.of(context).pop();

                try {
                  if (docId == null) {
                    await firestoreService.addProfile(
                      name: name,
                      email: email,
                      bio: bio,
                    );
                  } else {
                    await firestoreService.updateProfile(
                      docId: docId,
                      name: name,
                      email: email,
                      bio: bio,
                    );
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Profile \"$name\" saved")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        elevation: 10,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestoreService.getProfile(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profileData = snapshot.data!.data() as Map<String, dynamic>?;
          if (profileData == null) {
            return const Center(child: Text("Profile not found"));
          }

          final name = profileData['name'];
          final email = profileData['email'];
          final bio = profileData['bio'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.teal,
                  child: Text(
                    name != null && name.isNotEmpty ? name[0] : 'U',
                    style: const TextStyle(fontSize: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text("Name: $name", style: const TextStyle(fontSize: 18, color: Colors.teal)),
                const SizedBox(height: 8),
                Text("Email: $email", style: const TextStyle(fontSize: 16, color: Colors.teal)),
                const SizedBox(height: 8),
                Text("Bio: $bio", style: const TextStyle(fontSize: 14, color: Colors.teal)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _showEditProfileDialog(
                      context,
                      docId: snapshot.data!.id,
                      name: name,
                      email: email,
                      bio: bio,
                    );
                  },
                  child: const Text("Edit Profile"),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditProfileDialog(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add Profile
  Future<void> addProfile({required String name, required String email, required String bio}) async {
    await _db.collection('profiles').doc('user_profile').set({
      'name': name,
      'email': email,
      'bio': bio,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update Profile
  Future<void> updateProfile(
      {required String docId, required String name, required String email, required String bio}) async {
    await _db.collection('profiles').doc(docId).update({
      'name': name,
      'email': email,
      'bio': bio,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get Profile
  Stream<DocumentSnapshot> getProfile() {
    return _db.collection('profiles').doc('user_profile').snapshots();
  }
}
