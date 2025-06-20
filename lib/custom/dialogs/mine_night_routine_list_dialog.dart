import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_mine_night_routine_dialog.dart';

class MineNightRoutineListDialog extends StatefulWidget {
  final TextEditingController titleController;
  final VoidCallback onClose;

  const MineNightRoutineListDialog({
    super.key,
    required this.titleController,
    required this.onClose,
  });

  @override
  State<MineNightRoutineListDialog> createState() => _MineNightRoutineListDialogState();
}

class _MineNightRoutineListDialogState extends State<MineNightRoutineListDialog> {
  List<Map<String, dynamic>> routines = [];

  @override
  void initState() {
    super.initState();
    fetchSavedRoutines();
  }

  Future<void> fetchSavedRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return;
    final userDocId = query.docs.first.id;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userDocId)
        .collection('saved')
        .where('type', isEqualTo: 'night')
        .orderBy('score', descending: true)
        .get();

    setState(() {
      routines = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF182333),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  "나만의 루틴",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                )
              ],
            ),
            const Divider(thickness: 1, color: Colors.white),
            const SizedBox(height: 5),
            Container(
              height: 200,
              child: routines.isEmpty
                  ? const Center(
                child: Text(
                  "등록된 루틴이 없습니다.",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
              )
                  : ListView.builder(
                itemCount: routines.length,
                itemBuilder: (context, index) {
                  final routine = routines[index];
                  final title = routine['title'] ?? '';
                  return RadioListTile(
                    value: title,
                    groupValue: widget.titleController.text,
                    onChanged: (val) {
                      widget.titleController.text = title;
                      widget.onClose();
                    },
                    title: Text(title, style: const TextStyle(color: Colors.white)),
                    activeColor: Colors.white,
                  );
                },
              ),
            ),
            const Divider(thickness: 1, color: Colors.white),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => const AddMineNightRoutineDialog(),
                );
                fetchSavedRoutines();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("나의 밤 루틴 등록하기", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
