import 'package:flutter/material.dart';
import '../custom/routine_box.dart';

class DailyRoutine extends StatefulWidget {
  const DailyRoutine({super.key});

  @override
  State<DailyRoutine> createState() => _DailyRoutineState();
}

class _DailyRoutineState extends State<DailyRoutine> with TickerProviderStateMixin {
  final routineList = [
    {'time': '07:00', 'title': '기상하기', 'hasAlarm': false},
    {'time': '08:30', 'title': '10분 스트레칭 하기', 'hasAlarm': false},
    {'time': '09:00', 'title': '명상하기', 'hasAlarm': true},
    {'time': '09:30', 'title': '샤워하기', 'hasAlarm': false},
  ];

  late List<bool> isCheckedList;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _lineAnimations;

  @override
  void initState() {
    super.initState();
    isCheckedList = List.generate(routineList.length, (_) => false);

    _controllers = List.generate(
      routineList.length,
          (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _lineAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 60).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
  }

  void toggleCheck(int index) {
    setState(() {
      isCheckedList[index] = !isCheckedList[index];
      if (index < routineList.length - 1) {
        if (isCheckedList[index]) {
          _controllers[index].forward(from: 0);
        } else {
          _controllers[index].reset();
        }
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: routineList.length,
      itemBuilder: (context, index) {
        final isChecked = isCheckedList[index];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isChecked ? Colors.blue : Colors.grey.shade400,
                  ),
                ),
                if (index != routineList.length - 1)
                  SizedBox(
                    width: 2,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // 회색 배경선
                        Container(color: Colors.grey.shade300),
                        // 파란 선 애니메이션
                        AnimatedBuilder(
                          animation: _lineAnimations[index],
                          builder: (context, child) {
                            return Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: 2,
                                height: _lineAnimations[index].value,
                                color: Colors.blue,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RoutineBox(
                time: routineList[index]['time'] as String,
                title: routineList[index]['title'] as String,
                hasAlarm: routineList[index]['hasAlarm'] as bool,
                isChecked: isChecked,
                onToggle: () => toggleCheck(index),
              ),
            ),
          ],
        );
      },
    );
  }
}
