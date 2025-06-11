import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentScreen extends StatefulWidget {
  final String boardId;

  const CommentScreen({super.key, required this.boardId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
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
      'userId': user!.uid, // 남겨두되 사용은 안 함
    });

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

  Widget _buildCommentTile(DocumentSnapshot doc, {int indent = 0, bool showDivider = false}) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = (data['createdAt'] as Timestamp).toDate();
    final updatedAt = data['updatedAt'] != null
        ? (data['updatedAt'] as Timestamp).toDate()
        : null;
    final isMine = myNickName != null && data['nickName'] == myNickName;
    final timeAgo = _formatTimeAgo(createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: 16.0 * indent, right: 8),
            child: const Divider(thickness: 1, height: 16, color: Colors.grey),
          ),
        Padding(
          padding: EdgeInsets.only(left: 16.0 * indent, right: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
                ),
                title: Row(
                  children: [
                    Text(data['nickName'] ?? '익명'),
                    const SizedBox(width: 6),
                    Text('· $timeAgo', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (updatedAt != null)
                      const Text(' · 수정됨', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                subtitle: Text(data['content'] ?? ''),
                trailing: isMine
                    ? PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editComment(doc.id, data['content']);
                    } else if (value == 'delete') {
                      _deleteComment(doc.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('수정')),
                    const PopupMenuItem(value: 'delete', child: Text('삭제')),
                  ],
                )
                    : null,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _replyToId = doc.id;
                  });
                  _commentController.text = '@${data['nickName']} ';
                },
                child: const Text('답글 달기', style: TextStyle(fontSize: 13)),
              ),
              _buildReplies(doc.id, indent: indent + 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReplies(String parentId, {int indent = 1}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('boards')
          .doc(widget.boardId)
          .collection('comments')
          .where('parentId', isEqualTo: parentId)
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final replies = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: replies.asMap().entries.map((entry) {
            final index = entry.key;
            final reply = entry.value;
            return _buildCommentTile(reply, indent: indent, showDivider: index == 0);
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('댓글'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('boards')
                  .doc(widget.boardId)
                  .collection('comments')
                  .where('parentId', isEqualTo: null)
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView(
                  children: docs.map((doc) => _buildCommentTile(doc)).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
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
                )
              ],
            ),
          ),
        ],
      ),
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
