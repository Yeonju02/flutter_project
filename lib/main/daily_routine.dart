import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routinelogapp/main/routine_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../custom/routine_box.dart';
import 'routine_edit.dart';
import '../custom/dialogs/xp_dialog.dart';

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
  int userLevel = 1;
  int userXP = 0;

  @override
  void initState() {
    super.initState();
    fetchRoutines();
    fetchUserStatus();
  }

  Future<void> fetchUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;

    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) return;

    final userData = userQuery.docs.first.data();
    userDocId = userQuery.docs.first.id;
    setState(() {
      userLevel = userData['level'] ?? 1;
      userXP = userData['xp'] ?? 0;
    });
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

    if (selectedDay.isAfter(today)) return;

    final nowTime = TimeOfDay.now();
    final startTime = _parseTime(item['startTime']);
    final endTime = _parseTime(item['endTime']);

    final nowMinutes = _toMinutes(nowTime);
    final startMinutes = _toMinutes(startTime);
    final endMinutes = _toMinutes(endTime);

    if (selectedDay.isAtSameMomentAs(today) && nowMinutes < startMinutes) return;
    if (index > 0 && !isCheckedList[index - 1]) return;

    final docId = item['docId'];
    final deadline = _addMinutes(endTime, 10);
    final deadlineMinutes = _toMinutes(deadline);
    final isLate = nowMinutes > deadlineMinutes;

    final willBeChecked = !isCheckedList[index];
    int baseXP = willBeChecked ? (isLate ? 0 : 10) : 0;

    int streakCount = 0;
    if (willBeChecked && baseXP > 0) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userDocId).get();
      streakCount = userDoc.data()?['streakCount'] ?? 0;

      final bonusRate = (streakCount >= 5 ? 5 : streakCount) * 0.1;
      baseXP = (baseXP + baseXP * bonusRate).round();
    }

    int earnedXP = baseXP;


    if (willBeChecked && earnedXP > 0) {
      final successQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDocId)
          .collection('routineLogs')
          .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(today))
          .where('isFinished', isEqualTo: true)
          .where('xpEarned', isGreaterThan: 0)
          .get();

      // 경험치 5번 먹었는지 확인하고 제한
      if (successQuery.docs.length >= 5) {
        earnedXP = 1;
      }
    }

    setState(() {
      isCheckedList[index] = willBeChecked;
      routineList[index]['xpEarned'] = earnedXP;

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
      'xpEarned': earnedXP,
    });

    // 추천 루틴 미션 처리
    if (willBeChecked && item['routineCategory'] == 'recommend') {
      final missionQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDocId)
          .collection('missions')
          .where('missionTitle', isEqualTo: '아침 & 밤 추천 루틴 중 하나 수행하기')
          .limit(1)
          .get();

      if (missionQuery.docs.isNotEmpty) {
        final missionDoc = missionQuery.docs.first;
        final data = missionDoc.data();
        final current = (data['recentCount'] ?? 0).toInt();
        final max = (data['maxCount'] ?? 1).toInt();

        if (current < max) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userDocId)
              .collection('missions')
              .doc(missionDoc.id)
              .update({'recentCount': current + 1});
        }
      }

      final allMissionQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDocId)
          .collection('missions')
          .where('missionTitle', isEqualTo: '모든 미션 완료하기')
          .limit(1)
          .get();

      if (allMissionQuery.docs.isNotEmpty) {
        final allMissionDoc = allMissionQuery.docs.first;
        final allData = allMissionDoc.data();
        final allCurrent = (allData['recentCount'] ?? 0).toInt();
        final allMax = (allData['maxCount'] ?? 1).toInt();

        if (allCurrent < allMax) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userDocId)
              .collection('missions')
              .doc(allMissionDoc.id)
              .update({'recentCount': allCurrent + 1});
        }
      }
    }

    if (willBeChecked && earnedXP > 0) {
      Future.delayed(const Duration(milliseconds: 300), () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => XpDialog(
            currentLevel: userLevel,
            currentXP: userXP,
            earnedXP: earnedXP,
            userDocId: userDocId!,
          ),
        );
      });
    }
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
