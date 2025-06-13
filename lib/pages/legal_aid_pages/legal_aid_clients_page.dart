import 'package:flutter/material.dart';
import 'package:is_project_1/components/custom_legal_navbar.dart';

class LegalAidClientsPage extends StatelessWidget {
  const LegalAidClientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF7BB3C7),
        elevation: 0,
        title: const Text(
          'FemAid Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Matched Clients Section
            _buildMatchedClientsSection(),
            const SizedBox(height: 24),
            // Recent Matches Section
            _buildRecentMatchesSection(),
          ],
        ),
      ),
      bottomNavigationBar: const CustomLegalNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildMatchedClientsSection() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Matched Clients',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildClientCard(
              name: 'Sarah Johnson',
              phone: '+1 (555) 123-4567',
              description: 'Seeking legal aid for domestic violence case',
              priority: 'Urgent',
              priorityColor: Colors.red,
            ),
            const SizedBox(height: 12),
            _buildClientCard(
              name: 'Maria Rodriguez',
              phone: '+1 (555) 987-6543',
              description: 'Requires for legal aid and sexual violence support',
              priority: 'High',
              priorityColor: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard({
    required String name,
    required String phone,
    required String description,
    required String priority,
    required Color priorityColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(phone, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMatchesSection() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Matches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildRecentMatchItem(
              name: 'Emma Thompson',
              time: '2 hrs ago',
              avatarColor: const Color(0xFF7BB3C7),
            ),
            _buildRecentMatchItem(
              name: 'Lisa Chen',
              time: '4 hrs ago',
              avatarColor: const Color(0xFF9B59B6),
            ),
            _buildRecentMatchItem(
              name: 'Anna Williams',
              time: '1 day ago',
              avatarColor: const Color(0xFFE67E22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMatchItem({
    required String name,
    required String time,
    required Color avatarColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: avatarColor.withOpacity(0.2),
            child: Text(
              name[0],
              style: TextStyle(
                color: avatarColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
