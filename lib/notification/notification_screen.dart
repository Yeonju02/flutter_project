import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("로그인이 필요합니다.")));

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final notifications = snapshot.data!.docs;

          final now = DateTime.now();
          final List<DocumentSnapshot> recent = [];
          final List<DocumentSnapshot> older = [];

          for (var doc in notifications) {
            final createdAt = (doc['createdAt'] as Timestamp).toDate();
            if (now.difference(createdAt).inDays <= 7) {
              recent.add(doc);
            } else {
              older.add(doc);
            }
          }

          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('최근 7일', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ...recent.map((doc) => _buildNotificationTile(context, doc)),

              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text('지난 알림', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ...older.map((doc) => _buildNotificationTile(context, doc)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final notiType = data['notiType'];
    final notiMsg = data['notiMsg'];
    final boardId = data['boardId'];
    final isRead = data['isRead'] ?? false;
    final createdAt = (data['createdAt'] as Timestamp).toDate();

    return InkWell(
      onTap: () {
        // 알림 클릭 시 게시글 상세 페이지로 이동
        if (boardId != null && (notiType == 'like' || notiType == 'comment')) {
          Navigator.pushNamed(context, '/post/$boardId');
        }
      },
      child: Container(
        color: isRead ? Colors.transparent : const Color(0xFFE7F3FF),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notiMsg ?? '', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(_formatTimeAgo(createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}
