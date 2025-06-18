// timer_dialog.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/class/global_timer_manager.dart';

void showTimerDialog(
    BuildContext context,
    String routineId,
    {
      required String title,
      required String startTime,
      required String endTime,
      required int initialSeconds,
      required bool isInitiallyRunning,
    }
    ) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _TimerDialog(
      routineId: routineId,
      title: title,
      startTime: startTime,
      endTime: endTime,
      initialSeconds: initialSeconds,
      isInitiallyRunning: isInitiallyRunning,
    ),
  );
}

class _TimerDialog extends StatefulWidget {
  final String routineId;
  final String title;
  final String startTime;
  final String endTime;
  final int initialSeconds;
  final bool isInitiallyRunning;

  const _TimerDialog({
    required this.routineId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.initialSeconds,
    required this.isInitiallyRunning,
  });

  @override
  State<_TimerDialog> createState() => _TimerDialogState();
}

class _TimerDialogState extends State<_TimerDialog> {
  late int remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    remainingSeconds = widget.initialSeconds;
    if (widget.isInitiallyRunning) {
      _startTimer();
    }
  }

  void _startTimer() {
    GlobalTimerManager.instance.start(widget.routineId, remainingSeconds, title : widget.title);
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        remainingSeconds = GlobalTimerManager.instance.getRemainingSeconds(widget.routineId);
        if (remainingSeconds <= 0) {
          timer.cancel();
          _showFinishNotification();
          Navigator.of(context).pop();
        }
      });
    });
  }

  void _stopTimer() {
    GlobalTimerManager.instance.stop(widget.routineId);
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showFinishNotification() {
    print("🔔 ${widget.title} 시간이 다 되었어요!");
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Text(widget.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text('${widget.startTime} ~ ${widget.endTime}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Text(
                  _formatTime(remainingSeconds),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF92BBE2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: _startTimer,
                      child: const Text("시작하기", style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCCCC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: _stopTimer,
                      child: const Text("중지하기", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.close, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}