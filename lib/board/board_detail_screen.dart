import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'board_comment_screen.dart';
import 'board_write_screen.dart';
import '../custom/bottom_nav_bar.dart';
import '../main/main_page.dart';
import '../notification/notification_screen.dart';
import '../mypage/myPage_main.dart';
import '../shop/shop_main.dart';

class BoardDetailScreen extends StatefulWidget {
  final String boardId;

  const BoardDetailScreen({super.key, required this.boardId});

  @override
  State<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends State<BoardDetailScreen> {
  final PageController _pageController = PageController();

  Future<void> _onOpenLink(LinkableElement link) async {
    final String rawUrl = link.url.trim();

    debugPrint('클릭된 링크: $rawUrl');

    String fixedUrl = rawUrl;
    if (!fixedUrl.startsWith('http://') && !fixedUrl.startsWith('https://')) {
      fixedUrl = 'https://$fixedUrl';
    }

    try {
      final Uri uri = Uri.parse(fixedUrl);
      final launched = await launchUrl(uri);
      if (!launched) {
        debugPrint('launch 실패');
      }
    } catch (e) {
      debugPrint('예외 발생: $e');
    }
  }

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
    final boardDoc = FirebaseFirestore.instance.collection('boards').doc(widget.boardId);
    final user = FirebaseAuth.instance.currentUser;
    final likeDoc = boardDoc.collection('likes').doc(user?.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 상세'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Stack(
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: boardDoc.get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('존재하지 않는 게시글입니다.'));
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Row(
                    children: [
                      const CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/100')),
                      const SizedBox(width: 8),
                      Text(data['nickName'] ?? '익명', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.report_outlined),
                        onPressed: () => _reportBoard(context, widget.boardId),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(data['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: boardDoc.collection('boardFiles').orderBy('isThumbNail', descending: true).snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox.shrink();
                      final images = snap.data!.docs.map((e) => e['filePath'] as String).toList();

                      return Column(
                        children: [
                          SizedBox(
                            height: 300,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: images.length,
                              itemBuilder: (context, index) => Image.network(images[index], fit: BoxFit.cover),
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
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SelectableLinkify(
                      text: data['content'] ?? '',
                      onOpen: _onOpenLink,
                      style: const TextStyle(fontSize: 16, height: 1.6),
                      linkStyle: const TextStyle(color: Colors.blue),
                    ),
                  ),
                  const Divider(height: 32),
                  const Text('댓글', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  CommentScreenBody(boardId: widget.boardId),
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
                } else if (index == 2) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MainPage()));
                } else if (index == 3) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                } else if (index == 4) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MyPageMain()));
                } else if (index == 1) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
