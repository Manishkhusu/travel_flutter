import 'package:flutter/material.dart';
import 'package:flutter_xploverse/feature2/expense/add_expense_dialog.dart';
import 'package:flutter_xploverse/feature2/expense/expenselist.dart';
import 'package:flutter_xploverse/feature2/favourite_page.dart';
import 'package:flutter_xploverse/feature2/landingpage.dart';
import 'package:flutter_xploverse/feature2/languagetranslator/translatorpg.dart'; // Corrected import path
import 'package:flutter_xploverse/feature2/profile_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({Key? key}) : super(key: key);

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      LandingPage(),
      FavoritesPage(),
      Translatorpg(),
      ExpenseListScreen(), // Keep this line. It adds the expense list
      ProfilePage(),
    ];
  }

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
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore), //Replace the icons
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite), //Replace the icons
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.translate), //Replace the icons
              label: 'Translator',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.money), //Replace the icons
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person), //Replace the icons
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
