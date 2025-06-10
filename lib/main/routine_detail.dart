import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../custom/date_slider.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'daily_routine.dart';

class RoutineDetailPage extends StatefulWidget {
  final DateTime date;

  const RoutineDetailPage({super.key, required this.date});

  @override
  State<RoutineDetailPage> createState() => _RoutineDetailPageState();
}

class _RoutineDetailPageState extends State<RoutineDetailPage> {
  late DateTime selectedDate;
  bool isDayMode = true;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.date;
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('yyyy.MM.dd').format(selectedDate);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // 위쪽 묶음
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        selectedDate.month.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // 스위치: 전체 세로 높이 중간에 배치되도록 Align
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: FlutterSwitch(
                      width: 60,
                      height: 30,
                      toggleSize: 25,
                      value: isDayMode,
                      activeColor: Colors.indigo,
                      inactiveColor: Colors.grey.shade200,
                      toggleColor: Colors.white,
                      activeIcon: Image.asset('assets/moon.png', width: 20, height: 20),
                      inactiveIcon: Image.asset('assets/sun.png', width: 20, height: 20),
                      onToggle: (val) {
                        setState(() {
                          isDayMode = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 날짜 슬라이더
            DateSlider(
              initialDate: selectedDate,
              onDateSelected: (newDate) {
                setState(() {
                  selectedDate = newDate;
                });
              },
            ),

            const Divider(thickness: 1.2),

            const SizedBox(height: 12),
            const DailyRoutine(),
          ],
        ),
      ),
    );
  }
}
