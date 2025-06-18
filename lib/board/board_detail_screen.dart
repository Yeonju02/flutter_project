import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routinelogapp/board/comment_input_bar.dart';
import 'package:routinelogapp/board/comment_list.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BoardDetailScreen extends StatefulWidget {
  final String boardId;

  const BoardDetailScreen({super.key, required this.boardId});

  @override
  State<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends State<BoardDetailScreen> {
  final PageController _pageController = PageController();
  String? myNickName;

  @override
  void initState() {
    super.initState();
    _loadMyNickName();
  }

  Future<void> _loadMyNickName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    setState(() {
      myNickName = userDoc.data()?['nickName'] ?? '익명';
    });
  }

  Future<void> _onOpenLink(LinkableElement link) async {
    final String rawUrl = link.url.trim();
    String fixedUrl = rawUrl;
    if (!fixedUrl.startsWith('http://') && !fixedUrl.startsWith('https://')) {
      fixedUrl = 'https://$fixedUrl';
    }
    try {
      final Uri uri = Uri.parse(fixedUrl);
      await launchUrl(uri);
    } catch (e) {
      debugPrint('링크 열기 실패: $e');
    }
  }

  Future<void> _reportBoard(BuildContext context, String boardId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final reportsRef = FirebaseFirestore.instance.collection('boards').doc(boardId).collection('reports');
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
    if (myNickName == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final boardDoc = FirebaseFirestore.instance.collection('boards').doc(widget.boardId);
    final likeDoc = FirebaseFirestore.instance
        .collection('boards')
        .doc(widget.boardId)
        .collection('likes')
        .doc(FirebaseAuth.instance.currentUser?.uid);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('게시글', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: FutureBuilder<DocumentSnapshot>(
                future: boardDoc.get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('존재하지 않는 게시글입니다.'));
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 좋아요 및 신고 포함 유저 정보
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(data['userId']).get(),
                        builder: (context, userSnapshot) {
                          String? profileImg;
                          if (userSnapshot.hasData && userSnapshot.data!.exists) {
                            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                            profileImg = userData['imgPath'];
                          }

                          return StreamBuilder<DocumentSnapshot>(
                            stream: boardDoc.snapshots(),
                            builder: (context, boardSnapshot) {
                              final boardData = boardSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                              final likeCount = boardData['likeCount'] ?? 0;

                              return StreamBuilder<DocumentSnapshot>(
                                stream: likeDoc.snapshots(),
                                builder: (context, snapshot) {
                                  final isLiked = snapshot.data?.exists ?? false;

                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: const Color(0xFFE0E0E0),
                                            backgroundImage: (profileImg != null && profileImg.isNotEmpty)
                                                ? NetworkImage(profileImg)
                                                : null,
                                            child: (profileImg == null || profileImg.isEmpty)
                                                ? const Icon(Icons.person, size: 24, color: Colors.grey)
                                                : null,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(data['nickName'] ?? '익명', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text('$likeCount', style: const TextStyle(fontSize: 14)),
                                          IconButton(
                                            icon: Icon(
                                              isLiked ? Icons.favorite : Icons.favorite_border,
                                              size: 26,
                                              color: isLiked ? const Color(0xFFF45050) : Colors.grey,
                                            ),
                                            onPressed: () async {
                                              final user = FirebaseAuth.instance.currentUser;
                                              if (user == null) return;

                                              if (isLiked) {
                                                await likeDoc.delete();
                                                await boardDoc.update({'likeCount': FieldValue.increment(-1)});
                                              } else {
                                                await likeDoc.set({'likedAt': FieldValue.serverTimestamp()});
                                                await boardDoc.update({'likeCount': FieldValue.increment(1)});

                                                final receiverUid = data['userId'];
                                                if (receiverUid != user.uid) {
                                                  final notiSettingSnap = await FirebaseFirestore.instance
                                                      .collection('users')
                                                      .doc(receiverUid)
                                                      .collection('notiSettings')
                                                      .doc('main')
                                                      .get();

                                                  final notiSettings = notiSettingSnap.data();
                                                  final isLikeEnabled = notiSettings?['like'] ?? true;

                                                  if (isLikeEnabled) {
                                                    final userDoc = await FirebaseFirestore.instance
                                                        .collection('users')
                                                        .doc(user.uid)
                                                        .get();
                                                    final nickName = userDoc.data()?['nickName'] ?? '익명';
                                                    await FirebaseFirestore.instance
                                                        .collection('users')
                                                        .doc(receiverUid)
                                                        .collection('notifications')
                                                        .add({
                                                      'notiType': 'like',
                                                      'notiMsg': '$nickName님이 게시글을 좋아합니다.',
                                                      'boardId': widget.boardId,
                                                      'createdAt': FieldValue.serverTimestamp(),
                                                      'isRead': false,
                                                    });
                                                  }
                                                }
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(LucideIcons.alertTriangle, size: 26, color: Colors.blueGrey),
                                            onPressed: () => _reportBoard(context, widget.boardId),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
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
                      SelectableLinkify(
                        text: data['content'] ?? '',
                        onOpen: _onOpenLink,
                        style: const TextStyle(fontSize: 16, height: 1.6),
                        linkStyle: const TextStyle(color: Colors.blue),
                      ),
                      const Divider(height: 32),
                      const Text('댓글', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      CommentList(
                        boardId: widget.boardId,
                        myNickName: myNickName,
                        onReplyTargetChanged: (id, nick) {},
                        onEdit: (id, content) {},
                      )
                    ],
                  );
                },
              ),
            ),
          ),
          CommentInputBar(boardId: widget.boardId),
        ],
      ),
    );
  }
}
