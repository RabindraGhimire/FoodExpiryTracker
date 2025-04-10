import 'package:firstproject/data/notifier.dart';
import 'package:firstproject/views/pages/community_page.dart';
import 'package:firstproject/views/pages/foods_page.dart';
import 'package:firstproject/views/pages/home_page.dart';
import 'package:firstproject/views/pages/profile_page.dart';
import 'package:firstproject/views/widgets/navbar_widget.dart';
import 'package:flutter/material.dart';

String? title='Food Expiry Tracker';

List<Widget> pages=[
  HomePage(),
  FoodsPage(),
  CommunityPage(),
  ProfilePage()
  
];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title!),
        actions: [
          IconButton(
            onPressed: (){
              isDarkModeNotifier.value=!isDarkModeNotifier.value;
            }, 
            icon: ValueListenableBuilder(valueListenable: isDarkModeNotifier, builder: (context, isDarkMode, child) {
              return Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode
              );
            },
              ),
          ),
        ],
        centerTitle: true,
        // leading: Icon(Icons.login),
        // actions: [
        //   Text('asdadasd'),
        //   Icon(Icons.login),
        // ],
        backgroundColor: Colors.teal,
      ),
      body:ValueListenableBuilder(
        valueListenable:  selectedPageNotifier,
        builder: (context, selectedPage, child) {
          return pages.elementAt(selectedPage);
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: (){},
      //   child: Icon(Icons.add),
      //   ),
      bottomNavigationBar:NavbarWidget(), 
    );
  }
}