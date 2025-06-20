import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddMineRoutineDialog extends StatefulWidget {
  const AddMineRoutineDialog({super.key});

  @override
  State<AddMineRoutineDialog> createState() => _AddMineRoutineDialogState();
}

class _AddMineRoutineDialogState extends State<AddMineRoutineDialog> {
  final TextEditingController _controller = TextEditingController();
  bool isSaving = false;

  Future<void> saveRoutine() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    setState(() {
      isSaving = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;

    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) return;
    final userDocId = userQuery.docs.first.id;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userDocId)
        .collection('saved')
        .add({
      'title': title,
      'type': 'morning',
      'score': 0,
      'scoreCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      Navigator.of(context).pop(); // 다이얼로그 닫기
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "나의 아침 루틴 만들기",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "루틴 제목",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSaving ? null : saveRoutine,
              child: isSaving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text("완료"),
            ),
          ],
        ),
      ),
    );
  }
}
