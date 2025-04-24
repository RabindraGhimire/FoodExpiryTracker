import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _acceptTerms = false;

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        // Create user with Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        final uid = userCredential.user!.uid;

        // Save additional user info to Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'email': email,
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'created_at': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sign-up successful")),
        );

        // Clear fields
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _passwordController.clear();
        _addressController.clear();

        Navigator.pop(context); // Go back to Login page

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } else if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept the terms and conditions")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up'), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildInputField(_firstNameController, "First Name"),
              _buildInputField(_lastNameController, "Last Name"),
              _buildInputField(_emailController, "Email", keyboardType: TextInputType.emailAddress),
              _buildInputField(_phoneController, "Phone Number", keyboardType: TextInputType.phone),
              _buildInputField(_passwordController, "Password", obscureText: true),
              _buildInputField(_addressController, "Address"),
              Row(
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (bool? value) {
                      setState(() {
                        _acceptTerms = value ?? false;
                      });
                    },
                  ),
                  const Text("I accept the terms and conditions"),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signUp,
                child: const Text("Sign Up"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.teal),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return "$label is required";
          if (label == "Email" &&
              !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
            return "Enter a valid email";
          }
          if (label == "Phone Number" && value.length != 10) {
            return "Enter a valid phone number";
          }
          if (label == "Password" && value.length < 6) {
            return "Password must be at least 6 characters long";
          }
          return null;
        },
      ),
    );
  }
}
