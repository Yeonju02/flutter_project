import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../custom/custom_blue_button.dart';

class NewRoutineSheet extends StatefulWidget {
  final DateTime selectedDate;

  const NewRoutineSheet({super.key, required this.selectedDate});

  @override
  State<NewRoutineSheet> createState() => _NewRoutineSheetState();
}

class _NewRoutineSheetState extends State<NewRoutineSheet> {
  bool isEditingTitle = false;
  bool isEditingGoal = false;

  final titleController = TextEditingController();
  final goalController = TextEditingController();
  TimeOfDay selectedTime = TimeOfDay.now();

  void _showCupertinoTimePicker() {
    Duration initialDuration = Duration(
      hours: selectedTime.hour,
      minutes: selectedTime.minute,
    );

    showCupertinoDialog(
      context: context,
      builder: (_) {
        return CupertinoAlertDialog(
          content: SizedBox(
            height: 200,
            child: CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.hm,
              initialTimerDuration: initialDuration,
              onTimerDurationChanged: (Duration newDuration) {
                setState(() {
                  selectedTime = TimeOfDay(
                    hour: newDuration.inHours,
                    minute: newDuration.inMinutes % 60,
                  );
                });
              },
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child:  Text('확인'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final timeStr = selectedTime.format(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 바
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
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
                        color: titleController.text.isEmpty ? Colors.grey : Colors.black87,
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

          SizedBox(height: 30),

          // 시간 및 날짜
          Align(
            alignment: Alignment.centerLeft,
            child: Text('시간 및 날짜', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 20),
              SizedBox(width: 12),
              Text(dateStr, style: TextStyle(fontSize: 16)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: _showCupertinoTimePicker,
                child: Icon(Icons.access_time, size: 20),
              ),
              SizedBox(width: 12),
              Text(timeStr, style: TextStyle(fontSize: 16)),
            ],
          ),

          SizedBox(height: 30),
          Divider(thickness: 1),
          SizedBox(height: 30),

          Align(
            alignment: Alignment.centerLeft,
            child: Text('목표', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          SizedBox(height: 10),

          // 목표 입력칸
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
                      decoration: InputDecoration(
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
                        color: goalController.text.isEmpty ? Colors.grey : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, size: 18, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    isEditingGoal = true;
                  });
                },
              ),
            ],
          ),

          SizedBox(height: 50),
          CustomBlueButton(
            text: '루틴 추가하기',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          SizedBox(height: 100),
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
