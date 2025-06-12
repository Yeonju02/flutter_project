import 'package:flutter/material.dart';
import '../board/board_main_screen.dart';
import '../custom/routine_calendar.dart';
import '../custom/xp_level_bar.dart';
import '../custom/bottom_nav_bar.dart';
import '../notification/notification_screen.dart';
import '../shop/shop_main.dart';
import '../mypage/myPage_main.dart';
import 'routine_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  DateTime _focusedDay = DateTime(2025, 6, 5);
  DateTime? _selectedDay;

  //final prefs = await SharedPreferences.getInstance();  위쪽 import랑 이거 두 줄 쓰면 SharedPreference로 저장된 로그인 id 불러올 수 있음
  //final userId = prefs.getString('userId');

  void _goToPrevMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: XPLevelBar(),
                  ),
                  SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left),
                          onPressed: _goToPrevMonth,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_focusedDay.year}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_focusedDay.month.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right),
                          onPressed: _goToNextMonth,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  Divider(thickness: 1),
                  Expanded(
                    child: RoutineCalendar(
                      focusedDay: _focusedDay,
                      selectedDay: _selectedDay,
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RoutineDetailPage(date: selectedDay),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 30,  // 이거 안하면 너무 아래에 딱 붙는듯
            child: BottomNavBar(
              currentIndex: 2,
              onTap: (index) {
                if (index == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ShopMainPage()),
                  );
                }

                if (index == 1) {
                  Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const BoardMainScreen()),
                  );
                }

                if (index == 3) {
                  Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const NotificationScreen()),
                  );
                }

                if (index == 4) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyPageMain()),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}