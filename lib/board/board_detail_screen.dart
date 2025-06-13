import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'board_comment_screen.dart';
import 'board_write_screen.dart';
import '../custom/bottom_nav_bar.dart';
import '../main/main_page.dart';
import '../notification/notification_screen.dart';
import '../mypage/myPage_main.dart';
import '../shop/shop_main.dart';

class BoardDetailScreen extends StatelessWidget {
  final String boardId;

  const BoardDetailScreen({super.key, required this.boardId});

  Future<void> _reportBoard(BuildContext context, String boardId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final reportsRef = FirebaseFirestore.instance
        .collection('boards')
        .doc(boardId)
        .collection('reports');
    final existing = await reportsRef.where('reporterId', isEqualTo: user.uid).get();

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 신고한 게시글입니다.')),
      );
      return;
    }

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('신고 사유를 선택해주세요'),
        children: [
          SimpleDialogOption(child: const Text('욕설 / 비방'), onPressed: () => Navigator.pop(context, '욕설 / 비방')),
          SimpleDialogOption(child: const Text('광고 / 도배'), onPressed: () => Navigator.pop(context, '광고 / 도배')),
          SimpleDialogOption(child: const Text('부적절한 콘텐츠'), onPressed: () => Navigator.pop(context, '부적절한 콘텐츠')),
          SimpleDialogOption(child: const Text('기타'), onPressed: () => Navigator.pop(context, '기타')),
        ],
      ),
    );

    if (reason == null) return;

    await reportsRef.add({
      'boardId': boardId,
      'commentId': null,
      'reporterId': user.uid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
      'isResolved': false,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신고가 접수되었습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final boardDoc = FirebaseFirestore.instance.collection('boards').doc(boardId);
    final PageController _pageController = PageController();
    final user = FirebaseAuth.instance.currentUser;
    final likeDoc = FirebaseFirestore.instance.collection('boards').doc(boardId).collection('likes').doc(user?.uid);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('게시글', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: boardDoc.get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('오류 발생: ${snapshot.error}'));
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("존재하지 않는 게시글입니다."));
              }

              final data = snapshot.data!.data() as Map<String, dynamic>?;

              if (data == null || data['isDeleted'] == true) {
                return const Center(child: Text("삭제된 게시글입니다."));
              }

              final isMine = user != null && user.uid == data['userId'];

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
                          ),
                          const SizedBox(width: 8),
                          Text(data['nickName'] ?? '익명', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          StreamBuilder<DocumentSnapshot>(
                            stream: boardDoc.snapshots(),
                            builder: (context, boardSnapshot) {
                              final boardData = boardSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                              final likeCount = boardData['likeCount'] ?? 0;

                              return StreamBuilder<DocumentSnapshot>(
                                stream: likeDoc.snapshots(),
                                builder: (context, snapshot) {
                                  final isLiked = snapshot.data?.exists ?? false;

                                  return Row(
                                    children: [
                                      Text('$likeCount', style: const TextStyle(fontSize: 14)),
                                      IconButton(
                                        icon: Icon(
                                          isLiked ? Icons.favorite : Icons.favorite_border,
                                          color: isLiked ? const Color(0xFFF45050) : Colors.grey,
                                        ),
                                          onPressed: () async {
                                            if (isLiked) {
                                              await likeDoc.delete();
                                              await boardDoc.update({'likeCount': FieldValue.increment(-1)});
                                            } else {
                                              await likeDoc.set({'likedAt': FieldValue.serverTimestamp()});
                                              await boardDoc.update({'likeCount': FieldValue.increment(1)});

                                              // 알림 전송
                                              final currentUser = FirebaseAuth.instance.currentUser;
                                              final receiverUid = data['userId'];

                                              if (currentUser != null && receiverUid != currentUser.uid) {
                                                // 수신자 알림 설정 확인
                                                final notiSettingSnap = await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(receiverUid)
                                                    .collection('notiSettings')
                                                    .doc('main')
                                                    .get();

                                                final notiSettings = notiSettingSnap.data();
                                                final isLikeEnabled = notiSettings?['like'] ?? true;

                                                if (isLikeEnabled) {
                                                  // 현재 사용자 nickName 불러오기
                                                  final userDoc = await FirebaseFirestore.instance
                                                      .collection('users')
                                                      .doc(currentUser.uid)
                                                      .get();

                                                  final nickName = userDoc.data()?['nickName'] ?? '익명';

                                                  await FirebaseFirestore.instance
                                                      .collection('users')
                                                      .doc(receiverUid)
                                                      .collection('notifications')
                                                      .add({
                                                    'notiType': 'like',
                                                    'notiMsg': '$nickName님이 게시글을 좋아합니다.',
                                                    'boardId': boardId,
                                                    'createdAt': FieldValue.serverTimestamp(),
                                                    'isRead': false,
                                                  });
                                                }
                                              }
                                            }
                                          }
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          if (!isMine)
                            IconButton(
                              icon: const Icon(Icons.report_outlined),
                              onPressed: () => _reportBoard(context, boardId),
                            ),
                          if (isMine)
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BoardWriteScreen(post: {
                                        ...data,
                                        'boardId': boardId,
                                      }),
                                    ),
                                  );
                                } else if (value == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('삭제 확인'),
                                      content: const Text('게시글을 삭제하시겠습니까?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await boardDoc.update({'isDeleted': true});
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('게시글이 삭제되었습니다.')),
                                      );
                                    }
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('수정')),
                                const PopupMenuItem(value: 'delete', child: Text('삭제')),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: boardDoc.collection('boardFiles').orderBy('isThumbNail', descending: true).snapshots(),
                    builder: (context, imageSnap) {
                      if (!imageSnap.hasData || imageSnap.data!.docs.isEmpty) {
                        return const SizedBox();
                      }
                      final images = imageSnap.data!.docs.map((e) => e['filePath'] as String).toList();

                      return Column(
                        children: [
                          SizedBox(
                            height: 300,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: images.length,
                              itemBuilder: (context, i) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(images[i], fit: BoxFit.cover, width: double.infinity),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          SmoothPageIndicator(
                            controller: _pageController,
                            count: images.length,
                            effect: const ScrollingDotsEffect(
                              activeDotColor: Colors.black,
                              dotColor: Colors.grey,
                              dotHeight: 8,
                              dotWidth: 8,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                  Text(data['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(data['content'] ?? '', style: const TextStyle(fontSize: 16, height: 1.5)),
                  const Divider(height: 32, thickness: 1),
                  const SizedBox(height: 32),
                  const Text('댓글', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  CommentScreenBody(boardId: boardId),
                ],
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBar(
              currentIndex: 1,
              onTap: (index) {
                if (index == 0) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopMainPage()));
                } else if (index == 1) {
                  Navigator.pop(context);
                } else if (index == 2) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MainPage()));
                } else if (index == 3) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                } else if (index == 4) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MyPageMain()));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
