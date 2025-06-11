import 'package:flutter/material.dart';
import 'package:is_project_1/pages/user_pages/map_page.dart';
import 'package:is_project_1/pages/profile_page.dart';
import 'package:is_project_1/pages/user_pages/user_homepage.dart';
import 'package:is_project_1/pages/user_pages/user_legalaid.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final dynamic currentIndex;

  const CustomBottomNavigationBar({Key? key, required this.currentIndex})
    : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    if (currentIndex == index)
      return; // Don't navigate if already on the same page

    // Navigate to the appropriate page based on index
    switch (index) {
      case 0:
        // Navigate to Home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const UserHomepage()),
          (route) => false,
        );
        break;
      case 1:
        // Navigate to Legal Aid
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const UserLegalaid()),
          (route) => false,
        );
        break;
      case 2:
        // Navigate to Maps
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MapPage()),
          (route) => false,
        );
        break;
      case 3:
        // Navigate to Profile
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF4FABCB),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.gavel), // Legal/Justice icon
          label: 'Legal Aid',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map), // Map icon
          label: 'Maps',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
