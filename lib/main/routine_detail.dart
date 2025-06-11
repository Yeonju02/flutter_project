import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../custom/date_slider.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'daily_routine.dart';
import '../custom/custom_blue_button.dart';
import 'new_routine.dart';

class RoutineDetailPage extends StatefulWidget {
  final DateTime date;

  const RoutineDetailPage({super.key, required this.date});

  @override
  State<RoutineDetailPage> createState() => _RoutineDetailPageState();
}

class _RoutineDetailPageState extends State<RoutineDetailPage> {
  late DateTime selectedDate;
  bool isDayMode = false;

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
            SizedBox(height: 8),

            // 연/월 + 뒤로가기 + 스위치
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '${selectedDate.year}',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        selectedDate.month.toString().padLeft(2, '0'),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Spacer(),
                  Padding(
                    padding: EdgeInsets.only(top: 40.0),
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

            SizedBox(height: 20),

            // 날짜 슬라이더
            DateSlider(
              initialDate: selectedDate,
              onDateSelected: (newDate) {
                setState(() {
                  selectedDate = newDate;
                });
              },
            ),

            SizedBox(height: 20),
            Divider(thickness: 1.2),
            SizedBox(height: 20),

            // 루틴 리스트
            Expanded(child: DailyRoutine()),

            Divider(thickness: 1.2),
            SizedBox(height: 20),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: CustomBlueButton(
                text: '루틴 추가하기',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: NewRoutineSheet(selectedDate: selectedDate),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 150),
          ],
        ),
      ),
    );
  }
}
