import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportListScreen extends StatelessWidget {
  const ReportListScreen({super.key});

  Future<void> deleteBoardCompletely(String boardId) async {
    final boardRef = FirebaseFirestore.instance.collection('boards').doc(boardId);

    // 1. 하위 컬렉션 삭제 함수
    Future<void> deleteSubCollection(String subPath) async {
      final subCollection = await boardRef.collection(subPath).get();
      for (var doc in subCollection.docs) {
        await doc.reference.delete();
      }
    }

    // 2. 하위 컬렉션 삭제
    await deleteSubCollection('comments');
    await deleteSubCollection('likes');
    await deleteSubCollection('reports');

    // 3. 게시글 문서 삭제
    await boardRef.delete();
  }

  Future<void> markAsResolved(String boardId, String reportId) async {
    // 게시글 완전 삭제
    await deleteBoardCompletely(boardId);

    // 해결 표시 남기기 (Firestore에서 report 삭제 대신 상태 업데이트)
    final resolvedAt = Timestamp.now();
    await FirebaseFirestore.instance
        .collection('resolvedReports')
        .doc(reportId)
        .set({
      'boardId': boardId,
      'reportId': reportId,
      'resolvedAt': resolvedAt,
      'status': 'resolved',
    });
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
                      final createdAt = report['createdAt'];
                      final createdAtText = (createdAt is Timestamp)
                          ? createdAt.toDate().toString()
                          : '시간 없음';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text('[${report['reason']}] ${report['boardId']}'),
                          subtitle: Text(
                            '신고자: ${report['reporterId']}\n시간: $createdAtText',
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
