import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:clockin/presentation/screens/diary/diarytl_screen.dart';
import 'package:clockin/presentation/screens/settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

 @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  final navigationKey = GlobalKey<CurvedNavigationBarState>();
  int index = 1;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = const <Widget>[
      DiarytlScreen(), 
      SizedBox.shrink(), 
      SettingsScreen(), 
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.access_time, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ];
    return Scaffold(
      extendBody: true,
      body: index == 1
          ? const Center(
              child: Text(
                'Clock View',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            )
          : pages[index],
      bottomNavigationBar: CurvedNavigationBar(
        key: navigationKey,
        height: 60,
        color: Colors.black,
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: Colors.black,
        animationDuration: Duration(milliseconds: 400),
        items: items,
        index: index, 
        onTap: (index) => setState(() => this.index = index), // Handle navigation tap
      ),
    );
  }
}
