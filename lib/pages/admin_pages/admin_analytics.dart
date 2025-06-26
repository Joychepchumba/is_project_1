import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:is_project_1/components/custom_admin.navbar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  Map<String, dynamic> analytics = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    final String baseUrl = dotenv.env['BASE_URL']!;
    final response = await http.get(Uri.parse('$baseUrl/analytics/overview'));
    if (response.statusCode == 200) {
      setState(() {
        analytics = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load analytics")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics Dashboard',
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              'Monitor app usage and performance metrics',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: const [
          Icon(Icons.notifications_outlined, color: Colors.black),
          SizedBox(width: 12),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    _buildUsageMetricsCard(),
                    const SizedBox(height: 20),
                    _buildRevenueCard(),
                    const SizedBox(height: 20),
                    _buildDangerZonesCard(),
                    const SizedBox(height: 20),
                    _buildSafetyTipsCard(),
                ],
              ),
            ),
      bottomNavigationBar: const CustomAdminNavigationBar(currentIndex: 2),
    );
  }

  Widget _buildUsageMetricsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.analytics, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Usage Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('User Distribution', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: [
                    PieChartSectionData(
                      color: Colors.blue,
                      value: (analytics['providers'] ?? 0).toDouble(),
                      title: '${analytics['providers'] ?? 0}',
                      radius: 50,
                    ),
                    PieChartSectionData(
                      color: const Color.fromARGB(255, 244, 152, 3),
                      value: (analytics['users'] ?? 0).toDouble(),
                      title: '${analytics['users'] ?? 0}',
                      radius: 50,
                    ),
                    PieChartSectionData(
                      color: Colors.grey[300]!,
                      value: (analytics['admins'] ?? 0).toDouble(),
                      title: '${analytics['admins'] ?? 0}',
                      radius: 50,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Legal Aid Providers', Colors.blue),
                _buildLegendItem('Users', const Color.fromARGB(255, 244, 152, 3)),
                _buildLegendItem('Admin', Colors.grey[300]!),
              ],
            ),
          ],
        ),
      ),
    );
  }

Widget _buildRevenueCard() {
  final totalRevenue = analytics['total_revenue'] ?? 0;
  final topContent = analytics['top_content'] ?? [];
  final recent = analytics['recent_purchases'] ?? [];

  return Card(
    elevation: 3,
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.teal),
              SizedBox(width: 8),
              Text('Revenue Overview', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),

          Text("💰 Total Revenue Generated", style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          Text("KSh $totalRevenue",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.teal)),
          const Divider(height: 32),

          // Top Content in pill cards
          if (topContent.isNotEmpty) ...[
            const Text("🏆 Top Purchased Content", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Column(
              children: topContent.map<Widget>((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item['title'], style: const TextStyle(fontSize: 14))),
                      Text("KSh ${item['total']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const Divider(height: 32),
          ],

          // Recent Purchases
          const Text("🕒 Latest Purchases", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.builder(
              itemCount: recent.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final tx = recent[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long, size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx['title'], style: const TextStyle(fontSize: 14)),
                            Text(tx['date'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Text("KSh ${tx['amount']}", style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    ),
  );
}

Widget _buildDangerZonesCard() {
  final List zones = analytics['danger_zones'] ?? [];

  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: zones.isEmpty
          ? Center(
              child: Text(
                'No data available for danger zones.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.warning_amber_rounded,
                          color: Colors.redAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Frequent Danger Zones',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Incident reports by location',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      maxY: zones.fold<double>(
                          0, (max, z) => max > z['reported_count'] ? max : z['reported_count'].toDouble() + 10),
                      alignment: BarChartAlignment.spaceBetween,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (val, _) => Text(
                              val.toInt().toString(),
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              if (value.toInt() >= zones.length) return const SizedBox.shrink();
                              final name = zones[value.toInt()]['location_name'];
                              return Text(
                                name.length > 8
                                    ? '${name.substring(0, 6)}...'
                                    : name,
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: 10,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey[300],
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(
                        zones.length,
                        (index) {
                          final count = (zones[index]['reported_count'] ?? 0).toDouble();
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: count,
                                color: Colors.redAccent,
                                width: 20,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
    ),
  );
}

Widget _buildSafetyTipsCard() {
  final total = analytics['tips_total'] ?? 0;
  final verified = analytics['tips_verified'] ?? 0;
  final pending = analytics['tips_pending'] ?? 0;
  final submitters = analytics['tips_submitters'] ?? 0;

  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_outline,
                    color: Colors.orangeAccent, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                'Safety Tips',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat('Total', total, Colors.blue),
              _buildStat('Verified', verified, Colors.green),
              _buildStat('Pending', pending, Colors.amber.shade800),
              _buildStat('Submitters', submitters, Colors.purple),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildStat(String label, int value, Color color) {
  return Column(
    children: [
      Text(
        '$value',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    ],
  );
}

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
