import 'package:flutter/material.dart';
import 'package:is_project_1/pages/legal_aid_pages/legal_aid_cases_page.dart';
import 'package:is_project_1/pages/legal_aid_pages/legal_aid_clients_page.dart';
import 'package:is_project_1/pages/legal_aid_pages/legalaid_homepage.dart';

import 'package:is_project_1/pages/profile_page.dart';

class CustomLegalNavigationBar extends StatelessWidget {
  final int currentIndex;

  const CustomLegalNavigationBar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (currentIndex == index) {
      return; // Don't navigate if already on the same page
    }

    // Navigate to the appropriate page based on index
    switch (index) {
      case 0:
        // Navigate to Home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LegalAidHomepage()),
          (route) => false,
        );
        break;
      case 1:
        // Navigate to Legal Aid
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LegalAidClientsPage()),
          (route) => false,
        );
        break;
      case 2:
        // Navigate to Maps
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LegalCasesPage()),
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
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
        BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Cases'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
