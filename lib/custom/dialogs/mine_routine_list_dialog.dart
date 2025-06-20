import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_mine_routine_dialog.dart';

class MineRoutineListDialog extends StatefulWidget {
  final TextEditingController titleController;
  final VoidCallback onClose;

  const MineRoutineListDialog({
    super.key,
    required this.titleController,
    required this.onClose,
  });

  @override
  State<MineRoutineListDialog> createState() => _MineRoutineListDialogState();
}

class _MineRoutineListDialogState extends State<MineRoutineListDialog> {
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
        .where('type', isEqualTo: 'morning')
        .orderBy('score', descending: true)
        .get();

    setState(() {
      routines = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text("나만의 루틴", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                )
              ],
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 5),
            Container(
              height: 200,
              child: routines.isEmpty
                  ? const Center(
                child: Text(
                  "등록된 루틴이 없습니다.",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                    title: Text(title),
                  );
                },
              ),
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => const AddMineRoutineDialog(),
                );
                fetchSavedRoutines();
              },
              icon: const Icon(Icons.add),
              label: const Text("나의 아침 루틴 등록하기"),
            ),

          ],
        ),
      ),
    );
  }
}
