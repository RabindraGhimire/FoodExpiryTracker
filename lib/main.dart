import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firstproject/data/notifier.dart';
import 'package:firstproject/firebase_options.dart';
import 'package:firstproject/views/pages/login_page.dart';
import 'package:firstproject/views/widget_tree.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // this line will throw if [DEFAULT] already exists
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      // if it’s *any* other Firebase error, we still want to know about it
      rethrow;
    }
    // otherwise: silently swallow the duplicate-app error
  }

  runApp(const MyApp());
}



class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal, // Changed to teal to match your app bar
              brightness: isDarkMode ? Brightness.light : Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: FutureBuilder(
            future: FirebaseAuth.instance.authStateChanges().first,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasData) {
                return const WidgetTree();
              } else {
                return const LoginPage();
              }
            },
          ),
        );
      },
    );
  }
}