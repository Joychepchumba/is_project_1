import 'package:flutter/material.dart';
import 'package:is_project_1/components/custom_legal_navbar.dart';

class LegalCasesPage extends StatelessWidget {
  const LegalCasesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Your Cases',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              _buildCaseCard(
                caseType: 'Domestic Abuse Case',
                clientName: 'Jessee Wangari',
                phoneNumber: '077626262',
                description: 'Legal aid on domestic abuse case.',
                date: '15 April 2025',
              ),
              const SizedBox(height: 16),
              _buildCaseCard(
                caseType: 'Sexual Violence Case',
                clientName: 'Faith Syokimau',
                phoneNumber: '0771721926262',
                description: 'Legal aid on sexual violence case.',
                date: '15 April 2024',
              ),
              const SizedBox(height: 16),
              _buildCaseCard(
                caseType: 'Assault Case',
                clientName: 'Wantam',
                phoneNumber: '077921236262',
                description: 'Legal aid on assault case.',
                date: '15 January 2025',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomLegalNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildCaseCard({
    required String caseType,
    required String clientName,
    required String phoneNumber,
    required String description,
    required String date,
  }) {
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
            // Case type and date row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  caseType,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Client name with person icon
            Row(
              children: [
                Icon(Icons.person, size: 18, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  clientName,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Phone number with phone icon
            Row(
              children: [
                Icon(Icons.phone, size: 18, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  phoneNumber,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // View More button
            GestureDetector(
              onTap: () {
                // Handle view more action
              },
              child: Row(
                children: [
                  Text(
                    'View More',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 18, color: Colors.blue[600]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
