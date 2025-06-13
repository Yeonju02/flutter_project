import 'package:flutter/material.dart';
import 'routine_detail.dart';
import '../custom/date_slider.dart';
import 'daily_routine.dart';
import '../custom/custom_blue_button.dart';
import 'new_routine.dart';
import 'package:intl/intl.dart';
import 'package:flutter_switch/flutter_switch.dart';

class NightRoutineDetailPage extends StatefulWidget {
  final DateTime date;

  const NightRoutineDetailPage({super.key, required this.date});

  @override
  State<NightRoutineDetailPage> createState() => _NightRoutineDetailPageState();
}

class _NightRoutineDetailPageState extends State<NightRoutineDetailPage> {
  late DateTime selectedDate;
  final GlobalKey<DateSliderState> sliderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    selectedDate = widget.date;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
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
                        constraints: BoxConstraints(),
                      ),
                      const SizedBox(height: 10),
                      Text('${selectedDate.year}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(selectedDate.month.toString().padLeft(2, '0'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Spacer(),
                  Padding(
                    padding: EdgeInsets.only(top: 40.0),
                    child: FlutterSwitch(
                      width: 60,
                      height: 30,
                      toggleSize: 25,
                      value: true, // 밤 루틴은 항상 true
                      activeColor: Colors.indigo,
                      inactiveColor: Colors.grey.shade200,
                      toggleColor: Colors.white,
                      activeIcon: Image.asset('assets/moon.png', width: 20, height: 20),
                      inactiveIcon: Image.asset('assets/sun.png', width: 20, height: 20),
                      onToggle: (val) {
                        if (!val) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoutineDetailPage(date: selectedDate),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
            Expanded(
              child: DailyRoutine(
                key: UniqueKey(),
                selectedDate: selectedDate,
                routineType: 'night',
              ),
            ),
            const Divider(thickness: 1.2),
            const SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: CustomBlueButton(
                text: '루틴 추가하기',
                onPressed: () async {
                  final result = await showModalBottomSheet(
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

                  if (result == true) {
                    setState(() {});
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
