import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:is_project_1/components/custom_admin.navbar.dart';

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
    final response = await http.get(Uri.parse('https://de6f-41-90-176-14.ngrok-free.app/analytics/overview'));
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
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.trending_up, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Revenue Generated', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Educational content revenue breakdown', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (analytics['monthly_revenue'] != null && analytics['monthly_revenue'].isNotEmpty)
                      ? analytics['monthly_revenue']
                              .cast<Map<String, dynamic>>()
.map((item) => (item['total'] ?? 0).toDouble())
                              .reduce((a, b) => a > b ? a : b) +
                          1
                      : 10,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final rawList = analytics['monthly_revenue'] ?? [];
final months = List<Map<String, dynamic>>.from(rawList)
    .map((item) => item['month'].toString())
    .toList();
                          if (value.toInt() < months.length) {
                            return Transform.rotate(
                              angle: -0.5,
                              child: Text(months[value.toInt()], style: const TextStyle(fontSize: 9)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: Colors.grey[300]!, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    analytics['monthly_revenue']?.length ?? 0,
                    (index) {
                      final item = analytics['monthly_revenue'][index];
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: (item['total'] ?? 0).toDouble(),
                            rodStackItems: [],
                            color: Colors.teal,
                            width: 30,
                            borderRadius: BorderRadius.circular(4),
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

  Widget _buildDangerZonesCard() {
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
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Frequent Danger Zones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Incident reports by location', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 60,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final rawZones = analytics['danger_zones'] ?? [];
final locations = List<Map<String, dynamic>>.from(rawZones)
    .map((zone) => zone['location_name'].toString())
    .toList();
                          if (value.toInt() < locations.length) {
                            return Transform.rotate(
                              angle: -0.5,
                              child: Text(locations[value.toInt()], style: const TextStyle(fontSize: 9)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: Colors.grey[300]!, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    analytics['danger_zones']?.length ?? 0,
                    (index) {
                      final zone = analytics['danger_zones'][index];
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: (zone['reported_count'] ?? 0).toDouble(),
                            rodStackItems: [],
                            color: Colors.red,
                            width: 25,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Safety Tip Metrics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Total Tips: ${analytics['tips_total'] ?? 0}'),
          Text('Verified: ${analytics['tips_verified'] ?? 0}'),
          Text('Pending: ${analytics['tips_pending'] ?? 0}'),
          Text('Submitters: ${analytics['tips_submitters'] ?? 0}'),
          const SizedBox(height: 20),
         const SizedBox(height: 12),
        ],
      ),
    ),
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
