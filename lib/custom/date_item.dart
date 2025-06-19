import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateItem extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool hasEvent;
  final VoidCallback onTap;

  const DateItem({
    super.key,
    required this.date,
    required this.isSelected,
    required this.hasEvent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('d').format(date),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  DateFormat('E', 'en_US').format(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            if (!isSelected && hasEvent)
              const Positioned(
                top: 6,
                right: 6,
                child: CircleAvatar(
                  radius: 5,
                  backgroundColor: Colors.lightBlue,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
