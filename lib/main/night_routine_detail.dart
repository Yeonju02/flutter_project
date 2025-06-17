import 'package:flutter/material.dart';
import 'routine_detail.dart';
import '../custom/night_date_slider.dart';
import 'daily_routine.dart';
import '../custom/custom_gery_button.dart';
import 'new_routine.dart';
import 'package:flutter_switch/flutter_switch.dart';

class NightRoutineDetailPage extends StatefulWidget {
  final DateTime date;

  const NightRoutineDetailPage({super.key, required this.date});

  @override
  State<NightRoutineDetailPage> createState() => _NightRoutineDetailPageState();
}

class _NightRoutineDetailPageState extends State<NightRoutineDetailPage>
    with TickerProviderStateMixin {
  late DateTime selectedDate;
  final GlobalKey<NightDateSliderState> sliderKey = GlobalKey();

  late final AnimationController _controller;
  late final Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.date;

    // 달 슬라이드 애니메이션 설정
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: const Offset(0, 1), // 아래에서 시작
      end: Offset.zero,          // 원래 위치로 이동
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // 페이지 진입 후 살짝 딜레이 주고 애니메이션 실행
    Future.delayed(const Duration(milliseconds: 200), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1C33),
              Color(0xFF3D4166),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context, true),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${selectedDate.year}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          selectedDate.month.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: FlutterSwitch(
                        width: 60,
                        height: 30,
                        toggleSize: 25,
                        value: true,
                        activeColor: Colors.indigo,
                        inactiveColor: Colors.grey.shade200,
                        toggleColor: Colors.white,
                        activeIcon: Image.asset('assets/moon.png', width: 20, height: 20),
                        inactiveIcon: Image.asset('assets/sun.png', width: 20, height: 20),
                        onToggle: (val) {
                          if (!val) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RoutineDetailPage(date: selectedDate),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 달 이미지 애니메이션
              ClipRect(
                child: SizedBox(
                  height: 120,
                  child: SlideTransition(
                    position: _animation,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        //Image.asset(
                        //  'assets/moon_background.png',
                        //  width: 250,
                        //  fit: BoxFit.cover,
                        //),
                        Image.asset(
                          'assets/rising_moon.PNG',
                          width: 250,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
              ),


              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Divider(
                  thickness: 1.2,
                  color: Color(0xFFD9D9D9),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),

              NightDateSlider(
                key: sliderKey,
                initialDate: selectedDate,
                onDateSelected: (newDate) {
                  setState(() {
                    selectedDate = newDate;
                  });
                },
              ),

              const SizedBox(height: 10),
              const Divider(thickness: 1.2, color: Colors.white),
              const SizedBox(height: 20),

              Expanded(
                child: DailyRoutine(
                  key: UniqueKey(),
                  selectedDate: selectedDate,
                  routineType: 'night',
                ),
              ),

              const Divider(thickness: 1.2, color: Colors.white),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: CustomGeryButton(
                  text: '루틴 추가하기',
                  onPressed: () async {
                    final result = await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (context) => Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: NewRoutineSheet(selectedDate: selectedDate),
                      ),
                    );

                    if (result == true) {
                      setState(() {});
                      sliderKey.currentState?.refresh();
                    }
                  },
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
