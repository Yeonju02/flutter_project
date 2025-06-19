import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:routinelogapp/board/board_detail_screen.dart';
import '../custom/bottom_nav_bar.dart';
import '../main/main_page.dart';
import '../mypage/myPage_main.dart';
import '../shop/shop_main.dart';
import '../board/board_main_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("로그인이 필요합니다.")));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('알림', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
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
                padding: const EdgeInsets.only(bottom: 100),
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: BottomNavBar(
              currentIndex: 3,
              onTap: (index) {
                if (index == 0) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopMainPage()));
                }
                if (index == 1) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BoardMainScreen()));
                }
                if (index == 2) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MainPage()));
                }
                if (index == 3) {
                  // 현재 페이지
                }
                if (index == 4) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPageMain()));
                }
              },
            ),
          ),
        ],
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
    final notiNick = data['notiNick'] ?? '익명';
    final notiImg = data['notiImg'] ?? '';

    return InkWell(
      onTap: () async {
        if (boardId != null && (notiType == 'like' || notiType == 'comment')) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .collection('notifications')
              .doc(doc.id)
              .update({'isRead': true});

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BoardDetailScreen(boardId: boardId)),
          );
        }
      },
      child: Container(
        color: isRead ? Colors.transparent : const Color(0xFFE7F3FF),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE0E0E0),
              backgroundImage: notiImg.isNotEmpty ? NetworkImage(notiImg) : null,
              child: notiImg.isEmpty
                  ? const Icon(Icons.person, size: 20, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notiMsg ?? '', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(_formatTimeAgo(createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
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