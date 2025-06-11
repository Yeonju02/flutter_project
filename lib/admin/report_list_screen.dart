import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportListScreen extends StatelessWidget {
  const ReportListScreen({super.key});

  Future<void> markAsResolved(String boardId, String reportId) async {
    await FirebaseFirestore.instance
        .collection('boards')
        .doc(boardId)
        .collection('reports')
        .doc(reportId)
        .update({'isResolved': true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('신고 목록')),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('boards').get(),
        builder: (context, boardSnap) {
          if (!boardSnap.hasData) return const Center(child: CircularProgressIndicator());
          final boardDocs = boardSnap.data!.docs;

          return ListView(
            children: boardDocs.map((boardDoc) {
              final boardId = boardDoc.id;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('boards')
                    .doc(boardId)
                    .collection('reports')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, reportSnap) {
                  if (!reportSnap.hasData || reportSnap.data!.docs.isEmpty) return const SizedBox();

                  final reports = reportSnap.data!.docs;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: reports.map((reportDoc) {
                      final report = reportDoc.data() as Map<String, dynamic>;
                      final isResolved = report['isResolved'] == true;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text('[${report['reason']}] ${report['boardId']}'),
                          subtitle: Text(
                            '신고자: ${report['reporterId']}\n시간: ${report['createdAt']?.toDate() ?? '시간 없음'}',
                          ),
                          trailing: isResolved
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : ElevatedButton(
                            onPressed: () => markAsResolved(boardId, reportDoc.id),
                            child: const Text('해결'),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}