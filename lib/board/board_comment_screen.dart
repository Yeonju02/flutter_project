import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'comment_list.dart';
import 'comment_input_bar.dart';

class CommentScreen extends StatefulWidget {
  final String boardId;
  const CommentScreen({super.key, required this.boardId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  String myNickName = '';
  String? _replyToId;
  String? _replyToNickname;
  String? _editTargetId;
  String? _editInitialContent;

  @override
  void initState() {
    super.initState();
    _loadNickName();
  }

  Future<void> _loadNickName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    setState(() {
      myNickName = userDoc.data()?['nickName'] ?? '';
    });
  }

  void _onReplyTargetChanged(String commentId, String nickName) {
    setState(() {
      _replyToId = commentId;
      _replyToNickname = nickName;
      _editTargetId = null;
      _editInitialContent = null;
    });
  }

  void _onEdit(String commentId, String content) {
    setState(() {
      _editTargetId = commentId;
      _editInitialContent = content;
      _replyToId = null;
      _replyToNickname = null;
    });
  }

  void _onSubmitDone() {
    setState(() {
      _replyToId = null;
      _replyToNickname = null;
      _editTargetId = null;
      _editInitialContent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CommentList(
            boardId: widget.boardId,
            myNickName: myNickName,
            onReplyTargetChanged: _onReplyTargetChanged,
            onEdit: _onEdit,
          ),
        ),
        CommentInputBar(
          boardId: widget.boardId,
          replyToId: _replyToId,
          replyToNickname: _replyToNickname,
          editTargetId: _editTargetId,
          editInitialContent: _editInitialContent,
          onSubmitted: _onSubmitDone,
        )
      ],
    );
  }
}
