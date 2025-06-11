import 'package:flutter/material.dart';
import '../custom/date_item.dart';
import 'package:intl/intl.dart';

class DateSlider extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  const DateSlider({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<DateSlider> createState() => _DateSliderState();
}

class _DateSliderState extends State<DateSlider> {
  late DateTime selectedDate;
  late List<DateTime> dates;
  final ScrollController _scrollController = ScrollController();

  final Set<String> eventDates = {
    '2025-06-02',
    '2025-06-05',
  };

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;

    // ±30일 범위 날짜 생성
    dates = List.generate(
      61,
          (i) => widget.initialDate.add(Duration(days: i - 30)),
    );

    // 처음 빌드 완료 후 자동 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int index = dates.indexWhere((d) =>
      d.year == selectedDate.year &&
          d.month == selectedDate.month &&
          d.day == selectedDate.day);
      if (index != -1) {
        // 한 아이템의 너비 약 72 (58 + margin 6*2), 가운데 맞추기
        _scrollController.jumpTo((index * 72) - (MediaQuery.of(context).size.width / 2) + 36);
      }
    });
  }

  bool hasEvent(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    return eventDates.contains(key);
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

          return DateItem(
            date: date,
            isSelected: isSelected,
            hasEvent: hasEvent(date),
            onTap: () {
              setState(() {
                selectedDate = date;
              });
              widget.onDateSelected(date);
              // 이후에는 스크롤 위치 고정 (자동 이동 없음)
            },
          );
        },
      ),
    );
  }
}
