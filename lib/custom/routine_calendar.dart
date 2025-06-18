import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoutineCalendar extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;

  RoutineCalendar({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  State<RoutineCalendar> createState() => _RoutineCalendarState();
}

class _RoutineCalendarState extends State<RoutineCalendar> {
  Map<DateTime, List<String>> _events = {};
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.focusedDay;
    _selectedDay = widget.selectedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;

    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) return;

    final userDocId = userQuery.docs.first.id;

    final routineSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userDocId)
        .collection('routineLogs')
        .get();

    Map<DateTime, List<String>> eventMap = {};

    for (var doc in routineSnapshot.docs) {
      final data = doc.data();
      final dateStr = data['date'];
      final title = data['title'];

      if (dateStr != null && title != null) {
        final date = DateTime.parse(dateStr);
        final dateKey = DateTime.utc(date.year, date.month, date.day);
        eventMap.putIfAbsent(dateKey, () => []).add(title);
      }
    }

    setState(() {
      _events = eventMap;
      _selectedDay ??= _focusedDay; // 초기 진입 시 루틴 보이게
    });
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _handleDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    widget.onDaySelected(selectedDay, focusedDay);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          headerVisible: false,
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: _handleDaySelected,
          eventLoader: _getEventsForDay,
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: Colors.lightBlue,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isNotEmpty) {
                return Positioned(
                  bottom: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.lightBlue,
                    ),
                  ),
                );
              }
              return null;
            },
          ),
        ),
        Divider(thickness: 2, color: Colors.grey),
        SizedBox(height: 8),
        ..._getEventsForDay(_selectedDay ?? _focusedDay).map(
              (event) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 10, color: Colors.lightBlue),
                SizedBox(width: 14),
                Text(
                  event,
                  style: TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
