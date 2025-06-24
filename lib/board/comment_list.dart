import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentList extends StatefulWidget {
  final String boardId;
  final String? myNickName;
  final void Function(String commentId, String nickName)? onReplyTargetChanged;
  final void Function(String commentId, String content)? onEdit;

  const CommentList({
    super.key,
    required this.boardId,
    required this.myNickName,
    this.onReplyTargetChanged,
    this.onEdit,
  });

  @override
  State<CommentList> createState() => _CommentListState();
}

class _CommentListState extends State<CommentList> with AutomaticKeepAliveClientMixin {
  final Map<String, bool> expandedStates = {};
  final List<Color> levelColors = [
    Color(0xFFFF0000), Color(0xFFFF2600), Color(0xFFFF4D00), Color(0xFFFF7300), Color(0xFFFF7F00),
    Color(0xFFFF9933), Color(0xFFFFA533), Color(0xFFFFB233), Color(0xFFDAA520), Color(0xFFB8860B),
    Color(0xFF8B8000), Color(0xFF808000), Color(0xFF6B8E23), Color(0xFF556B2F), Color(0xFF228B22),
    Color(0xFF006400), Color(0xFF006A4E), Color(0xFF008000), Color(0xFF008B8B), Color(0xFF0099CC),
    Color(0xFF007BA7), Color(0xFF0066CC), Color(0xFF0033CC), Color(0xFF0000FF), Color(0xFF1B0091),
    Color(0xFF3400A2), Color(0xFF4B00B3), Color(0xFF6100C4), Color(0xFF7600D5), Color(0xFF8B00FF),
  ];

  @override
  bool get wantKeepAlive => true;

  Future<void> _deleteComment(String commentId) async {
    await FirebaseFirestore.instance
        .collection('boards')
        .doc(widget.boardId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.boardId.isEmpty) return const Text('boardId가 비어있습니다.');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('boards')
          .doc(widget.boardId)
          .collection('comments')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final docs = snapshot.data!.docs;
        Map<String, List<QueryDocumentSnapshot>> repliesMap = {};
        List<QueryDocumentSnapshot> topLevel = [];

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final parentId = data['parentId']?.toString();
          if (parentId == null || parentId.trim().isEmpty) {
            topLevel.add(doc);
          } else {
            repliesMap.putIfAbsent(parentId, () => []).add(doc);
          }
        }

        List<Widget> commentWidgets = [];

        void renderReplies(String parentId) {
          final replies = repliesMap[parentId] ?? [];
          for (var reply in replies) {
            final data = reply.data() as Map<String, dynamic>;
            final createdAt = (data['createdAt'] as Timestamp).toDate();
            final updatedAt = data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null;
            final timeAgo = _formatTimeAgo(createdAt);
            final userId = data['userId'] ?? '';
            final isMine = widget.myNickName != null && data['nickName'] == widget.myNickName;

            commentWidgets.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserAvatar(userId),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCommentHeaderFromUser(userId, timeAgo, updatedAt, isMine, () {
                            widget.onEdit?.call(reply.id, data['content']);
                          }, () {
                            _deleteComment(reply.id);
                          }),
                          const SizedBox(height: 4),
                          Text(data['content'] ?? ''),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: Colors.black),
                            onPressed: () {
                              widget.onReplyTargetChanged?.call(reply.id, data['nickName'] ?? '');
                            },
                            child: const Text('답글 달기'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
            renderReplies(reply.id);
          }
        }

        for (var parent in topLevel) {
          final data = parent.data() as Map<String, dynamic>;
          final createdAt = (data['createdAt'] as Timestamp).toDate();
          final updatedAt = data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null;
          final timeAgo = _formatTimeAgo(createdAt);
          final userId = data['userId'] ?? '';
          final isMine = widget.myNickName != null && data['nickName'] == widget.myNickName;

          commentWidgets.add(
            Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserAvatar(userId),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCommentHeaderFromUser(userId, timeAgo, updatedAt, isMine, () {
                          widget.onEdit?.call(parent.id, data['content']);
                        }, () {
                          _deleteComment(parent.id);
                        }),
                        const SizedBox(height: 4),
                        Text(data['content'] ?? ''),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  expandedStates[parent.id] = !(expandedStates[parent.id] ?? false);
                                });
                              },
                              child: Text(
                                (expandedStates[parent.id] ?? false)
                                    ? '답글 숨기기'
                                    : '답글 보기 (${_countReplies(parent.id, repliesMap)})',
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: Colors.black),
                              onPressed: () {
                                widget.onReplyTargetChanged?.call(parent.id, data['nickName'] ?? '');
                              },
                              child: const Text('답글 달기'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );

          if ((expandedStates[parent.id] ?? false)) {
            renderReplies(parent.id);
          }
        }

        return Column(children: commentWidgets);
      },
    );
  }

  Widget _buildUserAvatar(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        String? imgPath;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          imgPath = data['imgPath'];
        }

        return CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey[200],
          backgroundImage: (imgPath != null && imgPath.isNotEmpty) ? NetworkImage(imgPath) : null,
          child: (imgPath == null || imgPath.isEmpty) ? const Icon(Icons.person, color: Colors.grey) : null,
        );
      },
    );
  }

  Widget _buildCommentHeaderFromUser(String userId, String timeAgo, DateTime? updatedAt, bool isMine, VoidCallback onEdit, VoidCallback onDelete) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final level = (userData['level'] ?? 0).clamp(0, 29);
        final nickName = userData['nickName'] ?? '익명';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(nickName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: levelColors[level], width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lv.$level',
                    style: TextStyle(
                      color: levelColors[level],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('· $timeAgo', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (updatedAt != null)
                  const Text(' · 수정됨', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            if (isMine)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('수정')),
                  PopupMenuItem(value: 'delete', child: Text('삭제')),
                ],
              ),
          ],
        );
      },
    );
  }

  int _countReplies(String parentId, Map<String, List<QueryDocumentSnapshot>> repliesMap) {
    int count = 0;
    if (repliesMap.containsKey(parentId)) {
      final children = repliesMap[parentId]!;
      count += children.length;
      for (var child in children) {
        count += _countReplies(child.id, repliesMap);
      }
    }
    return count;
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
