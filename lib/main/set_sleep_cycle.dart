import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../custom/dialogs/cycle_explain_dialog.dart';

class SetSleepCyclePage extends StatefulWidget {
  const SetSleepCyclePage({super.key});

  @override
  State<SetSleepCyclePage> createState() => _SetSleepCyclePageState();
}

class _SetSleepCyclePageState extends State<SetSleepCyclePage> {
  TimeOfDay wakeUpTime = const TimeOfDay(hour: 7, minute: 30);

  DateTime get wakeUpDateTime {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, wakeUpTime.hour, wakeUpTime.minute);
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: wakeUpTime,
    );
    if (picked != null) {
      setState(() {
        wakeUpTime = picked;
      });
    }
  }

  List<Widget> _buildSleepOptions(BuildContext context, DateTime wakeTime) {
    const cycleMinutes = 90;
    List<Widget> options = [];

    for (int i = 6; i >= 1; i--) {
      final totalSleepMinutes = cycleMinutes * i;
      final sleepTime = wakeTime.subtract(Duration(minutes: totalSleepMinutes));
      final sleepHour = totalSleepMinutes ~/ 60;
      final sleepMin = totalSleepMinutes % 60;

      options.add(
        GestureDetector(
          onTap: () {
            Navigator.pop(context, {
              'sleepTime': sleepTime,
              'wakeTime': wakeTime,
              'totalSleepMinutes': totalSleepMinutes,
              'cycleCount': i,
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF222C45),
              borderRadius: BorderRadius.circular(12),
              border: i == 6 ? Border.all(color: Colors.white, width: 1.2) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.jm().format(sleepTime),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$i cycle',
                        style: const TextStyle(fontSize: 16, color: Colors.white)),
                    Text('$sleepHour hr ${sleepMin.toString().padLeft(2, '0')} min',
                        style: const TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return options;
  }

  @override
  Widget build(BuildContext context) {
    final wakeClockStr = DateFormat('hh : mm a').format(wakeUpDateTime);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF101728), Color(0xFF182333)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
              const Text(
                '수면 사이클 설정',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '자세한 설명이 필요하신가요?',
                    style: TextStyle(fontSize: 14, color: Colors.white60),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const CycleExplainDialog(),
                      );
                    },
                    child: const Icon(Icons.help_outline, color: Colors.white60, size: 18),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickTime,
                child: Text(
                  wakeClockStr,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '기상 시간에 따라 취침 시간을 추천해드려요',
                style: TextStyle(fontSize: 14, color: Colors.white60),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _buildSleepOptions(context, wakeUpDateTime),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
