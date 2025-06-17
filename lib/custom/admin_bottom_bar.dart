import 'package:flutter/material.dart';

class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/user.png')),
          label: '회원',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/board.png')),
          label: '대시보드',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/post.png')),
          label: '게시판',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/shop.png')),
          label: '상품',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/review.png')),
          label: '리뷰',
        ),
      ],
      onTap: onTap,
    );
  }
}
