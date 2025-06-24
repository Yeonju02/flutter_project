import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:routinelogapp/board/board_detail_screen.dart';
import 'package:routinelogapp/board/board_write_screen.dart';
import 'package:routinelogapp/custom/bottom_nav_bar.dart';
import 'package:routinelogapp/main/main_page.dart';
import 'package:routinelogapp/mypage/myPage_main.dart';
import 'package:routinelogapp/notification/notification_screen.dart';
import 'package:routinelogapp/shop/shop_main.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BoardMainScreen extends StatefulWidget {
  const BoardMainScreen({super.key});

  @override
  State<BoardMainScreen> createState() => _BoardMainScreenState();
}

class _BoardMainScreenState extends State<BoardMainScreen> {
  String _selectedCategory = '전체';
  String _sortOption = '최신글';
  final List<String> _categories = ['전체', '아침 루틴 후기/공유', '수면 관리 후기/공유', '제품/영상 추천', '공지사항'];

  void _handlePostMenuSelection(String value, Map<String, dynamic> post) async {
    if (!mounted) return; // 위젯이 아직 살아있을 때만 실행

    if (value == 'edit') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BoardWriteScreen(post: post)),
      );
    } else if (value == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            '삭제 확인',
            style: TextStyle(color: Colors.black),
          ),
          content: const Text(
            '이 게시글을 삭제하시겠습니까?',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              child: const Text('취소', style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: const Text('삭제', style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await FirebaseFirestore.instance
            .collection('boards')
            .doc(post['boardId'])
            .update({'isDeleted': true});

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글이 삭제되었습니다.')),
        );

        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('게시판', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 23.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF92BBE2),     // 선택된 배경
                          backgroundColor: const Color(0xFFE0E0E0),   // 선택되지 않은 배경
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF92BBE2) : Colors.grey.shade300,
                            ),
                          ),
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 최신글/인기글 드롭다운 버튼
                    IntrinsicWidth(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton2<String>(
                          value: _sortOption,
                          isExpanded: false,
                          buttonStyleData: ButtonStyleData(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF92BBE2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          dropdownStyleData: DropdownStyleData(
                            decoration: BoxDecoration(
                              color: const Color(0xFF92BBE2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          iconStyleData: const IconStyleData(
                            icon: Icon(Icons.arrow_drop_down, size: 20, color: Colors.white),
                            openMenuIcon: Icon(Icons.arrow_drop_up, size: 20, color: Colors.white),
                          ),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          items: ['최신글', '인기글'].map((value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _sortOption = value);
                            }
                          },
                        ),
                      ),
                    ),

                    // 글쓰기 버튼
                    IntrinsicWidth(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF92BBE2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BoardWriteScreen()),
                          );
                        },
                        child: const Text("글쓰기"),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _getVisiblePostsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final posts = snapshot.data ?? [];
                    if (posts.isEmpty) return const Center(child: Text('게시글이 없습니다.'));

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return post['__isReported'] == true
                            ? _buildReportedCard()
                            : _buildPostCard(post);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: BottomNavBar(
              currentIndex: 1,
              onTap: (index) {
                if (index == 0) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopMainPage()));
                } else if (index == 1) {
                  // 현재 페이지
                } else if (index == 2) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MainPage()));
                } else if (index == 3) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                } else if (index == 4) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPageMain()));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getVisiblePostsStream() async* {
    final user = FirebaseAuth.instance.currentUser;

    await for (final snapshot in FirebaseFirestore.instance
        .collection('boards')
        .orderBy(_sortOption == '최신글' ? 'createdAt' : 'likeCount', descending: true)
        .snapshots()) {
      final filtered = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['boardId'] = doc.id;

        if (data['isDeleted'] == true) continue;
        if (_selectedCategory != '전체' && data['boardCategory'] != _selectedCategory) continue;

        final reports = await FirebaseFirestore.instance
            .collection('boards')
            .doc(data['boardId'])
            .collection('reports')
            .where('reporterId', isEqualTo: user?.uid)
            .get();

        if (reports.docs.isNotEmpty) {
          data['__isReported'] = true;
        }

        filtered.add(data);
      }

      yield filtered;
    }
  }

  Future<void> _reportBoard(String boardId) async {
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
        backgroundColor: Colors.white,
        title: const Text('신고 사유를 선택해주세요'),
        children: [
          SimpleDialogOption(
            child: const Text('욕설 / 비방'),
            onPressed: () => Navigator.pop(context, '욕설 / 비방'),
          ),
          SimpleDialogOption(
            child: const Text('광고 / 도배'),
            onPressed: () => Navigator.pop(context, '광고 / 도배'),
          ),
          SimpleDialogOption(
            child: const Text('부적절한 콘텐츠'),
            onPressed: () => Navigator.pop(context, '부적절한 콘텐츠'),
          ),
          SimpleDialogOption(
            child: const Text('기타'),
            onPressed: () => Navigator.pop(context, '기타'),
          ),
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

    setState(() {});
  }

  Widget _buildReportedCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 23.0),
        child: Center(
          child: Text('\u{1F6AB} 신고한 게시글입니다', style: TextStyle(color: Colors.grey[600])),
        ),
      ),
    );
  }

  Future<void> _onOpenLink(LinkableElement link) async {
    String rawUrl = link.url.trim();

    if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
      rawUrl = 'https://$rawUrl';
    }

    final url = Uri.parse(rawUrl);

    final success = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL을 열 수 없습니다')),
      );
    }
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final PageController _pageController = PageController();
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    final boardDoc = FirebaseFirestore.instance.collection('boards').doc(post['boardId']);
    final likeDoc = boardDoc.collection('likes').doc(userId);
    final isNotice = post['boardCategory'] == '공지사항';

    bool isExpanded = false;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BoardDetailScreen(boardId: post['boardId']),
          ),
        );
      },
      child: StatefulBuilder(
        builder: (context, setState) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
            builder: (context, currentUserSnapshot) {
              final currentUserData = currentUserSnapshot.data?.data() as Map<String, dynamic>? ?? {};
              final isCurrentUserAdmin = currentUserData['status'] == 'A';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(post['userId']).get(),
                builder: (context, userSnapshot) {
                  final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                  final List<Color> levelColors = [
                    Color(0xFFFF0000), Color(0xFFFF2600), Color(0xFFFF4D00), Color(0xFFFF7300), Color(0xFFFF7F00),
                    Color(0xFFFF9933), Color(0xFFFFA533), Color(0xFFFFB233), Color(0xFFDAA520), Color(0xFFB8860B),
                    Color(0xFF8B8000), Color(0xFF808000), Color(0xFF6B8E23), Color(0xFF556B2F), Color(0xFF228B22),
                    Color(0xFF006400), Color(0xFF006A4E), Color(0xFF008000), Color(0xFF008B8B), Color(0xFF0099CC),
                    Color(0xFF007BA7), Color(0xFF0066CC), Color(0xFF0033CC), Color(0xFF0000FF), Color(0xFF1B0091),
                    Color(0xFF3400A2), Color(0xFF4B00B3), Color(0xFF6100C4), Color(0xFF7600D5), Color(0xFF8B00FF),
                  ];

                  final level = userData['level'] ?? 0;
                  final levelColor = levelColors[(level - 1).clamp(0, levelColors.length - 1)];

                  final String? profileImg = userData['imgPath'];
                  final isPostWriterAdmin = userData['status'] == 'A';

                  return Card(
                    color: const Color(0xFFE7F3FF),
                    elevation: 0,
                    margin: const EdgeInsets.all(12),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 프로필 헤더
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                            child: Row(
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
                                    Text(post['nickName'] ?? '익명',
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    isPostWriterAdmin && isNotice
                                        ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '공지사항',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
                                    )
                                        : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: levelColor, width: 1),
                                      ),
                                      child: Text(
                                        'Lv.$level',
                                        style: TextStyle(
                                          color: levelColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (userId != post['userId'])
                                      IconButton(
                                        icon: const Icon(LucideIcons.alertTriangle,
                                            size: 26, color: Colors.blueGrey),
                                        onPressed: () => _reportBoard(post['boardId']),
                                      ),
                                    if (userId == post['userId'] || isCurrentUserAdmin)
                                      PopupMenuButton<String>(
                                        padding: EdgeInsets.zero,
                                        color: const Color(0xFF92BBE2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        onSelected: (value) => _handlePostMenuSelection(value, post),
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 4),
                                              child: Text('수정',
                                                  style: TextStyle(color: Colors.white)),
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 4),
                                              child: Text('삭제',
                                                  style: TextStyle(color: Colors.white)),
                                            ),
                                          ),
                                        ],
                                        icon: const Icon(Icons.more_vert),
                                      )
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 이미지 슬라이드
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('boards')
                                .doc(post['boardId'])
                                .collection('boardFiles')
                                .orderBy('isThumbNail', descending: true)
                                .snapshots(),
                            builder: (context, snap) {
                              if (snap.hasData && snap.data!.docs.isNotEmpty) {
                                final images =
                                snap.data!.docs.map((e) => e['filePath'] as String).toList();
                                return Column(
                                  children: [
                                    SizedBox(
                                      height: 250,
                                      child: PageView.builder(
                                        controller: _pageController,
                                        itemCount: images.length,
                                        itemBuilder: (context, index) {
                                          return Image.network(images[index],
                                              fit: BoxFit.cover, width: double.infinity);
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
                                  ],
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),

                          // 텍스트 본문
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 좋아요 버튼
                                StreamBuilder<DocumentSnapshot>(
                                  stream: boardDoc.snapshots(),
                                  builder: (context, boardSnapshot) {
                                    final boardData =
                                        boardSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                                    final likeCount = boardData['likeCount'] ?? 0;

                                    return StreamBuilder<DocumentSnapshot>(
                                      stream: likeDoc.snapshots(),
                                      builder: (context, snapshot) {
                                        final isLiked = snapshot.data?.exists ?? false;

                                        return Column(
                                          children: [
                                            IconButton(
                                                icon: Icon(
                                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                                  color: isLiked
                                                      ? const Color(0xFFF45050)
                                                      : Colors.grey,
                                                ),
                                                onPressed: () async {
                                                  if (isLiked) {
                                                    await likeDoc.delete();
                                                    await boardDoc.update({
                                                      'likeCount': FieldValue.increment(-1)
                                                    });
                                                  } else {
                                                    await likeDoc.set({
                                                      'likedAt': FieldValue.serverTimestamp()
                                                    });
                                                    await boardDoc.update({
                                                      'likeCount': FieldValue.increment(1)
                                                    });

                                                    // 좋아요 관련 로직
                                                    final missionQuery = await FirebaseFirestore.instance
                                                        .collection('users')
                                                        .doc(userId)
                                                        .collection('missions')
                                                        .where('missionTitle', isEqualTo: '게시글에 좋아요 3번 남기기')
                                                        .limit(1)
                                                        .get();

                                                    if (missionQuery.docs.isNotEmpty) {
                                                      final missionDoc = missionQuery.docs.first;
                                                      final missionData = missionDoc.data();
                                                      final current = (missionData['recentCount'] ?? 0).toInt();
                                                      final max = (missionData['maxCount'] ?? 3).toInt();

                                                      if (current < max) {
                                                        await FirebaseFirestore.instance
                                                            .collection('users')
                                                            .doc(userId)
                                                            .collection('missions')
                                                            .doc(missionDoc.id)
                                                            .update({'recentCount': current + 1});

                                                        if (current + 1 == max) {
                                                          final allMissionQuery = await FirebaseFirestore.instance
                                                              .collection('users')
                                                              .doc(userId)
                                                              .collection('missions')
                                                              .where('missionTitle', isEqualTo: '모든 미션 완료하기')
                                                              .limit(1)
                                                              .get();

                                                          if (allMissionQuery.docs.isNotEmpty) {
                                                            final allDoc = allMissionQuery.docs.first;
                                                            final allData = allDoc.data();
                                                            final allCurrent = (allData['recentCount'] ?? 0).toInt();
                                                            final allMax = (allData['maxCount'] ?? 1).toInt();

                                                            if (allCurrent < allMax) {
                                                              await FirebaseFirestore.instance
                                                                  .collection('users')
                                                                  .doc(userId)
                                                                  .collection('missions')
                                                                  .doc(allDoc.id)
                                                                  .update({'recentCount': allCurrent + 1});
                                                            }
                                                          }
                                                        }
                                                      }
                                                    }

                                                    final receiverUid = post['userId'];
                                                    if (userId != receiverUid) {
                                                      final notiSettingSnap =
                                                      await FirebaseFirestore.instance
                                                          .collection('users')
                                                          .doc(receiverUid)
                                                          .collection('notiSettings')
                                                          .doc('main')
                                                          .get();

                                                      final notiSettings = notiSettingSnap.data();
                                                      final isLikeEnabled =
                                                          notiSettings?['like'] ?? false;

                                                      if (isLikeEnabled) {

                                                        final userDoc = await FirebaseFirestore.instance
                                                            .collection('users')
                                                            .doc(userId) // 좋아요 누른 사람 (현재 유저)
                                                            .get();

                                                        final nickName = userDoc.data()?['nickName'] ?? '익명';
                                                        final profileImage = userDoc.data()?['imgPath'] ?? '';

                                                        await FirebaseFirestore.instance
                                                            .collection('users')
                                                            .doc(receiverUid)
                                                            .collection('notifications')
                                                            .add({
                                                          'notiType': 'like',
                                                          'notiMsg': '$nickName님이 게시글을 좋아합니다.',
                                                          'boardId': post['boardId'],
                                                          'notiImg': profileImage,
                                                          'createdAt':
                                                          FieldValue.serverTimestamp(),
                                                          'isRead': false,
                                                        });
                                                      }
                                                    }
                                                  }
                                                }),
                                            Text('$likeCount',
                                                style: const TextStyle(fontSize: 12)),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),

                                const SizedBox(width: 12),

                                // 게시글 내용
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(post['title'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      AnimatedCrossFade(
                                        crossFadeState: isExpanded
                                            ? CrossFadeState.showSecond
                                            : CrossFadeState.showFirst,
                                        duration: const Duration(milliseconds: 300),
                                        firstChild: Linkify(
                                          text: post['content'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          onOpen: _onOpenLink,
                                        ),
                                        secondChild: Linkify(
                                          text: post['content'] ?? '',
                                          onOpen: _onOpenLink,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: () => setState(() => isExpanded = !isExpanded),
                                        child: Text(
                                          isExpanded ? '간략히' : '더보기',
                                          style: const TextStyle(color: Colors.blue),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 댓글 미리보기
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('boards')
                                .doc(post['boardId'])
                                .collection('comments')
                                .orderBy('createdAt', descending: true)
                                .limit(1)
                                .snapshots(),
                            builder: (context, snapshot) {
                              String preview = '댓글이 아직 없습니다.';

                              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                final commentData =
                                snapshot.data!.docs.first.data() as Map<String, dynamic>;
                                preview = commentData['content'] ?? '내용 없음';
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('💬 ', style: TextStyle(fontSize: 16)),
                                    Expanded(
                                      child: Text(
                                        preview,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}