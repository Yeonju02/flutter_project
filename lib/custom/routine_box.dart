import 'package:flutter/material.dart';

class RoutineBox extends StatelessWidget {
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

  const RoutineBox({
    super.key,
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

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Colors.grey.shade100;
    final Color blueColor = Color(0xFF92BBE2);
    final Color redColor = Color(0xFFFFCCCC);

    final int xpEarned = routineData['xpEarned'] ?? 0;

    final bgColor = isChecked
        ? (xpEarned > 0 ? blueColor : redColor)
        : baseColor;

    final textColor = isChecked ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onEdit,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              '$startTime ~ $endTime',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: isChecked ? null : onToggle,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: isChecked
                      ? (xpEarned > 0
                      ? Icon(Icons.check, key: ValueKey('check'), size: 18, color: blueColor)
                      : Icon(Icons.close, key: ValueKey('close'), size: 18, color: Colors.red))
                      : Icon(Icons.circle_outlined, key: ValueKey('none'), size: 18, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
