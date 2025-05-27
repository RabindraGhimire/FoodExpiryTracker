import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

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
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'DK');

  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _obscurePassword = true;

  // NEW: controls if validation errors should show
  bool _autoValidate = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<bool> _showDocumentDialog(String title, String content) async {
    bool accepted = false;
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(child: Text(content)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Decline'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Accept'),
              ),
            ],
          ),
    ).then((value) => accepted = value ?? false);

    return accepted;
  }

  Future<void> _handleTermsTapped() async {
    if (_acceptedTerms) {
      setState(() {
        _acceptedTerms = false;
        _acceptedPrivacy = false;
      });
    } else {
      bool accepted = await _showDocumentDialog(
        "Terms & Conditions",
        "Your full terms and conditions text here...",
      );
      if (accepted) setState(() => _acceptedTerms = true);
    }
  }

  Future<void> _handlePrivacyTapped() async {
    if (_acceptedPrivacy) {
      setState(() => _acceptedPrivacy = false);
    } else {
      bool accepted = await _showDocumentDialog(
        "Privacy Policy",
        "Your full privacy policy text here...",
      );
      if (accepted) setState(() => _acceptedPrivacy = true);
    }
  }

  Future<void> _signUp() async {
    // Enable auto-validation on submit
    setState(() {
      _autoValidate = true;
    });

    if (_formKey.currentState!.validate()) {
      if (!_acceptedTerms) {
        _showSnack("Please accept the Terms & Conditions");
        return;
      }
      if (!_acceptedPrivacy) {
        _showSnack("Please accept the Privacy Policy");
        return;
      }

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        final UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(userCredential.user!.uid)
            .set({
              'first_name': _firstNameController.text.trim(),
              'last_name': _lastNameController.text.trim(),
              'email': email,
              'phone': _phoneNumber.phoneNumber,
              'address': _addressController.text.trim(),
              'created_at': FieldValue.serverTimestamp(),
              'updated_at': FieldValue.serverTimestamp(),
            });

        _clearForm();
        if (!mounted) return;
        _showSuccessAndNavigate();
      } on FirebaseAuthException catch (e) {
        _handleAuthError(e);
      } on FirebaseException catch (e) {
        _handleFirestoreError(e);
      } catch (e) {
        _handleGenericError(e);
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.orange),
    );
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _addressController.clear();
    setState(() {
      _acceptedTerms = false;
      _acceptedPrivacy = false;
      _phoneNumber = PhoneNumber(isoCode: 'US');
      _autoValidate = false; // reset validation mode on clear
    });
  }

  void _showSuccessAndNavigate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Account created successfully!"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  void _handleAuthError(FirebaseAuthException e) {
    String message = "Signup failed: ";
    switch (e.code) {
      case 'weak-password':
        message += "Password must be at least 6 characters";
        break;
      case 'email-already-in-use':
        message += "Account already exists for this email";
        break;
      case 'invalid-email':
        message += "Invalid email address";
        break;
      default:
        message += "Authentication error";
    }
    _showSnack(message);
  }

  void _handleFirestoreError(FirebaseException e) {
    _showSnack("Database error: ${e.message ?? 'Unknown error'}");
  }

  void _handleGenericError(dynamic e) {
    _showSnack("Error: ${e.toString()}");
  }

  Widget _buildTermsCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _handleTermsTapped,
          child: Row(
            children: [
              Checkbox(
                value: _acceptedTerms,
                onChanged: (value) => _handleTermsTapped(),
                activeColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Text(
                  "Accept Terms & Conditions",
                  style: TextStyle(
                    color: Colors.black87,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_acceptedTerms) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _handlePrivacyTapped,
            child: Row(
              children: [
                Checkbox(
                  value: _acceptedPrivacy,
                  onChanged: (value) => _handlePrivacyTapped(),
                  activeColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Accept Privacy Policy",
                    style: TextStyle(
                      color: Colors.black87,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      autovalidateMode:
          _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Please enter your $label";
        if (label == "Email" &&
            !RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value)) {
          return "Invalid email format";
        }
        return null;
      },
    );
  }

  Widget _buildPhoneInput() {
    return InternationalPhoneNumberInput(
      onInputChanged: (PhoneNumber number) => _phoneNumber = number,
      initialValue: _phoneNumber,
      selectorConfig: const SelectorConfig(
        selectorType: PhoneInputSelectorType.DROPDOWN,
        showFlags: true,
        useEmoji: true,
      ),
      ignoreBlank: false,
      autoValidateMode:
          _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
      selectorTextStyle: const TextStyle(color: Colors.black),
      textFieldController: _phoneController,
      formatInput: true,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: false,
      ),
      inputDecoration: InputDecoration(
        labelText: "Phone Number",
        prefixIcon: const Icon(Icons.phone, color: Colors.teal),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      validator:
          (value) =>
              value == null || value.isEmpty
                  ? 'Please enter phone number'
                  : null,
      onSaved: (number) => _phoneNumber = number!,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      autovalidateMode:
          _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
      decoration: InputDecoration(
        labelText: "Password",
        prefixIcon: const Icon(Icons.lock, color: Colors.teal),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Please enter a password";
        if (value.length < 6) return "Minimum 6 characters required";
        return null;
      },
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _signUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: const Text(
          "CREATE ACCOUNT",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account?"),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Sign In",
            style: TextStyle(
              color: Colors.teal.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Create Account'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade700, Colors.teal.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                // Keep autovalidateMode here if you want to validate form on submission too,
                // but our fields handle autovalidateMode individually now.
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildInputField(
                      _firstNameController,
                      "First Name",
                      Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      _lastNameController,
                      "Last Name",
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      _emailController,
                      "Email",
                      Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildPhoneInput(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 16),
                    _buildInputField(_addressController, "Address", Icons.home),
                    const SizedBox(height: 24),
                    _buildTermsCheckboxes(),
                    const SizedBox(height: 24),
                    _buildSignUpButton(),
                    const SizedBox(height: 16),
                    _buildLoginLink(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
