import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FunctionTriggerTestPage(),
    );
  }
}

class FunctionTriggerTestPage extends StatefulWidget {
  const FunctionTriggerTestPage({super.key});

  @override
  State<FunctionTriggerTestPage> createState() => _FunctionTriggerTestPageState();
}

class _FunctionTriggerTestPageState extends State<FunctionTriggerTestPage> {
  String? _fcmToken;
  final functionUrl = 'https://us-central1-routine-log-app.cloudfunctions.net/notifyTestPush';


  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    final token = await FirebaseMessaging.instance.getToken();
    setState(() {
      _fcmToken = token;
    });
    print(token);
    FirebaseMessaging.onMessage.listen((message) {
      print('${message.notification?.title}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('알림: ${message.notification?.title ?? '알림'}')),
      );
    });
  }

  Future<void> _callFunction() async {
    if (_fcmToken == null) return;

    final response = await http.post(
      Uri.parse(functionUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': _fcmToken}),
    );

    print('응답 코드: ${response.statusCode}');
    print('응답 내용: ${response.body}');

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Functions 호출 성공')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FCM 테스트')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _callFunction,
              child: const Text('FCM 테스트 알림 보내기'),
            ),
            const SizedBox(height: 20),
            Text('FCM Token:\n${_fcmToken ?? "토큰 불러오는 중..."}', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
