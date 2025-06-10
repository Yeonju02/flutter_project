import 'package:flutter/material.dart';

class RoutineBox extends StatefulWidget {
  final String time;
  final String title;
  final bool hasAlarm;

  const RoutineBox({
    super.key,
    required this.time,
    required this.title,
    this.hasAlarm = false,
  });

  @override
  State<RoutineBox> createState() => _RoutineBoxState();
}

class _RoutineBoxState extends State<RoutineBox> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = const Color(0xFF92BBE2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isChecked ? selectedColor : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            widget.time,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isChecked ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 16,
                color: isChecked ? Colors.white : Colors.black,
              ),
            ),
          ),
          if (widget.hasAlarm)
            Icon(Icons.alarm, size: 18, color: isChecked ? Colors.white70 : Colors.grey),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                isChecked = !isChecked;
              });
            },
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(
                isChecked ? Icons.check : Icons.circle_outlined,
                size: 18,
                color: isChecked ? selectedColor : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
