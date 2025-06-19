import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserDetailPage extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserDetailPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final date = (userData['joinedAt'] as Timestamp?)?.toDate();
    final joinedDate = date != null ? DateFormat('yyyy-MM-dd HH:mm').format(date) : '정보 없음';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF819CFF),
        title: const Text('회원 상세 정보', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('프로필 사진', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            SizedBox(height: 10,)
,            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: userData['imgPath'] != null
                    ? NetworkImage(userData['imgPath'])
                    : const AssetImage('assets/no_image.png') as ImageProvider,
              ),
            ),
            const SizedBox(height: 20),

            // 정보 카드
            _infoTile('닉네임', userData['nickName']),
            _infoTile('아이디', userData['userId']),
            _infoTile('이메일', userData['userEmail']),
            _infoTile('전화번호', userData['phone'] ?? '-'),
            _infoTile('가입일자', joinedDate),
            _infoTile('회원등급', userData['level'].toString()),
            _infoTile('상태', _statusLabel(userData['status'])),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String title, dynamic value) {
    final display = (value == null || value.toString().trim().isEmpty) ? '-' : value.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FA),
            borderRadius: BorderRadius.circular(12),
          ),
          width: double.infinity,
          child: Text(
            display,
            style: const TextStyle(fontSize: 15),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'A':
        return '관리자';
      case 'U':
        return '일반 사용자';
      default:
        return '알 수 없음';
    }
  }
}
