import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class RoutineCalendar extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;

  const RoutineCalendar({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  State<RoutineCalendar> createState() => _RoutineCalendarState();
}

class _RoutineCalendarState extends State<RoutineCalendar> {
  Map<DateTime, List<String>> _events = {
    DateTime.utc(2025, 6, 3): ['7:30 기상하기'],
    DateTime.utc(2025, 6, 5): ['7:30 기상하기', '8:30 10분 스트레칭 하기'],
    DateTime.utc(2025, 6, 10): ['7:30 기상하기', '8:30 10분 스트레칭 하기', '8:40 밥먹기'],
  };

  List<String> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          headerVisible: false,
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: widget.focusedDay,
          selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
          onDaySelected: widget.onDaySelected,
          eventLoader: _getEventsForDay,
          calendarStyle: const CalendarStyle(
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
                    decoration: const BoxDecoration(
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
        Divider(thickness: 2,color: Colors.grey,),
        SizedBox(height: 8),
        ..._getEventsForDay(widget.selectedDay ?? widget.focusedDay).map(
              (event) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 10, color: Colors.lightBlue),
                SizedBox(width: 14),
                Text(
                  event,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

      ],
    );
  }
}
