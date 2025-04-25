import 'package:firebase_auth/firebase_auth.dart';
import 'package:firstproject/data/notifier.dart';
import 'package:firstproject/views/pages/community_page.dart';
import 'package:firstproject/views/pages/foods_page.dart';
import 'package:firstproject/views/pages/home_page.dart';
import 'package:firstproject/views/pages/profile_page.dart';
import 'package:firstproject/views/widgets/navbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:firstproject/views/pages/login_page.dart';

String? title = 'Food Expiry Tracker';

// Define the list of pages for the bottom navigation
List<Widget> pages = [
  HomePage(),
  FoodsPage(),
  CommunityPage(),
];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  // Show log-out confirmation dialog
  void _showLogOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          // Log out button
          TextButton(
            onPressed: () async {
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
    // StreamBuilder to handle the user login status
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator if waiting for user state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Get the current user
        User? user = snapshot.data;

        // If user is not logged in, show the login page
        if (user == null) {
          return const LoginPage();
        }

        // Fallback to 'U' if displayName is unavailable
        String usernameFirstLetter = user.displayName != null && user.displayName!.isNotEmpty
            ? user.displayName![0]
            : 'U';

        return Scaffold(
          appBar: AppBar(
            title: Text(title!),
            actions: [
              // Profile and Log out options
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
                      _showLogOutDialog(context);
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      // Profile Settings option
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
                      // Log Out option
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
              // Dark mode toggle button
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
          // Body of the app based on selected page from bottom navigation
          body: ValueListenableBuilder(
            valueListenable: selectedPageNotifier,
            builder: (context, selectedPage, child) {
              return pages.elementAt(selectedPage);
            },
          ),
          // Bottom navigation bar
          bottomNavigationBar: NavbarWidget(),
        );
      },
    );
  }
}
