import 'package:flutter/material.dart';
import 'package:is_project_1/components/custom_bootom_navbar.dart';
import 'package:is_project_1/models/profile_response.dart';
import 'package:is_project_1/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:is_project_1/pages/user_pages/safety_tips_page.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


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

class EducationalContent {
  final String title;
  final String content;
  final double price;
  final bool isPaid;
  final String id;

  EducationalContent({
    required this.id,
    required this.title,
    required this.content,
    required this.price,
    required this.isPaid,
  });

  factory EducationalContent.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    final double safePrice = rawPrice != null
        ? double.tryParse(rawPrice.toString()) ?? 0.0
        : 0.0;

    return EducationalContent(
      id: json['id'],
      title: json['title'] ?? 'Untitled',
      content: json['content'] ?? '',
      price: safePrice,
      isPaid: json['is_paid'] ?? true,
    );
  }
}

class _UserHomepageState extends State<UserHomepage> {
  final String baseUrl = dotenv.env['BASE_URL']!;

  ProfileResponse? profile;
  List<EmergencyContact> emergencyContacts = [];
  bool isLoading = true;
  String? error;
  List<SafetyTip> safetyTips = [];
  bool tipsLoading = true;
  List<EducationalContent> educationalItems = [];
  bool eduLoading = true;
  List<String> purchasedContentIds = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData().then((_) async {
      final userId = await _getUserIdFromToken();
      if (userId != null) {
        _fetchPurchasedContentIds(userId);
      } else {
        print("Failed to get user ID from token");
      }
    });

    _fetchSafetyTips();
    _fetchEducationalContent();
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
    if (profileData.roleId == 5) {
      try {
        contacts = await ApiService.getEmergencyContacts();
      } catch (e) {
        print('Failed to load emergency contacts: \$e');
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

  Future<void> _fetchSafetyTips() async {
    try {
      final String baseUrl = dotenv.env['BASE_URL']!;
      final res = await http.get(Uri.parse('$baseUrl/get_tips'));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          safetyTips = data.map((e) => SafetyTip.fromJson(e)).toList();
          tipsLoading = false;
        });
      } else {
        setState(() => tipsLoading = false);
        print("Failed to load safety tips: \${res.body}");
      }
    } catch (e) {
      print("Failed to load tips: \$e");
      setState(() => tipsLoading = false);
    }
  }

  Future<String?> _getUserIdFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      try {
        final payload = token.split('.')[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final payloadMap = json.decode(decoded);
        return payloadMap['sub']?.toString();
      } catch (e) {
        print('JWT decode error: \$e');
      }
    }
    return null;
  }

  Future<void> _fetchEducationalContent() async {
    try {
      final String baseUrl = dotenv.env['BASE_URL']!;
      final res = await http.get(Uri.parse('$baseUrl/get_educational_content'));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          educationalItems = data.map((e) => EducationalContent.fromJson(e)).toList();
          eduLoading = false;
        });
      } else {
        setState(() => eduLoading = false);
      }
    } catch (e) {
      print("Failed to fetch educational content: \$e");
      setState(() => eduLoading = false);
    }
  }

  Future<void> _fetchPurchasedContentIds(String userId) async {
    try {
      final String baseUrl = dotenv.env['BASE_URL']!;
      final res = await http.get(Uri.parse('$baseUrl/user_purchases/$userId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          purchasedContentIds = List<String>.from(data['purchased_ids']);
        });
        print("Purchased content: \$purchasedContentIds");
      } else {
        print("Failed to fetch purchases: \${res.body}");
      }
    } catch (e) {
      print("Error fetching purchases: \$e");
    }
  }

 Future<void> _startPaymentFlow(EducationalContent content) async {
  final userId = await _getUserIdFromToken(); // <-- FIXED
  if (userId == null || userId == "0") {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You must be logged in with a valid account to purchase.")),
    );
    return;
  }


  Future<void> capturePayment(String orderId, String contentId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/capture-order/$orderId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "user_id": userId,
        "content_id": contentId,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment successful!")),
      );
      await _fetchPurchasedContentIds(userId);
      setState(() {});
    } else {
      print("Capture payment failed: ${response.statusCode} ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment failed to capture.")),
      );
    }
  }

  final response = await http.post(
    Uri.parse('$baseUrl/create-order'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "user_id": userId,
      "content_id": content.id,
      "content_title": content.title,
      "amount": content.price.toString(),
      "currency": "USD",
    }),
  );

  if (response.statusCode != 200) {
    print("Create order failed: ${response.statusCode} ${response.body}");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to create PayPal order.")),
    );
    return;
  }

  final data = jsonDecode(response.body);
  final orderId = data["order_id"];
  final approvalUrl = data["approval_url"];

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("Complete Payment")),
        body: WebViewWidget(
          controller: WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(approvalUrl))
            ..setNavigationDelegate(
              NavigationDelegate(
                onNavigationRequest: (nav) async {
                  if (nav.url.contains("payment-success")) {
                    await capturePayment(orderId, content.id);
                    Navigator.pop(context, true);
                    return NavigationDecision.prevent;
                  }
                  return NavigationDecision.navigate;
                },
              ),
            ),
        ),
      ),
    ),
  );
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
      if (label == 'Upload Safety Tip') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SafetyTipsPage(showUploadDialog: true),
          ),
        );
      }
      // Add more actions for other labels if needed
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
      Center(
        child: ElevatedButton(
          onPressed: () async {
            final refreshed = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SafetyTipsPage()),
            );

            if (refreshed == true) {
              final userId = profile?.id?.toString();
              if (userId != null) {
                await _fetchPurchasedContentIds(userId);
                setState(() {});
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4FABCB),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            "See All",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
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
  if (eduLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (educationalItems.isEmpty) {
    return const Text("No educational content available.");
  }

  return Column(
    children: [
      ...educationalItems.take(2).map(_buildEducationalItem).toList(),
      const SizedBox(height: 8),
      Center(
        child: ElevatedButton(
          onPressed: () async {
            final refreshed = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SafetyTipsPage()),
            );

            if (refreshed == true) {
              final userId = profile?.id?.toString();
              if (userId != null) {
                await _fetchPurchasedContentIds(userId);
                setState(() {});
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4FABCB),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            "See All",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    ],
  );
}


void _showBottomSheetContent(String content) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(content),
        ),
      );
    },
  );
}


Widget _buildEducationalItem(EducationalContent item) {
  final unlockedIds = purchasedContentIds.map((e) => e.toString()).toList();
final isUnlocked = unlockedIds.contains(item.id.toString());

  return InkWell(
    onTap: () async {
      if (isUnlocked) {
        _showBottomSheetContent(item.content);
      } else {
        final shouldPay = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Unlock Content"),
            content: const Text("This is premium content. Do you want to purchase access?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Buy")),
            ],
          ),
        );
        // Handle purchase logic here if shouldPay == true
        if (shouldPay == true) {
          _startPaymentFlow(item);

        }
      }
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                      if (item.isPaid && !isUnlocked)
      Text(
        "\KES ${item.price.toStringAsFixed(2)}",
        style: const TextStyle(fontSize: 12, color: Colors.orange),
      ),
                  if (isUnlocked)
                    Text(
                      item.content,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
          if (item.isPaid)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                isUnlocked ? Icons.lock_open : Icons.lock_outline,
                color: isUnlocked ? Colors.green : Colors.grey,
              ),
            ),
        ],
      ),
    ),
  );
}
}