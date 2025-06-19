import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class NightRoutineEditDialog extends StatefulWidget {
  final Map<String, dynamic> routineData;
  final String userDocId;
  final String routineDocId;

  const NightRoutineEditDialog({
    super.key,
    required this.routineData,
    required this.userDocId,
    required this.routineDocId,
  });

  @override
  State<NightRoutineEditDialog> createState() => _NightRoutineEditDialogState();
}

class _NightRoutineEditDialogState extends State<NightRoutineEditDialog> {
  late TextEditingController titleController;
  late TextEditingController goalController;
  late String date;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  int selectedMood = 2;
  double score = 0.0;

  bool isEditingTitle = false;
  bool isEditingGoal = false;
  bool showTimeOrderError = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.routineData['title'] ?? '');
    goalController = TextEditingController(text: widget.routineData['goal'] ?? '');
    date = widget.routineData['date'] ?? '';
    startTime = _parseTime(widget.routineData['startTime']);
    endTime = _parseTime(widget.routineData['endTime']);
    selectedMood = int.tryParse(widget.routineData['mood'] ?? '2') ?? 2;
    score = (widget.routineData['score'] ?? 0).toDouble();
  }

  TimeOfDay _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return TimeOfDay.now();
    try {
      final match = RegExp(r'(\d{1,2}):(\d{2})\s*([aApP][mM])').firstMatch(timeStr);
      if (match == null) throw FormatException('Invalid time format: $timeStr');
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

  bool _isStartTimeBeforeEndTime(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return startMinutes < endMinutes;
  }

  void _showTimePicker({
    required BuildContext outerContext,
    required TimeOfDay initialTime,
    required ValueChanged<TimeOfDay> onTimeSelected,
  }) {
    Duration selectedDuration = Duration(hours: initialTime.hour, minutes: initialTime.minute);
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
              child: Text('확인'),
              onPressed: () {
                final selectedHour = selectedDuration.inHours;
                setState(() {
                  onTimeSelected(TimeOfDay(
                    hour: selectedHour,
                    minute: selectedDuration.inMinutes % 60,
                  ));
                });
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveRoutine() async {
    final isRecommend = widget.routineData['routineCategory'] == 'recommend';
    final title = titleController.text;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userDocId)
          .collection('routineLogs')
          .doc(widget.routineDocId)
          .update({
        'title': title,
        'goal': goalController.text,
        'startTime': startTime.format(context),
        'endTime': endTime.format(context),
        'mood': selectedMood.toString(),
        'score': score,
        'updatedAt': Timestamp.now(),
      });

      if (isRecommend && score != 0) {
        final routineQuery = await FirebaseFirestore.instance
            .collection('routines')
            .where('title', isEqualTo: title)
            .limit(1)
            .get();

        if (routineQuery.docs.isNotEmpty) {
          final docRef = routineQuery.docs.first.reference;
          final data = routineQuery.docs.first.data();
          final currentScore = (data['score'] ?? 0).toDouble();
          final scoreCount = (data['scoreCount'] ?? 0).toInt();

          final newScoreCount = scoreCount + 1;
          final newAverageScore = ((currentScore * scoreCount) + score) / newScoreCount;

          await docRef.update({
            'scoreCount': newScoreCount,
            'score': newAverageScore,
          });
        }
      }

      Navigator.pop(context, true);
    } catch (e) {
      print('루틴 수정 실패: $e');
    }
  }

  Future<void> _deleteRoutine() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userDocId)
          .collection('routineLogs')
          .doc(widget.routineDocId)
          .delete();

      Navigator.pop(context, true);
    } catch (e) {
      print('루틴 삭제 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final startStr = startTime.format(context);
    final endStr = endTime.format(context);
    final moodEmojis = ['😡', '😕', '😊', '🤩'];
    final moodLabels = ['매우 나쁨', '나쁨', '좋음', '매우 좋음'];
    final isRecommend = widget.routineData['routineCategory'] == 'recommend';

    return Container(
      color: const Color(0xFF182333),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.circle_outlined, size: 20, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: isEditingTitle
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        enabled: !isRecommend,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        decoration: const InputDecoration(border: InputBorder.none),
                      ),
                      const Divider(color: Colors.grey),
                    ],
                  )
                      : GestureDetector(
                    onTap: () {
                      if (!isRecommend) setState(() => isEditingTitle = true);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleController.text,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isRecommend ? Colors.grey : Colors.white,
                          ),
                        ),
                        Divider(color: Colors.grey.shade300),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(children: [const Icon(Icons.calendar_today, color: Colors.white), const SizedBox(width: 8), Text(date, style: const TextStyle(color: Colors.white))]),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showTimePicker(outerContext: context, initialTime: startTime, onTimeSelected: (picked) => setState(() => startTime = picked)),
                  child: Row(children: [const Icon(Icons.access_time, color: Colors.white), const SizedBox(width: 8), Text(startStr, style: const TextStyle(color: Colors.white))]),
                ),
                const SizedBox(width: 12),
                const Text('~', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showTimePicker(outerContext: context, initialTime: endTime, onTimeSelected: (picked) => setState(() => endTime = picked)),
                  child: Row(children: [const Icon(Icons.access_time, color: Colors.white), const SizedBox(width: 8), Text(endStr, style: const TextStyle(color: Colors.white))]),
                ),
              ],
            ),
            if (showTimeOrderError)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('시작 시간은 종료 시간보다 빨라야 해요.', style: TextStyle(color: Colors.red.shade300, fontSize: 14)),
              ),
            const SizedBox(height: 30),
            const Align(alignment: Alignment.centerLeft, child: Text('목표', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white))),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: isEditingGoal
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(controller: goalController, style: const TextStyle(fontSize: 16, color: Colors.white), decoration: const InputDecoration(border: InputBorder.none)),
                      const Divider(color: Colors.grey),
                    ],
                  )
                      : GestureDetector(
                    onTap: () => setState(() => isEditingGoal = true),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goalController.text, style: const TextStyle(fontSize: 16, color: Colors.white)),
                        Divider(color: Colors.grey.shade300),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isRecommend) ...[
              const Align(alignment: Alignment.centerLeft, child: Text('루틴 별점', style: TextStyle(color: Colors.white))),
              const SizedBox(height: 10),
              RatingBar.builder(
                initialRating: score,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 2),
                itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (newRating) => setState(() => score = newRating),
              ),
              const SizedBox(height: 30),
            ],
            const Align(alignment: Alignment.centerLeft, child: Text('기분', style: TextStyle(color: Colors.white))),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) {
                return Column(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => selectedMood = index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: selectedMood == index ? Colors.blue : Colors.transparent, width: 2),
                        ),
                        child: Text(moodEmojis[index], style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(moodLabels[index], style: const TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                );
              }),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      showTimeOrderError = !_isStartTimeBeforeEndTime(startTime, endTime);
                    });
                    if (!showTimeOrderError) _saveRoutine();
                  },
                  child: const Text('저장하기', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: _deleteRoutine,
                  child: const Text('루틴 삭제하기', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 30),
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
