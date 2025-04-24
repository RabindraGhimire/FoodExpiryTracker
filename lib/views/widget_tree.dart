import 'package:firebase_auth/firebase_auth.dart';
import 'package:firstproject/data/notifier.dart';
import 'package:firstproject/views/pages/community_page.dart';
import 'package:firstproject/views/pages/foods_page.dart';
import 'package:firstproject/views/pages/home_page.dart';
import 'package:firstproject/views/pages/profile_page.dart';
import 'package:firstproject/views/pages/signup_page.dart';
import 'package:firstproject/views/widgets/navbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:firstproject/views/pages/login_page.dart';

String? title = 'Food Expiry Tracker';

List<Widget> pages = [
  HomePage(),
  FoodsPage(),
  CommunityPage()
  
];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  // Function to show the confirmation dialog for log out
  void _showLogOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Sign out the user
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String usernameFirstLetter = user != null && user.displayName != null
        ? user.displayName![0]
        : 'U'; // Default to 'U' if the user name is unavailable

    return Scaffold(
      appBar: AppBar(
        title: Text(title!),
        actions: [
          // Profile Dropdown Icon (First letter of username)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                } else if (value == 'logout') {
                  _showLogOutDialog(context); // Show log out confirmation dialog
                }
              },
              itemBuilder: (context) {
                return [
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.account_circle),
                        SizedBox(width: 10),
                        Text('Profile Settings'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 10),
                        Text('Log Out'),
                      ],
                    ),
                  ),
                ];
              },
              child: CircleAvatar(
                child: Text(usernameFirstLetter), // Display first letter of username
              ),
            ),
          ),
          // Dark/Light mode toggle
          IconButton(
            onPressed: () {
              isDarkModeNotifier.value = !isDarkModeNotifier.value;
            },
            icon: ValueListenableBuilder(
              valueListenable: isDarkModeNotifier,
              builder: (context, isDarkMode, child) {
                return Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode);
              },
            ),
          ),
        ],
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: ValueListenableBuilder(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, child) {
          return pages.elementAt(selectedPage);
        },
      ),
      bottomNavigationBar: NavbarWidget(),
    );
  }
}
