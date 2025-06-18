import 'dart:async';
import 'dart:collection';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class GlobalTimerManager {
  static final GlobalTimerManager _instance = GlobalTimerManager._internal();
  static GlobalTimerManager get instance => _instance;

  GlobalTimerManager._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, int> _durations = {};
  final Map<String, Timer> _timers = {};

  late FlutterLocalNotificationsPlugin _notifications;

  // 초기화
  Future<void> initialize(FlutterLocalNotificationsPlugin notifications) async {
    _notifications = notifications;
  }

  // 타이머 시작
  void start(String id, int durationSeconds, {required String title}) {
    _startTimes[id] = DateTime.now();
    _durations[id] = durationSeconds;

    _timers[id]?.cancel();

    _timers[id] = Timer(Duration(seconds: durationSeconds), () {
      _startTimes.remove(id);
      _durations.remove(id);
      _timers.remove(id);

      showTimerFinishedNotification(title);
    });
  }

  void stop(String id) {
    _startTimes.remove(id);
    _durations.remove(id);
    _timers[id]?.cancel();
    _timers.remove(id);
  }

  bool isRunning(String id) {
    return _startTimes.containsKey(id) && _durations.containsKey(id) && getRemainingSeconds(id) > 0;
  }

  int getRemainingSeconds(String id) {
    if (!_startTimes.containsKey(id) || !_durations.containsKey(id)) return 0;
    final startedAt = _startTimes[id]!;
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    final duration = _durations[id]!;
    return (duration - elapsed).clamp(0, duration);
  }

  int getOriginalDuration(String id) => _durations[id] ?? 0;

  Future<void> showTimerFinishedNotification(String title) async {
    const androidDetails = AndroidNotificationDetails(
      'timer_channel',
      '루틴 타이머 알림',
      channelDescription: '타이머 완료 시 알림',
      importance: Importance.max,
      priority: Priority.high,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      '루틴 알림',
      '$title 시간이 다 되었어요!',
      platformDetails,
    );
  }
}
