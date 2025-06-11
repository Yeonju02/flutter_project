import 'package:flutter/material.dart';

class RoutineBox extends StatelessWidget {
  final String time;
  final String title;
  final bool hasAlarm;
  final bool isChecked;
  final VoidCallback onToggle;

  const RoutineBox({
    super.key,
    required this.time,
    required this.title,
    required this.isChecked,
    required this.hasAlarm,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final Color selectedColor =  Color(0xFF92BBE2);

    return AnimatedContainer(
      duration:  Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin:  EdgeInsets.only(bottom: 12),
      padding:  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isChecked ? selectedColor : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            time,
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
            ),
          ),
          if (hasAlarm)
            Icon(Icons.alarm, size: 18, color: isChecked ? Colors.white70 : Colors.grey),
          SizedBox(width: 8),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: AnimatedSwitcher(
                duration:  Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: isChecked
                    ? Icon(Icons.check, key:  ValueKey('checked'), size: 18, color: selectedColor)
                    : Icon(Icons.circle_outlined, key:  ValueKey('unchecked'), size: 18, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
