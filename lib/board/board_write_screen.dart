import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

class BoardWriteScreen extends StatefulWidget {
  final Map<String, dynamic>? post;

  const BoardWriteScreen({super.key, this.post});

  @override
  State<BoardWriteScreen> createState() => _BoardWriteScreenState();
}

class _BoardWriteScreenState extends State<BoardWriteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _selectedCategory;
  List<XFile> _images = [];
  bool _isUploading = false;

  final List<String> _categories = ['아침 루틴 후기/공유', '수면 관리 후기/공유', '제품/영상 추천'];

  bool get isEditMode => widget.post != null;

  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      _titleController.text = widget.post!['title'] ?? '';
      _contentController.text = widget.post!['content'] ?? '';
      _selectedCategory = widget.post!['boardCategory'];
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _images = picked;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _uploadImagesToStorage(String boardId) async {
    List<Map<String, dynamic>> fileInfoList = [];

    for (int i = 0; i < _images.length; i++) {
      XFile image = _images[i];
      String fileName = const Uuid().v4();
      final ref = FirebaseStorage.instance.ref().child('board_images/$fileName.jpg');
      final uploadTask = await ref.putFile(File(image.path));
      final fileUrl = await uploadTask.ref.getDownloadURL();

      fileInfoList.add({
        'filePath': fileUrl,
        'fileName': fileName,
        'isThumbNail': i == 0,
      });
    }

    return fileInfoList;
  }

  Future<void> _submitBoard() async {
    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 입력하세요')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('사용자 정보가 존재하지 않습니다.');
      }

      final nickName = userDoc.data()?['nickName'] ?? '익명';
      final now = Timestamp.now();

      if (isEditMode) {
        final boardId = widget.post!['boardId'];
        await FirebaseFirestore.instance.collection('boards').doc(boardId).update({
          'title': _titleController.text,
          'content': _contentController.text,
          'boardCategory': _selectedCategory,
          'updatedAt': now,
        });
      } else {
        final boardId = const Uuid().v4();

        await FirebaseFirestore.instance.collection('boards').doc(boardId).set({
          'boardId': boardId,
          'userId': user.uid,
          'nickName': nickName,
          'boardCategory': _selectedCategory,
          'title': _titleController.text,
          'content': _contentController.text,
          'likeCount': 0,
          'createdAt': now,
          'updatedAt': now,
          'isDeleted': false,
        });

        List<Map<String, dynamic>> imageInfoList = await _uploadImagesToStorage(boardId);
        for (var imageData in imageInfoList) {
          await FirebaseFirestore.instance
              .collection('boards')
              .doc(boardId)
              .collection('boardFiles')
              .add(imageData);
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditMode ? '게시글이 수정되었습니다!' : '게시글이 등록되었습니다!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('에러 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('내용 미리보기', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Linkify(
            text: _contentController.text,
            onOpen: (link) async {
              final url = Uri.parse(link.url);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL을 열 수 없습니다')),
                );
              }
            },
            style: const TextStyle(fontSize: 14),
            linkStyle: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? '글 수정' : '글 작성')),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              ))
                  .toList(),
              value: _selectedCategory,
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildPreview(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _images.map((file) {
                return Image.file(
                  File(file.path),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('이미지 추가'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitBoard,
              child: Text(isEditMode ? '수정 완료' : '작성 완료'),
            ),
          ],
        ),
      ),
    );
  }
}
