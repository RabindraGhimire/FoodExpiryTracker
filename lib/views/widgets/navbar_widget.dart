import 'package:firstproject/data/notifier.dart';
import 'package:flutter/material.dart';

class NavbarWidget extends StatefulWidget {
  const NavbarWidget({super.key});

  @override
  State<NavbarWidget> createState() => _NavbarWidgetState();
}

class _NavbarWidgetState extends State<NavbarWidget> {
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(valueListenable: selectedPageNotifier, 
    builder: (context, selectedPage, child) {
      return NavigationBar(
        destinations: [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.food_bank), label: 'Foods'),
          NavigationDestination(icon: Icon(Icons.groups), label: 'Community'),
          // NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          // NavigationDestination(icon: Icon(Icons.person), label: 'Sign Up')
        ],
        backgroundColor: Colors.teal,
        onDestinationSelected: (int value) {  
          selectedPageNotifier.value=value;
        },
        selectedIndex: selectedPage,
      );
    },);
  }
}