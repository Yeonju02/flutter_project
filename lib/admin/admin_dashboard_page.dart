import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

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
  int todaySales = 0;
  int totalSales = 0;
  int newUsersToday = 0;

  List<FlSpot> salesSpots = [];
  List<FlSpot> userSpots = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final now = DateTime.now();
    final monthFormatter = DateFormat('yyyy-MM');
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final ordersSnapshot = await FirebaseFirestore.instance.collectionGroup('orders').get();
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

    int todayTotal = 0;
    int allTotal = 0;
    int todayNew = 0;

    Map<String, double> monthlySalesMap = {};
    Map<String, int> monthlyUserMap = {};

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final label = monthFormatter.format(month);
      monthlySalesMap[label] = 0;
      monthlyUserMap[label] = 0;
    }

    for (var order in ordersSnapshot.docs) {
      final data = order.data() as Map<String, dynamic>;
      final ts = (data['orderedAt'] as Timestamp?)?.toDate();
      final price = (data['productPrice'] as int?) ?? 0;
      allTotal += price;

      if (ts != null) {
        final orderMonth = monthFormatter.format(ts);
        if (monthlySalesMap.containsKey(orderMonth)) {
          monthlySalesMap[orderMonth] = (monthlySalesMap[orderMonth] ?? 0) + price;
        }
        if (ts.isAfter(today) && ts.isBefore(tomorrow)) {
          todayTotal += price;
        }
      }
    }

    for (var user in usersSnapshot.docs) {
      final data = user.data() as Map<String, dynamic>;
      final ts = (data['joinedAt'] as Timestamp?)?.toDate();
      if (ts != null) {
        final userMonth = monthFormatter.format(ts);
        if (monthlyUserMap.containsKey(userMonth)) {
          monthlyUserMap[userMonth] = (monthlyUserMap[userMonth] ?? 0) + 1;
        }
        if (ts.isAfter(today) && ts.isBefore(tomorrow)) {
          todayNew++;
        }
      }
    }

    final salesSpotsList = monthlySalesMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final userSpotsList = monthlyUserMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    setState(() {
      todaySales = todayTotal;
      totalSales = allTotal;
      newUsersToday = todayNew;

      salesSpots = List.generate(
        salesSpotsList.length,
            (i) => FlSpot(i.toDouble(), salesSpotsList[i].value),
      );

      userSpots = List.generate(
        userSpotsList.length,
            (i) => FlSpot(i.toDouble(), max(0, userSpotsList[i].value.toDouble())),
      );
    });
  }

  Widget _buildSummaryCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(String title, List<FlSpot> data) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FA),
        borderRadius: BorderRadius.circular(16),
      ),
      height: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: LineChart(LineChartData(
              minY: 0,
              lineBarsData: [
                LineChartBarData(
                  spots: data,
                  isCurved: false,
                  barWidth: 3,
                  color: const Color(0xFF819CFF),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: _getYAxisInterval(data),
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _formatYAxisLabel(value),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true, horizontalInterval: _getYAxisInterval(data)),
            )),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF819CFF),
        title: Row(
          children: [
            Image.asset('assets/admin_logo.png', height: 28),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MainPage())),
              child: const Text('Main', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildSummaryCard('오늘 매출', '${formatter.format(todaySales)}원'),
                _buildSummaryCard('총 매출', '${formatter.format(totalSales)}원'),
                _buildSummaryCard('신규 가입자', '$newUsersToday명'),
              ],
            ),
            const SizedBox(height: 20),
            _buildLineChart('최근 6개월 매출 추이', salesSpots),
            _buildLineChart('최근 6개월 가입자 추이', userSpots),
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
}

double _getYAxisInterval(List<FlSpot> data) {
  final maxValue = data.map((e) => e.y).fold(0.0, max);

  if (maxValue <= 10_000) return 2_000;
  if (maxValue <= 50_000) return 5_000;
  if (maxValue <= 100_000) return 10_000;
  if (maxValue <= 300_000) return 30_000;
  if (maxValue <= 1_000_000) return 100_000;
  return 200_000;
}

String _formatYAxisLabel(double value) {
  if (value >= 100000) {
    return '${(value / 10000).toStringAsFixed(0)}만';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(0)}k';
  } else {
    return value.toInt().toString();
  }
}

