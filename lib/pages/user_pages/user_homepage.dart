import 'package:flutter/material.dart';
import 'package:is_project_1/components/custom_bootom_navbar.dart';
import 'package:is_project_1/models/profile_response.dart';
import 'package:is_project_1/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:is_project_1/pages/user_pages/safety_tips_page.dart';

class UserHomepage extends StatefulWidget {
  const UserHomepage({super.key});

  @override
  State<UserHomepage> createState() => _UserHomepageState();
}

class SafetyTip {
  final String title;
  final String content;

  SafetyTip({required this.title, required this.content});

  factory SafetyTip.fromJson(Map<String, dynamic> json) {
    return SafetyTip(
      title: json['title'] ?? 'Untitled',
      content: json['content'] ?? '',
    );
  }
}

class _UserHomepageState extends State<UserHomepage> {
  ProfileResponse? profile;
  List<EmergencyContact> emergencyContacts = [];
  bool isLoading = true;
  String? error;
  List<SafetyTip> safetyTips = [];
  bool tipsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _fetchSafetyTips();
  }

  Future<void> _fetchSafetyTips() async {
  try {
    final res = await http.get(Uri.parse('https://de6f-41-90-176-14.ngrok-free.app/get_tips'));
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      setState(() {
        safetyTips = data.map((e) => SafetyTip.fromJson(e)).toList();
        tipsLoading = false;
      });
    } else {
      setState(() => tipsLoading = false);
    }
  } catch (e) {
    print("Failed to load tips: $e");
    setState(() => tipsLoading = false);
  }
}

  Future<void> _loadProfileData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Load profile data
      final profileData = await ApiService.getProfile();

      List<EmergencyContact> contacts = [];
      // Only load emergency contacts for role_id == 5
      if (profileData.roleId == 5) {
        try {
          contacts = await ApiService.getEmergencyContacts();
        } catch (e) {
          // Emergency contacts are optional, don't fail the whole page
          print('Failed to load emergency contacts: $e');
        }
      }

      setState(() {
        profile = profileData;
        emergencyContacts = contacts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SafeGuard',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black87,
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions Section
            _buildSectionHeader('Quick Actions'),
            const SizedBox(height: 16),
            _buildQuickActionsGrid(),

            const SizedBox(height: 30),

            // Nearby Police Stations Section
            _buildSectionHeader('Nearby Police Stations'),
            const SizedBox(height: 16),
            _buildPoliceStationsCard(),

            const SizedBox(height: 30),

            // Safety Tips Section
            _buildSectionHeader('Safety Tips'),
            const SizedBox(height: 16),
            _buildSafetyTipsCard(),

            const SizedBox(height: 30),

            // Educational Content Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('Educational Content'),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'TRENDING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEducationalContent(),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildQuickActionItem(
                  Icons.upload_outlined,
                  'Upload Safety Tip',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionItem(
                  Icons.gavel_outlined,
                  'Legal Aid',
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionItem(
                  Icons.location_on_outlined,
                  'Share Location',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (emergencyContacts.isNotEmpty) {
                      final EmergencyContact contact = emergencyContacts.first;
                      final Uri url = Uri(
                        scheme: 'tel',
                        path: contact.contactNumber.replaceAll(
                          RegExp(r'[^\d+]'),
                          '',
                        ), // Clean the number
                      );

                      try {
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          print('Cannot launch phone app');
                        }
                      } catch (e) {
                        print('Error launching phone call: $e');
                      }
                    } else {
                      print('No emergency contacts available');
                    }
                  },
                  child: _buildQuickActionItem(
                    Icons.phone_outlined,
                    'Emergency Call',
                    Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        // Handle quick action tap
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliceStationsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Map placeholder
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFE8E8E8),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.local_police_outlined,
                size: 40,
                color: Colors.grey,
              ),
            ),
          ),

          // Police stations list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPoliceStationItem('Central Police Station', '0.5 km'),
                const SizedBox(height: 12),
                _buildPoliceStationItem('North Division', '1.2 km'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliceStationItem(String name, String distance) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.local_police, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          distance,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSafetyTipsCard() {
  if (tipsLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (safetyTips.isEmpty) {
    return const Text("No safety tips available.");
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ...safetyTips.take(2).map((tip) => _buildExpandableTipCard(tip)).toList(),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SafetyTipsPage()),
            );
          },
          child: const Text("See all →", style: TextStyle(color: Colors.blue)),
        ),
      ),
    ],
  );
}

  Widget _buildExpandableTipCard(SafetyTip tip) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
    margin: const EdgeInsets.only(bottom: 12),
    child: ExpansionTile(
      title: Text(tip.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(tip.content),
        )
      ],
    ),
  );
}

  Widget _buildSafetyTip(String tip) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tip,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEducationalContent() {
    return Column(
      children: [
        _buildEducationalItem(
          'Jiu-Jitsu',
          'Get to learn Jiu-Jitsu and protect and defend yourself.',
          'https://www.wikihow.com/images/thumb/4/49/Learn-Brazilian-Jiu%E2%80%90Jitsu-Step-12.jpg/v4-460px-Learn-Brazilian-Jiu%E2%80%90Jitsu-Step-12.jpg',
        ),
        const SizedBox(height: 16),
        _buildEducationalItem(
          'Karate',
          'Learn basic Karate and self-defense tips.',
          'https://images.unsplash.com/photo-1555597673-b21d5c935865?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1469&q=80',
        ),
      ],
    );
  }

  Widget _buildEducationalItem(
    String title,
    String description,
    String imageUrl,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Colors.grey,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
