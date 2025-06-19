import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentInputBar extends StatefulWidget {
  final String boardId;
  final String? replyToId;
  final String? replyToNickname;
  final String? editTargetId;
  final String? editInitialContent;
  final VoidCallback? onSubmitted;
  final VoidCallback? onCancelReply;

  const CommentInputBar({
    super.key,
    required this.boardId,
    this.replyToId,
    this.replyToNickname,
    this.editTargetId,
    this.editInitialContent,
    this.onSubmitted,
    this.onCancelReply,
  });

  @override
  State<CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<CommentInputBar> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _updateControllerText();
  }

  @override
  void didUpdateWidget(covariant CommentInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replyToId != oldWidget.replyToId ||
        widget.replyToNickname != oldWidget.replyToNickname ||
        widget.editTargetId != oldWidget.editTargetId ||
        widget.editInitialContent != oldWidget.editInitialContent) {
      _updateControllerText();
    }
  }

  void _updateControllerText() {
    String newText = '';
    if (widget.editInitialContent != null) {
      newText = widget.editInitialContent!;
    } else if (widget.replyToNickname != null) {
      newText = '@${widget.replyToNickname} ';
    }

    if (_controller.text != newText) {
      _controller.text = newText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }

    if (widget.replyToId != null || widget.editTargetId != null) {
      _focusNode.requestFocus();
    }
  }

  Future<void> _submitComment() async {
    final content = _controller.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (content.isEmpty || user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final nickName = userDoc['nickName'] ?? '';
    final imgPath = userDoc['imgPath'] ?? '';
    final commentsRef = FirebaseFirestore.instance.collection('boards').doc(widget.boardId).collection('comments');

    if (widget.editTargetId != null) {
      await commentsRef.doc(widget.editTargetId).update({
        'content': content,
        'updatedAt': Timestamp.now(),
      });
    } else {
      final newComment = await commentsRef.add({
        'nickName': nickName,
        'content': content,
        'parentId': widget.replyToId,
        'createdAt': Timestamp.now(),
        'userId': user.uid,
      });

      if (widget.replyToId != null) {
        final parentCommentSnap = await commentsRef.doc(widget.replyToId!).get();
        final parentData = parentCommentSnap.data() as Map<String, dynamic>?;
        final receiverId = parentData?['userId'];

        if (receiverId != null && receiverId != user.uid) {
          final notiSettingSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(receiverId)
              .collection('notiSettings')
              .doc('main')
              .get();
          final settings = notiSettingSnap.data();
          final isEnabled = settings?['comment'] ?? true;

          if (isEnabled) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(receiverId)
                .collection('notifications')
                .add({
              'notiType': 'comment',
              'notiMsg': '$nickName님이 회원님의 댓글에 답글을 남겼습니다.',
              'boardId': widget.boardId,
              'commentId': newComment.id,
              'createdAt': Timestamp.now(),
              'isRead': false,
              'notiNick': nickName,
              'notiImg': imgPath,
            });
          }
        }
      } else {
        final boardSnap = await FirebaseFirestore.instance.collection('boards').doc(widget.boardId).get();
        final boardData = boardSnap.data() as Map<String, dynamic>?;
        final boardOwnerId = boardData?['userId'];

        if (boardOwnerId != null && boardOwnerId != user.uid) {
          final notiSettingSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(boardOwnerId)
              .collection('notiSettings')
              .doc('main')
              .get();
          final settings = notiSettingSnap.data();
          final isEnabled = settings?['comment'] ?? true;

          if (isEnabled) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(boardOwnerId)
                .collection('notifications')
                .add({
              'notiType': 'comment',
              'notiMsg': '$nickName님이 회원님의 게시글에 댓글을 남겼습니다.',
              'boardId': widget.boardId,
              'commentId': newComment.id,
              'createdAt': Timestamp.now(),
              'isRead': false,
              'notiNick': nickName,
              'notiImg': imgPath,
            });
          }
        }
      }
    }

    _controller.clear();
    widget.onSubmitted?.call();
    widget.onCancelReply?.call();
    _focusNode.unfocus();
  }

  void _cancelReply() {
    _controller.clear();
    widget.onCancelReply?.call();
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.replyToNickname != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('@${widget.replyToNickname}에게 답글 중',
                      style: const TextStyle(color: Colors.black87)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _cancelReply,
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: widget.replyToNickname != null
                          ? '@${widget.replyToNickname}에게 답글 달기...'
                          : '댓글을 입력하세요...',
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFF92BBE0),
                          width: 2.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFF92BBE0),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF92BBE0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('등록', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
