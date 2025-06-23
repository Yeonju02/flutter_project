import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/lib/route_observer.dart';

class XPLevelBar extends StatefulWidget {
  const XPLevelBar({super.key});

  @override
  State<XPLevelBar> createState() => _XPLevelBarState();
}

class _XPLevelBarState extends State<XPLevelBar> with RouteAware {
  int xp = 0;
  int level = 0;
  bool isLoading = true;

  final List<Color> levelColors = [
    Color(0xFFFF0000), Color(0xFFFF2600), Color(0xFFFF4D00), Color(0xFFFF7300), Color(0xFFFF7F00),
    Color(0xFFFF9933), Color(0xFFFFA533), Color(0xFFFFB233), Color(0xFFDAA520), Color(0xFFB8860B),
    Color(0xFF8B8000), Color(0xFF808000), Color(0xFF6B8E23), Color(0xFF556B2F), Color(0xFF228B22),
    Color(0xFF006400), Color(0xFF006A4E), Color(0xFF008000), Color(0xFF008B8B), Color(0xFF0099CC),
    Color(0xFF007BA7), Color(0xFF0066CC), Color(0xFF0033CC), Color(0xFF0000FF), Color(0xFF1B0091),
    Color(0xFF3400A2), Color(0xFF4B00B3), Color(0xFF6100C4), Color(0xFF7600D5), Color(0xFF8B00FF),
  ];

  @override
  void initState() {
    super.initState();
    _loadXPLevel();
  }

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
    _loadXPLevel();
  }

  Future<void> _loadXPLevel() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      if (!mounted) return;
      setState(() => isLoading = false);
      return;
    }

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      if (!mounted) return;
      setState(() {
        xp = data['xp'] ?? 0;
        level = data['level'] ?? 0;
        isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const SizedBox(height: 20);

    double progress = (xp % 100) / 100.0;
    Color progressColor = levelColors[level.clamp(0, levelColors.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('루틴 XP   $xp', style: TextStyle(color : progressColor, fontSize: 16)),
            Text('Lv.$level   ', style: TextStyle(color: progressColor, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }
}
