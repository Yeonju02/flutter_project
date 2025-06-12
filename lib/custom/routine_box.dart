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
    final Color selectedColor = Color(0xFF92BBE2);

    return GestureDetector(
      onTap: onEdit,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isChecked ? selectedColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              '$startTime ~ $endTime',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isChecked ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isChecked ? Colors.white : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onToggle,
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
                      ? Icon(Icons.check, key: const ValueKey('checked'), size: 18, color: selectedColor)
                      : const Icon(Icons.circle_outlined, key: ValueKey('unchecked'), size: 18, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
