import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 하단 배경
          Positioned(
            bottom: 0,
            left: 16,
            right: 16,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (index) {
                  if (index == 2) return const SizedBox(width: 48); // 홈 아이콘 공간 비우기
                  return IconButton(
                    icon: Icon(_iconData(index),
                        color: currentIndex == index ? Colors.black : Colors.grey),
                    onPressed: () => onTap?.call(index),
                  );
                }),
              ),
            ),
          ),

          // 홈 아이콘
          Positioned(
            bottom: 15,
            child: GestureDetector(
              onTap: () => onTap?.call(2),
              child: Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Icon(
                  Icons.home,
                  color: currentIndex == 2 ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconData(int index) {
    switch (index) {
      case 0:
        return Icons.attach_money;
      case 1:
        return Icons.check_box;
      case 3:
        return Icons.notifications_none;
      case 4:
        return Icons.person_outline;
      default:
        return Icons.circle;
    }
  }
}
