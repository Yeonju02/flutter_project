import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routinelogapp/custom/night_date_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class NightDateSlider extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  const NightDateSlider({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<NightDateSlider> createState() => NightDateSliderState();
}

class NightDateSliderState extends State<NightDateSlider> {
  late DateTime selectedDate;
  late List<DateTime> dates;
  final ScrollController _scrollController = ScrollController();
  Map<String, bool> nightRoutineDates = {};

  Future<void> refresh() async {
    await loadNightRoutineDates();
  }

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;

    // ±30일 범위 날짜 생성
    dates = List.generate(
      61,
          (i) => widget.initialDate.add(Duration(days: i - 30)),
    );

    loadNightRoutineDates();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      int index = dates.indexWhere((d) =>
      d.year == selectedDate.year &&
          d.month == selectedDate.month &&
          d.day == selectedDate.day);
      if (index != -1) {
        _scrollController.jumpTo(
          (index * 72) - (MediaQuery.of(context).size.width / 2) + 36,
        );
      }
    });
  }

  Future<void> loadNightRoutineDates() async {
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

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userDocId)
        .collection('routineLogs')
        .where('routineType', isEqualTo: 'night')
        .get();

    final result = <String, bool>{};
    for (var doc in snapshot.docs) {
      final dateStr = doc['date'];
      result[dateStr] = true;
    }

    setState(() {
      nightRoutineDates = result;
    });
  }

  bool hasEvent(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    return nightRoutineDates[key] == true;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          return NightDateItem(
            date: date,
            isSelected: isSelected,
            hasEvent: hasEvent(date),
            onTap: () {
              setState(() {
                selectedDate = date;
              });
              widget.onDateSelected(date);
            },
          );
        },
      ),
    );
  }
}
