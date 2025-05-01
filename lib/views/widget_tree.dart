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
  FoodsPage(showAddForm: true,),
  CommunityPage(),
];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  void _showLogOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        
        if (user == null) {
          return const LoginPage();
        }

        final usernameFirstLetter = user.email?.isNotEmpty == true 
            ? user.email![0].toUpperCase() 
            : 'U';

        return Scaffold(
          appBar: AppBar(
            title: Text(title ?? 'Food Expiry Tracker'),
            actions: [
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
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.account_circle),
                          SizedBox(width: 10),
                          Text('Profile Settings'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 10),
                          Text('Log Out'),
                        ],
                      ),
                    ),
                  ],
                  child: CircleAvatar(
                    child: Text(usernameFirstLetter),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => isDarkModeNotifier.value = !isDarkModeNotifier.value,
                icon: ValueListenableBuilder(
                  valueListenable: isDarkModeNotifier,
                  builder: (context, isDarkMode, child) => Icon(
                    isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  ),
                ),
              ),
            ],
            centerTitle: true,
            backgroundColor: Colors.teal,
          ),
          body: ValueListenableBuilder(
            valueListenable: selectedPageNotifier,
            builder: (context, selectedPage, child) => pages.elementAt(selectedPage),
          ),
          bottomNavigationBar: const NavbarWidget(),
        );
      },
    );
  }
}
