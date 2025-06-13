import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:is_project_1/components/custom_bootom_navbar.dart';

class SafetyTipsPage extends StatefulWidget {
  const SafetyTipsPage({super.key});

  @override
  State<SafetyTipsPage> createState() => _SafetyTipsPageState();
}

class _SafetyTipsPageState extends State<SafetyTipsPage> {
  List<Map<String, dynamic>> safetyTips = [];
  final int _selectedIndex = 2; // Set default index for navigation
  final String baseUrl = 'http://your-local-ip:8000'; // Replace with your server's actual IP

  @override
  void initState() {
    super.initState();
    fetchSafetyTips();
  }

  Future<void> fetchSafetyTips() async {
    final response = await http.get(Uri.parse('$baseUrl/get_tips/'));
    if (response.statusCode == 200) {
      setState(() {
        safetyTips = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    } else {
      print("Failed to fetch safety tips: ${response.body}");
    }
  }

  void _showAddTipDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add a Safety Tip'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Content')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Self-Defense', 'Street Safety', 'Community Warnings', 'Travel Safety']
                    .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                    .toList(),
                onChanged: (value) => setState(() => selectedCategory = value),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedCategory != null) {
                  await uploadTip(titleController.text, contentController.text, selectedCategory!);
                  Navigator.pop(context);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> uploadTip(String title, String content, String category) async {
    final Map<String, dynamic> tipData = {
      "title": title,
      "content": content,
      "category": category,
      "submitted_by": "anonymous",  // You can replace this with the logged-in user
      "submitted_by_role": "user",
      "status": "pending"
    };

    final response = await http.post(
      Uri.parse('$baseUrl/upload_tip/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(tipData),
    );

    if (response.statusCode == 200) {
      fetchSafetyTips();
    } else {
      print("Failed to upload tip: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety Tips')),
      body: safetyTips.isEmpty
          ? const Center(child: Text('No safety tips available. Add one!'))
          : ListView.builder(
              itemCount: safetyTips.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: ListTile(
                    title: Text(safetyTips[index]['title']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(safetyTips[index]['content']),
                        Text('Category: ${safetyTips[index]['category']}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTipDialog,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: _selectedIndex),
    );
  }
}