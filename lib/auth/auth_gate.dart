import 'package:firebase_auth/firebase_auth.dart';
import 'package:firstproject/views/pages/home_page.dart';
import 'package:firstproject/views/pages/login_page.dart';
import 'package:firstproject/views/pages/profile_page.dart';
import 'package:flutter/material.dart';


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          return const HomePage(); // User is logged in
        } else {
          return const LoginPage(); // User is NOT logged in
        }
      },
    );
  }
}
