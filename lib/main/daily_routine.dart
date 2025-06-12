import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../custom/routine_box.dart';
import 'routine_edit.dart';

class DailyRoutine extends StatefulWidget {
  final DateTime selectedDate;
  final String routineType;

  const DailyRoutine({
    super.key,
    required this.selectedDate,
    required this.routineType,
  });

  @override
  State<DailyRoutine> createState() => _DailyRoutineState();
}

class _DailyRoutineState extends State<DailyRoutine> with TickerProviderStateMixin {
  List<Map<String, dynamic>> routineList = [];
  List<bool> isCheckedList = [];
  List<AnimationController> _controllers = [];
  List<Animation<double>> _lineAnimations = [];

  String? userDocId;

  @override
  void initState() {
    super.initState();
    fetchRoutines();
  }

  @override
  void didUpdateWidget(covariant DailyRoutine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate || widget.routineType != oldWidget.routineType) {
      fetchRoutines();
    }
  }

  Future<void> fetchRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;

    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) return;

    userDocId = userQuery.docs.first.id;
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

    final routinesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userDocId)
        .collection('routineLogs')
        .where('date', isEqualTo: dateStr)
        .where('routineType', isEqualTo: widget.routineType)
        .get();

    List<Map<String, dynamic>> routines = routinesSnapshot.docs.map((doc) {
      return {
        ...doc.data(),
        'docId': doc.id,
      };
    }).toList();

    // ⏱️ 클라이언트 정렬 (시간 파싱 후 정렬)
    routines.sort((a, b) {
      final aVal = _timeValue(a['startTime']);
      final bVal = _timeValue(b['startTime']);
      return aVal.compareTo(bVal);
    });

    for (final c in _controllers) {
      c.dispose();
    }

    setState(() {
      routineList = routines;
      isCheckedList = List.generate(routines.length, (_) => false);
      _controllers = List.generate(
        routines.length,
            (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 600)),
      );
      _lineAnimations = _controllers.map((controller) {
        return Tween<double>(begin: 0, end: 60).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeInOut),
        );
      }).toList();
    });
  }

  // 🔧 AM/PM 시간 문자열을 정렬 가능한 숫자로 변환
  int _timeValue(String? timeStr) {
    if (timeStr == null) return 0;

    final match = RegExp(r'(\d{1,2}):(\d{2})\s*([aApP][mM])').firstMatch(timeStr);
    if (match == null) return 0;

    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    String ampm = match.group(3)!.toUpperCase();

    if (ampm == 'PM' && hour != 12) hour += 12;
    if (ampm == 'AM' && hour == 12) hour = 0;

    return hour * 60 + minute;
  }

  void toggleCheck(int index) {
    setState(() {
      isCheckedList[index] = !isCheckedList[index];
      if (index < _controllers.length - 1) {
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
    if (routineList.isEmpty) {
      return const Center(child: Text('등록된 루틴이 없습니다.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: routineList.length,
      itemBuilder: (context, index) {
        final isChecked = isCheckedList[index];
        final item = routineList[index];

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
                        Container(color: Colors.grey.shade300),
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
                startTime: item['startTime'] ?? '',
                endTime: item['endTime'] ?? '',
                title: item['title'] ?? '',
                goal: item['goal'] ?? '',
                routineType: item['routineType'] ?? '',
                routineCategory: item['routineCategory'] ?? '',
                isChecked: isChecked,
                onToggle: () => toggleCheck(index),
                routineData: item,
                onEdit: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => RoutineEditDialog(
                      routineData: item,
                      userDocId: userDocId!,
                      routineDocId: item['docId'],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
