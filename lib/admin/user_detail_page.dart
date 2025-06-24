import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserDetailPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UserDetailPage({super.key, required this.userData});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late String currentStatus;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.userData['status'] ?? 'U';
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.userData;
    final date = (data['joinedAt'] as Timestamp?)?.toDate();
    final joinedDate =
    date != null ? DateFormat('yyyy-MM-dd HH:mm').format(date) : '정보 없음';

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
            const Text('프로필 사진', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 10),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: data['imgPath'] != null
                    ? NetworkImage(data['imgPath'])
                    : const AssetImage('assets/no_image.png') as ImageProvider,
              ),
            ),

            const SizedBox(height: 20),

            _infoTile('닉네임', data['nickName']),
            _infoTile('아이디', data['userId']),
            _infoTile('이메일', data['userEmail']),
            _infoTile('전화번호', data['phone'] ?? '-'),
            _infoTile('가입일자', joinedDate),
            _infoTile('레벨', data['level'].toString()),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '상태',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),

            DropdownButtonFormField2<String>(
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF7F8FA),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 높이 줄임
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              value: currentStatus,
              items: const [
                DropdownMenuItem(value: 'A', child: Text('관리자')),
                DropdownMenuItem(value: 'U', child: Text('일반 사용자')),
              ],
              onChanged: (value) async {
                if (value != null) {
                  setState(() {
                    currentStatus = value;
                  });
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.userData['docId'])
                      .update({'status': value});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('상태가 변경되었습니다.')),
                  );
                }
              },
              buttonStyleData: const ButtonStyleData(
                padding: EdgeInsets.symmetric(horizontal: 12),
                height: 40,
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200,
                decoration: BoxDecoration(
                  color: Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),

            const SizedBox(height: 20),
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
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
}

