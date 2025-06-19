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
      selectedItemColor: null, // 이미지로 표현하므로 컬러 X
      unselectedItemColor: null,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: [
        BottomNavigationBarItem(
          icon: Image.asset('assets/user.png', width: 24, height: 24),
          activeIcon: Image.asset('assets/user_selected.png', width: 24, height: 24),
          label: '회원',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/board.png', width: 24, height: 24),
          activeIcon: Image.asset('assets/board_selected.png', width: 24, height: 24),
          label: '대시보드',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/post.png', width: 24, height: 24),
          activeIcon: Image.asset('assets/post_selected.png', width: 24, height: 24),
          label: '게시판',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/shop.png', width: 24, height: 24),
          activeIcon: Image.asset('assets/shop_selected.png', width: 24, height: 24),
          label: '상품',
        ),
      ],
      onTap: onTap,
    );
  }
}
