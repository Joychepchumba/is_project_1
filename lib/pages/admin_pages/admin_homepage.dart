import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:is_project_1/components/custom_admin.navbar.dart';
import 'package:is_project_1/pages/admin_pages/admin_analytics.dart';
import 'package:is_project_1/pages/admin_pages/manage_safety_tips.dart';
import 'package:is_project_1/pages/admin_pages/verify_providers.dart';

class UserDistribution {
  final int totalUsers;
  final int legalAidProviders;
  final int admins;

  UserDistribution({
    required this.totalUsers,
    required this.legalAidProviders,
    required this.admins,
  });

  factory UserDistribution.fromJson(Map<String, dynamic> json) {
    return UserDistribution(
      totalUsers: json['total_users'] ?? 0,
      legalAidProviders: json['legal_aid_providers'] ?? 0,
      admins: json['admins'] ?? 0,
    );
  }
}

class AdminHomepage extends StatefulWidget {
  const AdminHomepage({super.key});

  @override
  State<AdminHomepage> createState() => _AdminHomepageState();
}

class _AdminHomepageState extends State<AdminHomepage> {
  bool isLoading = true;
  String? error;
  String baseUrl = 'http://localhost:8000';

  UserDistribution? userDistribution;

  //static const String baseUrl = 'https://423c-197-136-185-70.ngrok-free.app';

  @override
  void initState() {
    super.initState();
    loadEnv();
    _loadAnalyticsData();
  }

  Future<void> loadEnv() async {
    try {
      await dotenv.load(fileName: ".env");
      setState(() {
        baseUrl = dotenv.env['API_BASE_URL'] ?? baseUrl;
      });
    } catch (e) {
      print('Error loading .env file: $e');
    }
  }

  Future<void> _loadAnalyticsData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Fetch all analytics data
      await Future.wait([_fetchUserDistribution()]);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'Failed to load analytics data: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchUserDistribution() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/user-distribution'),
        headers: {
          'Content-Type': 'application/json',
          // Add authorization header if needed
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        userDistribution = UserDistribution.fromJson(data);
      } else {
        throw Exception(
          'Failed to fetch user distribution: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching user distribution: $e');
      // Use mock data as fallback
      userDistribution = UserDistribution(
        totalUsers: 15,
        legalAidProviders: 5,
        admins: 3,
      );
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4FABCB), // RGB(79, 171, 203)
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // System Overview Section
            const Text(
              'System Overview',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Administrator Panel',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Show loading indicator or error message if needed
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF4FABCB)),
                ),
              )
            else if (error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadAnalyticsData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),

            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    isLoading
                        ? '--'
                        : _formatNumber(userDistribution?.totalUsers ?? 0),
                    'TOTAL USERS',
                    const Color(0xFF4FABCB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    isLoading
                        ? '--'
                        : _formatNumber(
                            userDistribution?.legalAidProviders ?? 0,
                          ),
                    'LEGAL PROVIDERS',
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '12',
                    'PENDING\nVERIFICATIONS',
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'KES 45K',
                    'MONTHLY REVENUE',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: TextButton.icon(
                onPressed: isLoading ? null : _loadAnalyticsData,
                icon: Icon(
                  Icons.refresh,
                  color: isLoading ? Colors.grey : const Color(0xFF4FABCB),
                ),
                label: Text(
                  isLoading ? 'Loading...' : 'Refresh Data',
                  style: TextStyle(
                    color: isLoading ? Colors.grey : const Color(0xFF4FABCB),
                  ),
                ),
              ),
            ),

            // Admin Actions Section
            Row(
              children: [
                const Text(
                  'Admin Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Items
            _buildActionItem(
              icon: Icons.check_circle,
              iconColor: Colors.red,
              title: 'Verify Providers',
              subtitle: 'Review pending applications',
              badge: '12',
              badgeColor: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VerifyProvidersPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildActionItem(
              icon: Icons.lightbulb,
              iconColor: const Color(0xFF4FABCB),
              title: 'Manage Safety Tips',
              subtitle: 'Review and moderate content',
              badge: '5',
              badgeColor: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageSafetyTips(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionItem(
              icon: Icons.bar_chart,
              iconColor: Colors.green,
              title: 'System Analytics',
              subtitle: 'Usage stats & performance',
              hasArrow: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminAnalyticsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomAdminNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getIconForLabel(label), color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get appropriate icons for different labels
  IconData _getIconForLabel(String label) {
    if (label.contains('USERS')) {
      return Icons.people;
    } else if (label.contains('LEGAL')) {
      return Icons.gavel;
    } else if (label.contains('PENDING')) {
      return Icons.pending_actions;
    } else if (label.contains('REVENUE')) {
      return Icons.attach_money;
    }
    return Icons.analytics;
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    bool hasArrow = false,
    required VoidCallback onTap, // ✅ Change Null Function to VoidCallback
  }) {
    return InkWell(
      onTap: onTap, // ✅ Trigger tap
      borderRadius: BorderRadius.circular(12), // optional ripple border
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor ?? Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (hasArrow)
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
