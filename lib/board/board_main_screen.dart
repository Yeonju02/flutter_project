import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routinelogapp/board/board-comment-screen.dart';
import 'package:routinelogapp/board/board_write_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BoardMainScreen extends StatefulWidget {
  const BoardMainScreen({super.key});

  @override
  State<BoardMainScreen> createState() => _BoardMainScreenState();
}

class _BoardMainScreenState extends State<BoardMainScreen> {
  String _selectedCategory = '전체';
  String _sortOption = '최신글';

  final List<String> _categories = ['전체', '아침 루틴 후기/공유', '수면 관리 후기/공유', '제품/영상 추천', '공지사항'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게시판')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: _categories.map((cat) {
                      return ChoiceChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      );
                    }).toList(),
                  ),
                ),
                DropdownButton<String>(
                  value: _sortOption,
                  items: ['최신글', '인기글'].map((value) {
                    return DropdownMenuItem(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortOption = value);
                    }
                  },
                )
              ],
            ),
          ),
          const Divider(thickness: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('boards')
                  .orderBy(
                _sortOption == '최신글' ? 'createdAt' : 'likeCount',
                descending: true,
              )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('게시글이 없습니다.'));
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isDeleted'] != true;
                }).toList();

                final filteredDocs = _selectedCategory == '전체'
                    ? docs
                    : docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['boardCategory'] == _selectedCategory;
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final post = filteredDocs[index].data() as Map<String, dynamic>;
                    return _buildPostCard(post);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context,
            MaterialPageRoute(builder: (context) => BoardWriteScreen()),
          );
        },
        label: const Text('글쓰기'),
        icon: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final PageController _pageController = PageController();
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    final boardDoc = FirebaseFirestore.instance.collection('boards').doc(post['boardId']);
    final likeDoc = boardDoc.collection('likes').doc(userId);

    bool isExpanded = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(post['userId']).get(),
          builder: (context, userSnapshot) {
            final level = userSnapshot.hasData ? 'LV.${userSnapshot.data!.get('level').toString()}' : 'LV.?';

            return Card(
              margin: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 유저 정보
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
                            ),
                            const SizedBox(width: 8),
                            Text(post['nickName'] ?? '익명', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Text(level, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.flag), onPressed: () {}),
                      ],
                    ),
                  ),

                  // 썸네일 (확장 상태면 안 보임)
                  if (!isExpanded)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('boards')
                          .doc(post['boardId'])
                          .collection('boardFiles')
                          .orderBy('isThumbNail', descending: true)
                          .snapshots(),
                      builder: (context, snap) {
                        if (snap.hasData && snap.data!.docs.isNotEmpty) {
                          final images = snap.data!.docs.map((e) => e['filePath'] as String).toList();
                          return Column(
                            children: [
                              SizedBox(
                                height: 250,
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: images.length,
                                  itemBuilder: (context, index) {
                                    return Image.network(images[index], fit: BoxFit.cover, width: double.infinity);
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

                  // 제목 + 내용 + 좋아요
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreamBuilder<DocumentSnapshot>(
                          stream: likeDoc.snapshots(),
                          builder: (context, snapshot) {
                            final isLiked = snapshot.data?.exists ?? false;
                            final likeCount = post['likeCount'] ?? 0;

                            return Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: isLiked ? const Color(0xFFF45050) : Colors.grey,
                                  ),
                                  onPressed: () async {
                                    final boardSnapshot = await boardDoc.get();
                                    final currentCount = boardSnapshot.data()?['likeCount'] ?? 0;

                                    if (isLiked) {
                                      await likeDoc.delete();
                                      await boardDoc.update({'likeCount': currentCount - 1});
                                    } else {
                                      await likeDoc.set({'likedAt': FieldValue.serverTimestamp()});
                                      await boardDoc.update({'likeCount': currentCount + 1});
                                    }
                                  },
                                ),
                                Text('$likeCount', style: const TextStyle(fontSize: 12)),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(post['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              AnimatedCrossFade(
                                crossFadeState: isExpanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 300),
                                firstChild: Text(
                                  post['content'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                secondChild: Text(post['content'] ?? ''),
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
                        final commentData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                        preview = commentData['content'] ?? '내용 없음';
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommentScreen(boardId: post['boardId']),
                              ),
                            );
                          },
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
                        ),
                      );
                    },
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}