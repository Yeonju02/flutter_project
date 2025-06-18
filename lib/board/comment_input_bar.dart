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

  const CommentInputBar({
    super.key,
    required this.boardId,
    this.replyToId,
    this.replyToNickname,
    this.editTargetId,
    this.editInitialContent,
    this.onSubmitted,
  });

  @override
  State<CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<CommentInputBar> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode(); // FocusNode 추가

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    print('CommentInputBar initState 호출됨'); // 추가
    _updateControllerText();
  }

  @override
  void didUpdateWidget(covariant CommentInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('CommentInputBar didUpdateWidget 호출됨'); // 추가
    if (widget.replyToId != oldWidget.replyToId ||
        widget.replyToNickname != oldWidget.replyToNickname ||
        widget.editTargetId != oldWidget.editTargetId ||
        widget.editInitialContent != oldWidget.editInitialContent) {
      print('CommentInputBar 속성 변경 감지, _updateControllerText 호출'); // 추가
      _updateControllerText();
    }
  }

  // 컨트롤러의 텍스트와 선택 영역을 업데이트하는 함수
  void _updateControllerText() {
    String newText = '';
    if (widget.editInitialContent != null) {
      // 수정 모드
      newText = widget.editInitialContent!;
    } else if (widget.replyToNickname != null) {
      // 답글 모드
      newText = '@${widget.replyToNickname} ';
    }

    // 현재 텍스트와 다를 경우에만 업데이트하여 불필요한 렌더링 방지
    if (_controller.text != newText) {
      _controller.text = newText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length), // 커서를 텍스트 끝으로 이동
      );
    }

    // 답글 또는 수정 모드일 때 포커스 요청
    if (widget.replyToId != null || widget.editTargetId != null) {
      _focusNode.requestFocus();
    }
  }

  Future<void> _submitComment() async {
    final content = _controller.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (content.isEmpty || user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final nickName = userDoc['nickName'];
    final commentsRef = FirebaseFirestore.instance.collection('boards').doc(widget.boardId).collection('comments');

    if (widget.editTargetId != null) {
      // 댓글 수정
      await commentsRef.doc(widget.editTargetId).update({
        'content': content,
        'updatedAt': Timestamp.now(),
      });
    } else {
      // 새 댓글 또는 답글 추가
      await commentsRef.add({
        'nickName': nickName,
        'content': content,
        'parentId': widget.replyToId,
        'createdAt': Timestamp.now(),
        'userId': user.uid,
      });
    }

    _controller.clear(); // 입력 필드 비우기
    widget.onSubmitted?.call(); // 콜백 호출
    _focusNode.unfocus(); // 제출 후 키보드 내리기
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose(); // FocusNode 폐기
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                focusNode: _focusNode, // TextField에 FocusNode 할당
                controller: _controller,
                decoration: InputDecoration(
                  hintText: widget.replyToNickname != null
                      ? '@${widget.replyToNickname}에게 답글 달기...'
                      : '댓글을 입력하세요...',
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _submitComment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF92BBE0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text('등록', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}