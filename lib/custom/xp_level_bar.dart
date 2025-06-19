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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('루틴 XP   $xp', style: const TextStyle(fontSize: 16)),
            Text('Lv.$level   ', style: const TextStyle(color: Colors.lightBlue)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
          ),
        ),
      ],
    );
  }
}