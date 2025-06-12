import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../recommend_routine_box.dart';

class RecommendRoutineList extends StatelessWidget {
  final TextEditingController titleController;
  final VoidCallback onClose;

  const RecommendRoutineList({
    super.key,
    required this.titleController,
    required this.onClose,
  });

  Future<List<Map<String, dynamic>>> fetchMorningRoutines() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('routines')
        .where('type', isEqualTo: 'morning')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '추천 아침 루틴',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchMorningRoutines(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('추천 루틴이 없습니다.'));
                  }

                  final routines = snapshot.data!;
                  return ListView.builder(
                    itemCount: routines.length,
                    itemBuilder: (context, index) {
                      final item = routines[index];
                      final title = item['title'] ?? '';
                      final score = (item['score'] ?? 0).toDouble();

                      return RecommendRoutineBox(
                        title: title,
                        score: score,
                        onApply: () {
                          titleController.text = title;
                          onClose(); // 다이얼로그 닫기
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
