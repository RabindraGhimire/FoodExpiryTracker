import 'package:flutter/material.dart';
import 'package:firstproject/services/profile_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService firestoreService = FirestoreService();
  final double profileHeight = 144;

  User? get currentUser => _auth.currentUser;

  void _showEditProfileDialog(BuildContext context,
      {String? docId, String? first_name, String? last_name, String? email, String? phone}) {
    final TextEditingController firstNameController = TextEditingController(text: first_name);
    final TextEditingController lastNameController = TextEditingController(text: last_name);
    final TextEditingController emailController = TextEditingController(text: email);
    final TextEditingController phoneController = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  docId == null ? "Create Profile" : "Edit Profile",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInputField(firstNameController, "First Name", Icons.person),
                const SizedBox(height: 15),
                _buildInputField(lastNameController, "Last Name", Icons.person),
                const SizedBox(height: 15),
                _buildInputField(emailController, "Email", Icons.email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 15),
                _buildInputField(phoneController, "Phone", Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final firstName = firstNameController.text.trim();
                        final lastName = lastNameController.text.trim();
                        final email = emailController.text.trim();
                        final phone = phoneController.text.trim();

                        if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill all required fields")),
                          );
                          return;
                        }

                        Navigator.of(context).pop();

                        try {
                          if (docId == null) {
                            await firestoreService.addProfile(
                              userId: currentUser!.uid,
                              firstname: firstName,
                              lastname: lastName,
                              email: email,
                              contactno: phone,
                            );
                          } else {
                            await firestoreService.updateProfile(
                              docId: docId,
                              firstname: firstName,
                              lastname: lastName,
                              email: email,
                              contactno: phone,
                            );
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Profile \"$firstName $lastName\" saved")),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text(docId == null ? "SAVE" : "UPDATE"),
                      ),
                    ),
              ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.teal),
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        filled: true,
        fillColor: Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = currentUser?.uid;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade700, Colors.teal.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: const Text('Profile', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<DocumentSnapshot>(
              stream: firestoreService.getProfile(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final profileData = snapshot.data!.data() as Map<String, dynamic>?;
                if (profileData == null) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_add_alt_1, size: 60, color: Colors.grey),
                          const SizedBox(height: 20),
                          const Text("No profile found", style: TextStyle(fontSize: 18)),
                          TextButton(
                            onPressed: () => _showEditProfileDialog(context),
                            child: const Text('Create Profile', 
                                style: TextStyle(color: Colors.teal, fontSize: 16)),
                          )
                        ],
                      ),
                    ),
                  );
                }

                final firstName = profileData['first_name'];
                final lastName = profileData['last_name'];
                final email = profileData['email'];
                final phone = profileData['phone'];

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: profileHeight,
                            width: profileHeight,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.teal.withOpacity(0.2),
                                  blurRadius: 12,
                                  spreadRadius: 6,
                                )
                              ],
                            ),
                            child: CircleAvatar(
                              radius: profileHeight / 2,
                              backgroundColor: Colors.teal.shade100,
                              child: Text(
                                firstName != null && firstName.isNotEmpty ? firstName[0] : 'U',
                                style: TextStyle(
                                  fontSize: 48,
                                  color: Colors.teal.shade800,
                                  fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.teal),
                                onPressed: () => _showEditProfileDialog(
                                  context,
                                  docId: snapshot.data!.id,
                                  first_name: firstName,
                                  last_name: lastName,
                                  email: email,
                                  phone: phone,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildProfileItem(Icons.person, 'Name', '$firstName $lastName'),
                              const Divider(height: 30),
                              _buildProfileItem(Icons.email, 'Email', email),
                              const Divider(height: 30),
                              _buildProfileItem(Icons.phone, 'Phone', phone),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditProfileDialog(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.teal, size: 28),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
              const SizedBox(height: 5),
              Text(value, style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}