import 'package:flutter/material.dart';
import 'package:flutter_xploverse/feature2/favourite_page.dart';
import 'package:flutter_xploverse/feature2/landingpage.dart';
import 'package:flutter_xploverse/feature2/languagetranslator/translatorpg.dart';
import 'package:flutter_xploverse/feature2/map/presentation/view/map_screen.dart';
import 'package:flutter_xploverse/feature2/profile_page.dart';
// Import TranslationPage

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({Key? key}) : super(key: key);

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    LandingPage(),
    FavoritesPage(),
    MapPage(),
    Translatorpg(), // Add TranslationPage
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.black,
          selectedItemColor: Colors.yellow[700],
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed, //Add this
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.translate), // Add Translation
              label: 'Translate',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
