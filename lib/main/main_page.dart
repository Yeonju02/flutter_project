import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../board/board_main_screen.dart';
import '../custom/routine_calendar.dart';
import '../custom/xp_level_bar.dart';
import '../custom/bottom_nav_bar.dart';
import '../notification/notification_screen.dart';
import '../shop/shop_main.dart';
import '../mypage/myPage_main.dart';
import 'routine_detail.dart';


final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with RouteAware {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Key _calendarRefreshKey = UniqueKey();
  Key _xpBarKey = UniqueKey(); // 경험치바 새로고침용

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {
      _calendarRefreshKey = UniqueKey();
      _xpBarKey = UniqueKey();
    });
  }

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
    return MaterialApp(
      navigatorObservers: [routeObserver],
      home: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 90),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: XPLevelBar(key: _xpBarKey),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _goToPrevMonth,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_focusedDay.year}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_focusedDay.month.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _goToNextMonth,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Divider(thickness: 1),
                    Expanded(
                      child: RoutineCalendar(
                        key: _calendarRefreshKey,
                        focusedDay: _focusedDay,
                        selectedDay: _selectedDay,
                        onDaySelected: (selectedDay, focusedDay) async {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoutineDetailPage(date: selectedDay),
                            ),
                          );

                          if (result == true) {
                            setState(() {
                              _calendarRefreshKey = UniqueKey();
                              _xpBarKey = UniqueKey();
                            });
                          }
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
              bottom: 30,
              child: BottomNavBar(
                currentIndex: 2,
                onTap: (index) {
                  if (index == 0) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopMainPage()));
                  } else if (index == 1) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BoardMainScreen()));
                  } else if (index == 3) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                  } else if (index == 4) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MyPageMain()));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
