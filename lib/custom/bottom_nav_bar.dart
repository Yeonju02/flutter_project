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
      height: 90, // 전체 높이 증가
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 배경 바
          Positioned(
            bottom: 10,
            left: 20,
            right: 20,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (index) {
                  if (index == 2) return const SizedBox(width: 60); // 홈 자리 비워두기
                  return IconButton(
                    icon: Icon(
                      _iconData(index),
                      color: currentIndex == index ? Colors.black : Colors.grey,
                    ),
                    onPressed: () => onTap?.call(index),
                  );
                }),
              ),
            ),
          ),

          // 홈 버튼
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () => onTap?.call(2),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.home,
                  size: 30,
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

