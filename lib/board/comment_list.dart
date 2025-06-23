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

    if (widget.boardId.isEmpty) {
      return const Text('boardId가 비어있습니다.');
    }

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
                padding: const EdgeInsets.fromLTRB(32.0, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserAvatar(userId),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCommentHeader(data, timeAgo, updatedAt, isMine, () {
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
            renderReplies(reply.id.toString());
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
                        _buildCommentHeader(data, timeAgo, updatedAt, isMine, () {
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
      builder: (context, userSnapshot) {
        if (!mounted) return const SizedBox();

        String? imgPath;
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          imgPath = userData['imgPath'];
        }

        return CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFE0E0E0),
          backgroundImage: (imgPath != null && imgPath.isNotEmpty) ? NetworkImage(imgPath) : null,
          child: (imgPath == null || imgPath.isEmpty)
              ? const Icon(Icons.person, size: 20, color: Colors.grey)
              : null,
        );
      },
    );
  }

  Widget _buildCommentHeader(
      Map<String, dynamic> data,
      String timeAgo,
      DateTime? updatedAt,
      bool isMine,
      VoidCallback onEdit,
      VoidCallback onDelete,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        if (isMine)
          PopupMenuButton<String>(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('수정')),
              PopupMenuItem(value: 'delete', child: Text('삭제')),
            ],
          ),
      ],
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
