import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentScreenBody extends StatefulWidget {
  final String boardId;
  const CommentScreenBody({super.key, required this.boardId});

  @override
  State<CommentScreenBody> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreenBody> {
  final TextEditingController _commentController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  String? _replyToId;
  String? myNickName;

  @override
  void initState() {
    super.initState();
    _loadMyNickName();
  }

  Future<void> _loadMyNickName() async {
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    setState(() {
      myNickName = userDoc.data()?['nickName'];
    });
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || user == null || myNickName == null) return;

    await FirebaseFirestore.instance
        .collection('boards')
        .doc(widget.boardId)
        .collection('comments')
        .add({
      'nickName': myNickName,
      'content': content,
      'parentId': _replyToId,
      'createdAt': Timestamp.now(),
      'userId': user!.uid,
    });

    final boardDoc = await FirebaseFirestore.instance
        .collection('boards')
        .doc(widget.boardId)
        .get();

    final boardOwnerId = boardDoc.data()?['userId'];
    if (boardOwnerId != null && boardOwnerId != user!.uid) {
      // 댓글 알림 설정 여부 확인
      final settingSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(boardOwnerId)
          .collection('notiSettings')
          .doc('main')
          .get();

      final settings = settingSnap.data();
      final isCommentEnabled = settings?['comment'] ?? false;

      if (isCommentEnabled) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(boardOwnerId)
            .collection('notifications')
            .add({
          'notiType': 'comment',
          'notiMsg': '$myNickName 님이 댓글을 남겼습니다',
          'boardId': widget.boardId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    setState(() {
      _replyToId = null;
    });

    _commentController.clear();
  }

  Future<void> _deleteComment(String commentId) async {
    await FirebaseFirestore.instance
        .collection('boards')
        .doc(widget.boardId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  Future<void> _editComment(String commentId, String currentContent) async {
    final controller = TextEditingController(text: currentContent);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 수정'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              final updatedText = controller.text.trim();
              if (updatedText.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('boards')
                    .doc(widget.boardId)
                    .collection('comments')
                    .doc(commentId)
                    .update({
                  'content': updatedText,
                  'updatedAt': Timestamp.now(),
                });
              }
              Navigator.pop(context);
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> data, String commentId, int indent, bool isMine, DateTime createdAt, DateTime? updatedAt) {
    final timeAgo = _formatTimeAgo(createdAt);

    return Padding(
      padding: EdgeInsets.only(left: 32.0 * indent, right: 12, bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(data['nickName'] ?? '익명', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 6),
                              Text('· $timeAgo', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              if (updatedAt != null)
                                const Text(' · 수정됨', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(data['content'] ?? ''),
                        ],
                      ),
                    ),
                    if (isMine)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editComment(commentId, data['content']);
                          } else if (value == 'delete') {
                            _deleteComment(commentId);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('수정')),
                          const PopupMenuItem(value: 'delete', child: Text('삭제')),
                        ],
                      ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _replyToId = commentId;
                        });
                        _commentController.text = '@${data['nickName']} ';
                      },
                      child: const Text('답글 달기', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('boards')
              .doc(widget.boardId)
              .collection('comments')
              .orderBy('createdAt', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;

            Map<String, List<QueryDocumentSnapshot>> repliesMap = {};
            List<QueryDocumentSnapshot> topLevel = [];

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final parentId = data['parentId'];
              if (parentId == null) {
                topLevel.add(doc);
              } else {
                repliesMap.putIfAbsent(parentId, () => []).add(doc);
              }
            }

            List<Widget> commentWidgets = [];
            void addComments(List<QueryDocumentSnapshot> comments, {bool isTopLevel = false}) {
              for (var doc in comments) {
                final data = doc.data() as Map<String, dynamic>;
                final createdAt = (data['createdAt'] as Timestamp).toDate();
                final updatedAt = data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null;
                final isMine = myNickName != null && data['nickName'] == myNickName;

                final indent = isTopLevel ? 0 : 1;

                commentWidgets.add(_buildCommentTile(data, doc.id, indent, isMine, createdAt, updatedAt));
                if (repliesMap.containsKey(doc.id)) {
                  addComments(repliesMap[doc.id]!, isTopLevel: false);
                }
              }
            }

            addComments(topLevel, isTopLevel: true);
            return ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: commentWidgets,
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: '댓글을 입력하세요...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _submitComment,
              child: const Text('등록'),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}