import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../custom/custom_blue_button.dart';
import '../custom/dialogs/recommend_routine_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewRoutineSheet extends StatefulWidget {
  final DateTime selectedDate;

  const NewRoutineSheet({super.key, required this.selectedDate});

  @override
  State<NewRoutineSheet> createState() => _NewRoutineSheetState();
}

class _NewRoutineSheetState extends State<NewRoutineSheet> {
  final titleController = TextEditingController();
  final goalController = TextEditingController();
  bool isEditingTitle = false;
  bool isEditingGoal = false;
  String routineCategory = 'custom';
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();
  bool showTimeError = false;
  bool showTimeOrderError = false;

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
        return StatefulBuilder(
          builder: (context, setStateDialog) {
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
                    final selectedHour = selectedDuration.inHours;

                    if (selectedHour >= 12) {
                      setState(() {
                        showTimeError = true;
                      });
                    } else {
                      setState(() {
                        showTimeError = false;
                      });
                      onTimeSelected(TimeOfDay(
                        hour: selectedHour,
                        minute: selectedDuration.inMinutes % 60,
                      ));
                    }
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
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
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 제목 입력 영역
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
                          fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: '새 루틴 제목을 입력해주세요...',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Divider(thickness: 1, color: Colors.grey.shade400),
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
                            ? Colors.grey
                            : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    isEditingTitle = true;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 30),

          Align(
            alignment: Alignment.centerLeft,
            child: const Text('시간 및 날짜',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 20),
              const SizedBox(width: 12),
              Text(dateStr, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
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
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 6),
                    Text(startStr, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Text('~', style: TextStyle(fontSize: 18)),
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
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 6),
                    Text(endStr, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
          if (showTimeError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '오전 시간만 선택할 수 있어요.',
                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
              ),
            ),
          if (showTimeOrderError)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '시작 시간은 종료 시간보다 빨라야 해요.',
                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
              ),
            ),

          const SizedBox(height: 30),
          const Divider(thickness: 1),
          const SizedBox(height: 30),

          Align(
            alignment: Alignment.centerLeft,
            child: const Text('목표',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),

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
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: '한 줄 목표를 작성해보세요...',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Divider(thickness: 1, color: Colors.grey.shade400),
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
                            ? Colors.grey
                            : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    isEditingGoal = true;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 30),

          Column(
            children: [
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => RecommendRoutineList(
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
                  '아침 루틴에는 이런 것들이 있어요!',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.black87,
                    fontSize: 18,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // 나만의 루틴 가져오기
                },
                child: const Text(
                  '나만의 루틴 가져오기',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.black87,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 50),

          CustomBlueButton(
            text: '루틴 추가하기',
            onPressed: () async {
              setState(() {
                showTimeOrderError =
                !_isStartTimeBeforeEndTime(startTime, endTime);
              });
              if (showTimeOrderError) return;

              if (routineCategory != 'recommend') {
                routineCategory = 'custom';
              }

              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getString('userId');

              if (userId == null) {
                print('SharedPreferences에 userId 없음');
                return;
              }

              try {
                final query = await FirebaseFirestore.instance
                    .collection('users')
                    .where('userId', isEqualTo: userId)
                    .limit(1)
                    .get();

                if (query.docs.isEmpty) {
                  print('userId가 일치하는 문서 없음');
                  return;
                }

                final userDocId = query.docs.first.id;

                final routineData = {
                  'title': titleController.text,
                  'routineType': 'morning',
                  'date': DateFormat('yyyy-MM-dd')
                      .format(widget.selectedDate),
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
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    goalController.dispose();
    super.dispose();
  }
}
