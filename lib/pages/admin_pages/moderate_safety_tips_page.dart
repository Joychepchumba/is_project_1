import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ModerateSafetyTipsPage extends StatefulWidget {
  const ModerateSafetyTipsPage({super.key});

  @override
  State<ModerateSafetyTipsPage> createState() => _ModerateSafetyTipsPageState();
}

class _ModerateSafetyTipsPageState extends State<ModerateSafetyTipsPage> {
  List<dynamic> safetyTips = [];
  final String baseUrl = dotenv.env['BASE_URL']!;

  @override
  void initState() {
    super.initState();
    _loadSafetyTips();
  }

  Future<void> _loadSafetyTips() async {
    final response = await http.get(Uri.parse('$baseUrl/safety_tips'));
    if (response.statusCode == 200) {
      setState(() {
        safetyTips = jsonDecode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch safety tips")),
      );
    }
  }

  Future<void> _updateTipStatus(int tipId, String action) async {
    final response = await http.put(
      Uri.parse('$baseUrl/safety_tips/$tipId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': action}),
    );
    if (response.statusCode == 200) {
      _loadSafetyTips();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tip updated: $action')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update tip")),
      );
    }
  }

  void _showConfirmDelete(BuildContext context, int tipId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this safety tip?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateTipStatus(tipId, 'delete');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderate Safety Tips'),
        backgroundColor: const Color(0xFF4FABCB),
      ),
      body: safetyTips.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: safetyTips.length,
              itemBuilder: (context, index) {
                final tip = safetyTips[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  child: ExpansionTile(
                    title: Text(
                      tip['title'] ?? '(No Title)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          tip['content'] ?? '(No Content)',
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _showConfirmDelete(context, tip['id']);
                              } else {
                                _updateTipStatus(tip['id'], value);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'verified', child: Text('Mark as Verified')),
                              PopupMenuItem(value: 'false', child: Text('Flag as False')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                            icon: const Icon(Icons.more_vert, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}