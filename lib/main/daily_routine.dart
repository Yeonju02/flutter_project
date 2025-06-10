import 'package:flutter/material.dart';
import '../custom/routine_box.dart';

class DailyRoutine extends StatelessWidget {
  const DailyRoutine({super.key});

  @override
  Widget build(BuildContext context) {
    final routineList = [
      {'time': '07:00', 'title': '기상하기', 'hasAlarm': false},
      {'time': '08:30', 'title': '10분 스트레칭 하기', 'hasAlarm': false},
      {'time': '08:30', 'title': '10분 스트레칭 하기', 'hasAlarm': true},
      {'time': '08:30', 'title': '10분 스트레칭 하기', 'hasAlarm': false},
    ];

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: 24),
      itemCount: routineList.length,
      itemBuilder: (context, index) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey, // 항상 회색
                  ),
                ),
                if (index != routineList.length - 1)
                  Container(
                    width: 2,
                    height: 60,
                    color: Colors.grey.shade300,
                  ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: RoutineBox(
                time: routineList[index]['time'] as String,
                title: routineList[index]['title'] as String,
                hasAlarm: routineList[index]['hasAlarm'] as bool,

              ),
            ),
          ],
        );
      },
    );
  }
}
