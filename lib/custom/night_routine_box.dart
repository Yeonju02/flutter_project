import 'package:flutter/material.dart';
import 'dialogs/timer_dialog.dart';
import '../../utils/class/global_timer_manager.dart';

class NightRoutineBox extends StatelessWidget {
  final String routineId;
  final String startTime;
  final String endTime;
  final String title;
  final String goal;
  final String routineType;
  final String routineCategory;
  final bool isChecked;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final Map<String, dynamic> routineData;

  const NightRoutineBox({
    super.key,
    required this.routineId,
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.goal,
    required this.routineType,
    required this.routineCategory,
    required this.isChecked,
    required this.onToggle,
    required this.onEdit,
    required this.routineData,
  });

  int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

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

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Color(0xFFCCCCCC);
    final Color blueColor = const Color(0xFFD5BA51);
    final Color redColor = const Color(0xFF737373);

    final int xpEarned = routineData['xpEarned'] ?? 0;

    final bgColor = isChecked
        ? (xpEarned > 0 ? blueColor : redColor)
        : baseColor;

    final textColor = isChecked ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onEdit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Text(
              '$startTime  $title',
              style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.bold
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                final start = _parseTime(startTime);
                final end = _parseTime(endTime);
                final durationSeconds = (_toMinutes(end) - _toMinutes(start)) * 60;

                final isRunning = GlobalTimerManager.instance.isRunning(routineId);
                final remainingSeconds = GlobalTimerManager.instance.getRemainingSeconds(routineId);
                final isTimerInitialized = GlobalTimerManager.instance.getOriginalDuration(routineId) > 0;

                showTimerDialog(
                  context,
                  routineId,
                  title: title,
                  startTime: startTime,
                  endTime: endTime,
                  initialSeconds: isRunning || isTimerInitialized ? remainingSeconds : durationSeconds,
                  isInitiallyRunning: isRunning,
                );
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.timer, size: 18, color: Colors.black54),
              ),
            ),

            GestureDetector(
              onTap: isChecked ? null : onToggle,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: isChecked
                      ? (xpEarned > 0
                      ? Icon(Icons.check, key: const ValueKey('check'), size: 18, color: blueColor)
                      : Icon(Icons.close, key: const ValueKey('close'), size: 18, color: Color(0xFF737373)))
                      : const Icon(Icons.circle_outlined, key: ValueKey('none'), size: 18, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
