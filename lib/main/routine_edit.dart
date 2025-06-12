import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RoutineEditDialog extends StatefulWidget {
  final Map<String, dynamic> routineData;
  final String userDocId;
  final String routineDocId;

  const RoutineEditDialog({
    super.key,
    required this.routineData,
    required this.userDocId,
    required this.routineDocId,
  });

  @override
  State<RoutineEditDialog> createState() => _RoutineEditDialogState();
}

class _RoutineEditDialogState extends State<RoutineEditDialog> {
  late TextEditingController titleController;
  late TextEditingController goalController;
  late String date;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  int selectedMood = 2;
  double score = 0.0;

  bool isEditingTitle = false;
  bool isEditingGoal = false;
  bool showTimeError = false;

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
      if (match == null) throw FormatException('시간 형식 아님: $timeStr');
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
                if (selectedHour >= 12) {
                  setState(() => showTimeError = true);
                } else {
                  setState(() {
                    showTimeError = false;
                    onTimeSelected(TimeOfDay(
                      hour: selectedHour,
                      minute: selectedDuration.inMinutes % 60,
                    ));
                  });
                }
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
      // 사용자 루틴 업데이트
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

      Navigator.pop(context);
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
      Navigator.pop(context);
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 제목
          Row(
            children: [
              Icon(Icons.circle_outlined, size: 20),
              SizedBox(width: 16),
              Expanded(
                child: isEditingTitle
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      enabled: !isRecommend,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(border: InputBorder.none),
                    ),
                    Divider(color: Colors.grey),
                  ],
                )
                    : GestureDetector(
                  onTap: () {
                    if (!isRecommend) {
                      setState(() => isEditingTitle = true);
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleController.text,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isRecommend ? Colors.grey : Colors.black,
                        ),
                      ),
                      Divider(color: Colors.grey.shade300),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // 날짜 & 시간
          Row(children: [Icon(Icons.calendar_today), SizedBox(width: 8), Text(date)]),
          SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showTimePicker(
                  outerContext: context,
                  initialTime: startTime,
                  onTimeSelected: (picked) => setState(() => startTime = picked),
                ),
                child: Row(children: [Icon(Icons.access_time), SizedBox(width: 8), Text(startStr)]),
              ),
              SizedBox(width: 12),
              Text('~'),
              SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showTimePicker(
                  outerContext: context,
                  initialTime: endTime,
                  onTimeSelected: (picked) => setState(() => endTime = picked),
                ),
                child: Row(children: [Icon(Icons.access_time), SizedBox(width: 8), Text(endStr)]),
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
          SizedBox(height: 30),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('목표',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          SizedBox(height: 10),
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
                      style: TextStyle(fontSize: 16),
                      decoration: InputDecoration(border: InputBorder.none),
                    ),
                    Divider(color: Colors.grey),
                  ],
                )
                    : GestureDetector(
                  onTap: () => setState(() => isEditingGoal = true),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goalController.text, style: TextStyle(fontSize: 16)),
                      Divider(color: Colors.grey.shade300),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // 별점
          if (isRecommend) ...[
            Align(alignment: Alignment.centerLeft, child: Text('루틴 별점')),
            SizedBox(height: 10),
            RatingBar.builder(
              initialRating: score,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: EdgeInsets.symmetric(horizontal: 2),
              itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (newRating) => setState(() => score = newRating),
            ),
            SizedBox(height: 30),
          ],

          // 기분
          Align(alignment: Alignment.centerLeft, child: Text('기분')),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (index) {
              return Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => selectedMood = index),
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedMood == index ? Colors.blue : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(moodEmojis[index], style: TextStyle(fontSize: 28)),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(moodLabels[index], style: TextStyle(fontSize: 12)),
                ],
              );
            }),
          ),
          SizedBox(height: 40),

          // 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade300,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _saveRoutine,
                child: Text('저장하기'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _deleteRoutine,
                child: Text('루틴 삭제하기'),
              ),
            ],
          ),
          SizedBox(height: 30),
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
