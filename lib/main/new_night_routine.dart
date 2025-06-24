import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../custom/custom_gery_button.dart';
import '../custom/dialogs/recommend_routine_list.dart';
import '../custom/dialogs/recommend_night_routine_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'set_sleep_cycle.dart';
import '../custom/dialogs/mine_night_routine_list_dialog.dart';
import '../custom/dialogs/custom_night_alert_dialog.dart';



class NewNightRoutineSheet extends StatefulWidget {
  final DateTime selectedDate;

  const NewNightRoutineSheet({super.key, required this.selectedDate});

  @override
  State<NewNightRoutineSheet> createState() => _NewNightRoutineSheetState();
}

class _NewNightRoutineSheetState extends State<NewNightRoutineSheet> {
  final titleController = TextEditingController();
  final goalController = TextEditingController();
  bool isEditingTitle = false;
  bool isEditingGoal = false;
  String routineCategory = 'custom';
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();
  bool showTimeOrderError = false;
  bool showInvalidNightTimeError = false;

  void _showTimePicker({
    required BuildContext outerContext,
    required TimeOfDay initialTime,
    required ValueChanged<TimeOfDay> onTimeSelected,
  }) {
    Duration selectedDuration = Duration(
      hours: initialTime.hour,
      minutes: initialTime.minute,
    );

    showCupertinoDialog(
      context: outerContext,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          content: SizedBox(
            height: 200,
            child: CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.hm,
              initialTimerDuration: selectedDuration,
              onTimerDurationChanged: (Duration newDuration) {
                selectedDuration = newDuration;
              },
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('확인'),
              onPressed: () {
                final picked = TimeOfDay(
                  hour: selectedDuration.inHours,
                  minute: selectedDuration.inMinutes % 60,
                );

                setState(() {
                  //  cycle 모드일 경우 오전 시간도 허용해주기
                  if (picked.hour < 12 && routineCategory != 'cycle') {
                    showInvalidNightTimeError = true;
                  } else {
                    showInvalidNightTimeError = false;
                    onTimeSelected(picked);
                  }
                });

                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  bool _isStartTimeBeforeEndTime(TimeOfDay start, TimeOfDay end) {
    final startTotalMinutes = start.hour * 60 + start.minute;
    final endTotalMinutes = end.hour * 60 + end.minute;
    return startTotalMinutes < endTotalMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final startStr = startTime.format(context);
    final endStr = endTime.format(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      decoration: const BoxDecoration(
        color: Color(0xFF182333),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade500,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 제목
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: isEditingTitle
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: '새 루틴 제목을 입력해주세요...',
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                      ),
                      Divider(thickness: 1, color: Colors.white38),
                    ],
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleController.text.isEmpty
                            ? '루틴 제목을 입력해주세요...'
                            : titleController.text,
                        style: TextStyle(
                          color: titleController.text.isEmpty
                              ? Colors.white54
                              : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(thickness: 1, color: Colors.white24),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.white70),
                  onPressed: () {
                    setState(() {
                      isEditingTitle = true;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            // 날짜
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.white),
                const SizedBox(width: 12),
                Text(dateStr,
                    style: const TextStyle(fontSize: 16, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),
            // 시간
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _showTimePicker(
                      outerContext: context,
                      initialTime: startTime,
                      onTimeSelected: (picked) {
                        setState(() {
                          startTime = picked;
                        });
                      },
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(startStr, style: const TextStyle(fontSize: 16, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Text('~', style: TextStyle(fontSize: 18, color: Colors.white)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    _showTimePicker(
                      outerContext: context,
                      initialTime: endTime,
                      onTimeSelected: (picked) {
                        setState(() {
                          endTime = picked;
                        });
                      },
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(endStr, style: const TextStyle(fontSize: 16, color: Colors.white)),
                      const SizedBox(width: 40),
                      GestureDetector(
                        onLongPress: () {
                          final overlay = Overlay.of(context);
                          final overlayEntry = OverlayEntry(
                            builder: (context) => Positioned(
                              top: MediaQuery.of(context).size.height * 0.6,
                              left: 30,
                              right: 30,
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '루틴 끝나는시간 기준 10분 이내로 체크해주셔야\n루틴 수행 성공으로 인정됩니다.',
                                    style: TextStyle(color: Colors.white, fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          );
                          overlay.insert(overlayEntry);
                          Future.delayed(const Duration(seconds: 3), () {
                            overlayEntry.remove();
                          });
                        },
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.question_mark, size: 12, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (showInvalidNightTimeError)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '오후 시간대만 선택할 수 있어요.',
                  style: TextStyle(color: Colors.red.shade300, fontSize: 14),
                ),
              ),
            if (showTimeOrderError)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '시작 시간은 종료 시간보다 빨라야 해요.',
                  style: TextStyle(color: Colors.red.shade300, fontSize: 14),
                ),
              ),
            const SizedBox(height: 30),
            Divider(thickness: 1, color: Colors.white30),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('목표',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
            const SizedBox(height: 10),
            // 목표
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: isEditingGoal
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: goalController,
                        style: const TextStyle(
                            fontSize: 16, color: Colors.white),
                        decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintText: '한 줄 목표를 작성해보세요...',
                            hintStyle: TextStyle(color: Colors.white54)),
                      ),
                      Divider(thickness: 1, color: Colors.white38),
                    ],
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goalController.text.isEmpty
                            ? '한 줄 목표를 작성해보세요...'
                            : goalController.text,
                        style: TextStyle(
                          color: goalController.text.isEmpty
                              ? Colors.white54
                              : Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Divider(thickness: 1, color: Colors.white24),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.white70),
                  onPressed: () {
                    setState(() {
                      isEditingGoal = true;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            // 추천 루틴
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => RecommendNightRoutineList(
                    titleController: titleController,
                    onClose: () {
                      Navigator.of(context).pop();
                      setState(() {
                        isEditingTitle = false;
                        routineCategory = 'recommend';
                      });
                    },
                  ),
                );
              },
              child: const Text(
                '밤 루틴에는 이런 것들이 있어요!',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => MineNightRoutineListDialog(
                    titleController: titleController,
                    onClose: () {
                      Navigator.of(context).pop();
                      setState(() {
                        isEditingTitle = false;
                      });
                    },
                  ),
                );
              },
              child: const Text(
                '나만의 루틴 가져오기',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
            //  수면 사이클 설정
            TextButton(
              onPressed: () async {
                final result = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SetSleepCyclePage(),
                  ),
                );

                if (result != null) {
                  final DateTime sleepTime = result['sleepTime'];
                  final DateTime wakeTime = result['wakeTime'];

                  setState(() {
                    startTime = TimeOfDay.fromDateTime(sleepTime);
                    endTime = TimeOfDay.fromDateTime(wakeTime);
                    titleController.text = '${wakeTime.hour.toString().padLeft(2, '0')}시 ${wakeTime.minute.toString().padLeft(2, '0')}분 기상';

                    routineCategory = 'cycle';
                    showInvalidNightTimeError = false;
                  });
                }
              },
              child: const Text(
                '수면 사이클 설정하기',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 15),
            // 저장 버튼
            CustomGeryButton(
              text: '루틴 추가하기',
              onPressed: () async {
                setState(() {
                  if (routineCategory == 'cycle') {
                    showTimeOrderError = false;
                  } else {
                    showTimeOrderError = !_isStartTimeBeforeEndTime(startTime, endTime);
                  }
                });
                if (showTimeOrderError || showInvalidNightTimeError) return;

                final prefs = await SharedPreferences.getInstance();
                final userId = prefs.getString('userId');
                if (userId == null) return;

                try {
                  final query = await FirebaseFirestore.instance
                      .collection('users')
                      .where('userId', isEqualTo: userId)
                      .limit(1)
                      .get();

                  if (query.docs.isEmpty) return;

                  final userDocId = query.docs.first.id;

                  // 해당 날짜에 루틴 10개인지 체크하기
                  final existingQuery = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userDocId)
                      .collection('routineLogs')
                      .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(widget.selectedDate))
                      .get();

                  if (existingQuery.docs.length >= 10) {
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (_) => const CustomNightAlertDialog(
                          title: '루틴 등록 제한!',
                          description: '해당 날짜에는 루틴을 10개 이상 등록할 수 없습니다.',
                        ),
                      );
                    }
                    return;
                  }

                  final routineData = {
                    'title': titleController.text,
                    'routineType': 'night',
                    'date': DateFormat('yyyy-MM-dd').format(widget.selectedDate),
                    'startTime': startTime.format(context),
                    'endTime': endTime.format(context),
                    'isFinished': false,
                    'xpEarned': 0,
                    'mood': '',
                    'goal': goalController.text,
                    'routineCategory': routineCategory,
                    'createdAt': Timestamp.now(),
                    'score': 0,
                  };

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userDocId)
                      .collection('routineLogs')
                      .add(routineData);

                  Navigator.pop(context, true);
                } catch (e) {
                  print('저장 중 오류 발생: $e');
                }
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    goalController.dispose();
    super.dispose();
  }
}
