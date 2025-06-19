import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../custom/admin_bottom_bar.dart';
import '../main/main_page.dart';
import 'admin_board_page.dart';
import 'admin_product_page.dart';
import 'admin_user_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final List<String> _last6Months = [];
  final Map<String, int> _monthlySales = {};
  final Map<String, int> _monthlySignups = {};
  int _totalSales = 0;
  int _totalSignups = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _prepareDateLabels();
    _fetchDashboardData();
  }

  void _prepareDateLabels() {
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final label = "${date.year}-${date.month.toString().padLeft(2, '0')}";
      _last6Months.add(label);
      _monthlySales[label] = 0;
      _monthlySignups[label] = 0;
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      // 가입자 수
      final userSnapshot = await FirebaseFirestore.instance.collection('users').get();
      _totalSignups = userSnapshot.size;
      for (var doc in userSnapshot.docs) {
        final data = doc.data();
        final ts = data['joinedAt'];
        if (ts is Timestamp) {
          final date = ts.toDate();
          final label = "${date.year}-${date.month.toString().padLeft(2, '0')}";
          if (_monthlySignups.containsKey(label)) {
            _monthlySignups[label] = _monthlySignups[label]! + 1;
          }
        }
      }

      // 매출
      int salesSum = 0;
      for (var userDoc in userSnapshot.docs) {
        final orders = await userDoc.reference.collection('orders').get();
        for (var order in orders.docs) {
          final price = order['productPrice'] ?? 0;
          final ts = order['createdAt'];
          if (ts is Timestamp) {
            final date = ts.toDate();
            final label = "${date.year}-${date.month.toString().padLeft(2, '0')}";
            if (_monthlySales.containsKey(label)) {
              if (price is int) {
                _monthlySales[label] = (_monthlySales[label] ?? 0) + price;
                salesSum += price;
              }
            }
          }
        }
      }
      _totalSales = salesSum;
    } catch (e) {
      print('Dashboard 데이터 로딩 오류: $e');
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF819CFF),
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 28),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MainPage())),
              child: const Text('Main', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatText('누적 총 매출액', _formatCurrency(_totalSales)),
            const SizedBox(height: 6),
            SizedBox(height: 150, child: _buildSalesChart()),

            const SizedBox(height: 24),

            _buildStatText('누적 가입자 수', '$_totalSignups명'),
            const SizedBox(height: 6),
            SizedBox(height: 150, child: _buildSignupChart()),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserAdminPage()));
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminBoardPage()));
              break;
            case 3:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminProductPage()));
              break;
          }
        },
      ),
    );
  }

  Widget _buildStatText(String title, String value) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    return BarChart(
      BarChartData(
        barGroups: _last6Months.asMap().entries.map((e) {
          final index = e.key;
          final label = e.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: (_monthlySales[label] ?? 0) / 10000, // 1만 단위로 줄임
                width: 16,
                color: const Color(0xFF819CFF),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) => Text(_last6Months[value.toInt()].substring(5)),
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildSignupChart() {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: _last6Months.asMap().entries.map((e) {
              final index = e.key;
              final label = e.value;
              return FlSpot(index.toDouble(), (_monthlySignups[label] ?? 0).toDouble());
            }).toList(),
            color: const Color(0xFF92BBE2),
            isCurved: true,
            barWidth: 4,
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF92BBE2).withOpacity(0.3),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) => Text(_last6Months[value.toInt()].substring(5)),
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true),
      ),
    );
  }

  String _formatCurrency(int number) {
    return '₩' + number.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }
}
