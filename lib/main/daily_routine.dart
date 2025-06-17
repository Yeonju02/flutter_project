import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routinelogapp/main/routine_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

  TimeOfDay _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return TimeOfDay.now();
    try {
      final match = RegExp(r'(\d{1,2}):(\d{2})\s*([aApP][mM])').firstMatch(timeStr);
      if (match == null) throw FormatException('시간 형식 아님: \$timeStr');
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      String ampm = match.group(3)!.toUpperCase();
      if (ampm == 'PM' && hour != 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return TimeOfDay(hour: 0, minute: 0);
    }
  }

  int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  TimeOfDay _addMinutes(TimeOfDay time, int minutesToAdd) {
    int totalMinutes = _toMinutes(time) + minutesToAdd;
    return TimeOfDay(hour: totalMinutes ~/ 60 % 24, minute: totalMinutes % 60);
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

    routines.sort((a, b) {
      final aVal = _toMinutes(_parseTime(a['startTime']));
      final bVal = _toMinutes(_parseTime(b['startTime']));
      return aVal.compareTo(bVal);
    });

    for (final c in _controllers) {
      c.dispose();
    }

    setState(() {
      routineList = routines;
      isCheckedList = routines.map((routine) => routine['isFinished'] == true).toList();
      _controllers = List.generate(
        routines.length,
            (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 600)),
      );
      _lineAnimations = _controllers.map((controller) {
        return Tween<double>(begin: 0, end: 60).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeInOut),
        );
      }).toList();

      for (int i = 0; i < routines.length - 1; i++) {
        if (isCheckedList[i]) {
          _controllers[i].forward();
        }
      }
    });
  }

  void toggleCheck(int index) async {
    final item = routineList[index];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);

    print('📆 오늘 날짜: $today');
    print('📆 선택된 날짜: $selectedDay');

    if (selectedDay.isAfter(today)) {
      print('🚫 미래 루틴 - 체크 불가');
      Fluttertoast.showToast(
        msg: "미래 루틴은 체크할 수 없습니다.",
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    final nowTime = TimeOfDay.now();
    final endTime = _parseTime(item['endTime']);
    final nowMinutes = _toMinutes(nowTime);
    final endMinutes = _toMinutes(endTime);

    if (selectedDay.isAtSameMomentAs(today) && nowMinutes < endMinutes) {
      Fluttertoast.showToast(
        msg: "아직 루틴 수행 시간이 아닙니다.",
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    if (index > 0 && !isCheckedList[index - 1]) {
      Fluttertoast.showToast(
        msg: "이전 루틴을 먼저 완료해주세요.",
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    final docId = item['docId'];
    final deadline = _addMinutes(endTime, 10);
    final deadlineMinutes = _toMinutes(deadline);
    final isLate = nowMinutes > deadlineMinutes;

    final willBeChecked = !isCheckedList[index];

    setState(() {
      isCheckedList[index] = willBeChecked;
      routineList[index]['xpEarned'] = willBeChecked ? (isLate ? 0 : 10) : 0;

      if (index < _controllers.length - 1) {
        if (willBeChecked) {
          _controllers[index].forward(from: 0);
        } else {
          _controllers[index].reset();
        }
      }
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userDocId)
        .collection('routineLogs')
        .doc(docId)
        .update({
      'isFinished': willBeChecked,
      'xpEarned': willBeChecked ? (isLate ? 0 : 10) : 0,
    });

    print('📤 Firestore 업데이트 완료');
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
        final xpEarned = item['xpEarned'] ?? 0;

        final dotColor = isChecked
            ? (xpEarned > 0 ? Colors.blue : Colors.red)
            : Colors.grey.shade400;

        final lineColor = isChecked
            ? (xpEarned > 0 ? Colors.blue : Colors.red)
            : Colors.grey.shade300;

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
                    color: dotColor,
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
                                color: lineColor,
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
                routineId: item['docId'],
                startTime: item['startTime'] ?? '',
                endTime: item['endTime'] ?? '',
                title: item['title'] ?? '',
                goal: item['goal'] ?? '',
                routineType: item['routineType'] ?? '',
                routineCategory: item['routineCategory'] ?? '',
                isChecked: isChecked,
                onToggle: () => toggleCheck(index),
                routineData: item,
                onEdit: () async {
                  final result = await showModalBottomSheet(
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
                  if (result == true) {
                    await fetchRoutines();

                    final parentState = context.findAncestorStateOfType<RoutineDetailPageState>();
                    parentState?.sliderKey.currentState?.refresh();
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
