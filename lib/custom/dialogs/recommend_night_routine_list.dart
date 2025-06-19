import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../recommend_night_routine_box.dart';

class RecommendNightRoutineList extends StatelessWidget {
  final TextEditingController titleController;
  final VoidCallback onClose;

  const RecommendNightRoutineList({
    super.key,
    required this.titleController,
    required this.onClose,
  });

  Future<List<Map<String, dynamic>>> fetchNightRoutines() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('routines')
        .where('type', isEqualTo: 'night')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1C33), Color(0xFF2E2F42)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '추천 밤 루틴',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchNightRoutines(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('추천 루틴이 없습니다.', style: TextStyle(color: Colors.white70)),
                    );
                  }

                  final routines = snapshot.data!;
                  return ListView.builder(
                    itemCount: routines.length,
                    itemBuilder: (context, index) {
                      final item = routines[index];
                      final title = item['title'] ?? '';
                      final score = (item['score'] ?? 0).toDouble();

                      return RecommendNightRoutineBox(
                        title: title,
                        score: score,
                        onApply: () {
                          titleController.text = title;
                          onClose();
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
