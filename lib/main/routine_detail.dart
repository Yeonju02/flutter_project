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
  State<RoutineDetailPage> createState() => RoutineDetailPageState();
}

class RoutineDetailPageState extends State<RoutineDetailPage> {
  late DateTime selectedDate;
  bool isDayMode = false;
  final GlobalKey<DateSliderState> sliderKey = GlobalKey();

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

            // 연/월 + 뒤로가기 + 스위치
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
                        onPressed: () => Navigator.pop(context, true),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${selectedDate.year}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        selectedDate.month.toString().padLeft(2, '0'),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Spacer(),
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
              key: sliderKey,
              initialDate: selectedDate,
              onDateSelected: (newDate) {
                setState(() {
                  selectedDate = newDate;
                });
              },
            ),

            const SizedBox(height: 20),
            const Divider(thickness: 1.2),
            const SizedBox(height: 20),

            // 루틴 리스트
            Expanded(
              child: DailyRoutine(
                key: UniqueKey(), // 매번 새로 갱신되도록
                selectedDate: selectedDate,
                routineType: isDayMode ? 'night' : 'morning',
              ),
            ),
            const Divider(thickness: 1.2),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: CustomBlueButton(
                text: '루틴 추가하기',
                onPressed: () async {
                  final result = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: NewRoutineSheet(selectedDate: selectedDate),
                    ),
                  );

                  if (result == true) {
                    setState(() {}); // DailyRoutine 갱신
                    sliderKey.currentState?.refresh();
                  }
                },
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
