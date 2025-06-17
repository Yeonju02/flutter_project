import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FindAccountPage extends StatefulWidget {
  const FindAccountPage({super.key});

  @override
  State<FindAccountPage> createState() => _FindAccountPageState();
}

class _FindAccountPageState extends State<FindAccountPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final nameController = TextEditingController();
  final emailForIdController = TextEditingController();
  final emailForPwController = TextEditingController();
  String? foundUserId;

  final fieldColor = const Color(0xFFF5F7FA);
  final buttonColor = const Color(0xFFA5C8F8);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    nameController.dispose();
    emailForIdController.dispose();
    emailForPwController.dispose();
    super.dispose();
  }

  Future<void> _findUserId() async {
    final name = nameController.text.trim();
    final email = emailForIdController.text.trim();

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('nickName', isEqualTo: name)
          .where('userEmail', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() {
          foundUserId = query.docs.first['userId'];
        });
      } else {
        setState(() {
          foundUserId = null;
        });
        _showDialog('일치하는 계정을 찾을 수 없습니다.');
      }
    } catch (e) {
      _showDialog('오류가 발생했습니다.\n${e.toString()}');
    }
  }

  Future<void> _sendResetEmail() async {
    final email = emailForPwController.text.trim();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showDialog('$email 로 비밀번호 재설정 링크가 전송되었습니다.');
    } catch (e) {
      _showDialog('비밀번호 재설정 중 오류가 발생했습니다.\n${e.toString()}');
    }
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String hint, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('계정 찾기', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            indicatorColor: Color(0xFFA5C8F8),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: '아이디 찾기'),
              Tab(text: '비밀번호 찾기'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 아이디 찾기
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Icon(Icons.person_search, size: 60, color: Colors.grey),
                  const SizedBox(height: 20),
                  _buildInput('이름(별명)', nameController),
                  _buildInput('이메일', emailForIdController),
                  const SizedBox(height: 20),
                  _buildButton('아이디 찾기', _findUserId),
                  if (foundUserId != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      '찾은 아이디: $foundUserId',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ]
                ],
              ),
            ),

            // 비밀번호 찾기
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Icon(Icons.vpn_key, size: 60, color: Colors.grey),
                  const SizedBox(height: 20),
                  _buildInput('이메일', emailForPwController),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '가입한 이메일로 재설정 링크를 보내드립니다.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildButton('비밀번호 재설정 메일 보내기', _sendResetEmail),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
