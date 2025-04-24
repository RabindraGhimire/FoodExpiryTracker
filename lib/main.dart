import 'package:firebase_core/firebase_core.dart';
import 'package:firstproject/data/notifier.dart';
import 'package:firstproject/firebase_options.dart';
import 'package:firstproject/views/widget_tree.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
              seedColor: Colors.red,
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
            ),
          ),
          home: const WidgetTree(),
        );
      },
    );
  }
}
