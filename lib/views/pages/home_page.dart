import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home Page')));
      // body: Center(
      //   child: Text('Home Page'),
      // ),
    //   floatingActionButton: FloatingActionButton(
    //     onPressed: () {
    //       // Action when the FAB is pressed
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         SnackBar(content: Text('Floating Action Button Pressed')),
    //       );
    //     },
    //     child: Icon(Icons.add), // You can change the icon if needed
    //   ),
    // );
  }
}
