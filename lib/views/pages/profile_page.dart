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
      {String? docId, String? firstname, String? lastname, String? email, String? contactno}) {
    final TextEditingController firstNameController = TextEditingController(text: firstname);
    final TextEditingController lastNameController = TextEditingController(text: lastname);
    final TextEditingController emailController = TextEditingController(text: email);
    final TextEditingController phoneController = TextEditingController(text: contactno);

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
                      child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final firstName = firstNameController.text.trim();
                        final lastName = lastNameController.text.trim();
                        final email = emailController.text.trim();
                        final phone = phoneController.text.trim();

                        if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill all required fields")));
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
                            SnackBar(content: Text("Profile \"$firstName $lastName\" saved")));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),),
                      child: Text(docId == null ? "SAVE" : "UPDATE", 
                          style: const TextStyle(fontSize: 16)),
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

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

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
                const Text(
                  "Change Password",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock, color: Colors.teal),
                    labelText: "Current Password",
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureCurrentPassword = !obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.teal),
                    labelText: "New Password",
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_reset, color: Colors.teal),
                    labelText: "Confirm New Password",
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
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
                        final currentPassword = currentPasswordController.text.trim();
                        final newPassword = newPasswordController.text.trim();
                        final confirmPassword = confirmPasswordController.text.trim();

                        if (currentPassword.isEmpty || 
                            newPassword.isEmpty || 
                            confirmPassword.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill all password fields")));
                          return;
                        }

                        if (newPassword != confirmPassword) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("New passwords don't match")));
                          return;
                        }

                        if (newPassword.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Password must be at least 6 characters")));
                          return;
                        }

                        try {
                          // Reauthenticate user
                          final credential = EmailAuthProvider.credential(
                            email: currentUser!.email!,
                            password: currentPassword,
                          );
                          await currentUser!.reauthenticateWithCredential(credential);

                          // Change password
                          await currentUser!.updatePassword(newPassword);

                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Password changed successfully")));
                        } on FirebaseAuthException catch (e) {
                          String errorMessage = "Password change failed";
                          if (e.code == 'wrong-password') {
                            errorMessage = "Current password is incorrect";
                          } else if (e.code == 'requires-recent-login') {
                            errorMessage = "This operation is sensitive and requires recent authentication. Log in again before retrying this request.";
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMessage)));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: ${e.toString()}")));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Text('CHANGE', style: TextStyle(fontSize: 16)),
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
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
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
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    // child: Text(
                    //   'Your Profile',
                    //   style: TextStyle(
                    //     color: Colors.white.withOpacity(0.9),
                    //     fontSize: 18,
                    //     fontWeight: FontWeight.w500
                    //   ),
                    // ),
                  ),
                ),
              ),
              title: const Text('Profile', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  firestoreService.getProfile(userId).first.then((snapshot) {
                    if (snapshot.exists) {
                      final data = snapshot.data() as Map<String, dynamic>;
                      _showEditProfileDialog(
                        context,
                        docId: snapshot.id,
                        firstname: data['first_name'],
                        lastname: data['last_name'],
                        email: data['email'],
                        contactno: data['phone'],
                      );
                    } else {
                      _showEditProfileDialog(context);
                    }
                  });
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<DocumentSnapshot>(
              stream: firestoreService.getProfile(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildEmptyProfileState(context);
                }

                final profileData = snapshot.data!.data() as Map<String, dynamic>;
                return _buildProfileContent(context, snapshot.data!.id, profileData);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProfileState(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_alt_1, size: 60, color: Colors.teal),
            ),
            const SizedBox(height: 24),
            const Text(
              "No Profile Found",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              "Create your profile to get started",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showEditProfileDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Create Profile',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, String docId, Map<String, dynamic> profileData) {
    final firstName = profileData['first_name'] ?? '';
    final lastName = profileData['last_name'] ?? '';
    final email = profileData['email'] ?? 'Not provided';
    final phone = profileData['phone'] ?? 'Not provided';

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
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
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
                child: GestureDetector(
                  onTap: () => _showEditProfileDialog(
                    context,
                    docId: docId,
                    firstname: firstName,
                    lastname: lastName,
                    email: email,
                    contactno: phone,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
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
                    child: const Icon(Icons.edit, color: Colors.teal, size: 24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '$firstName $lastName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileItem(Icons.person_outline, 'Full Name', '$firstName $lastName'),
                  const Divider(height: 30, thickness: 0.5),
                  _buildProfileItem(Icons.email_outlined, 'Email Address', email),
                  const Divider(height: 30, thickness: 0.5),
                  _buildProfileItem(Icons.phone_outlined, 'Phone Number', phone),
                  const Divider(height: 30, thickness: 0.5),
                  GestureDetector(
                    onTap: () => _showChangePasswordDialog(context),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_outline, color: Colors.teal, size: 20),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Password',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '••••••••',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () => _showEditProfileDialog(
                context,
                docId: docId,
                firstname: firstName,
                lastname: lastName,
                email: email,
                contactno: phone,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.teal.shade400, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit Profile', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.teal, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}