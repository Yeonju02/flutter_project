import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportListScreen extends StatelessWidget {
  const ReportListScreen({super.key});

  Future<void> deleteBoardCompletely(String boardId) async {
    final boardRef = FirebaseFirestore.instance.collection('boards').doc(boardId);

    // 하위 컬렉션 삭제 (신고 reports는 삭제 x)
    Future<void> deleteSubCollection(String subPath) async {
      final subCollection = await boardRef.collection(subPath).get();
      for (var doc in subCollection.docs) {
        await doc.reference.delete();
      }
    }

    await deleteSubCollection('comments');
    await deleteSubCollection('likes');
    // await deleteSubCollection('reports');

    await boardRef.delete(); // 게시글 문서 삭제
  }

  Future<void> markAsResolved(String boardId, String reportId) async {
    final resolvedAt = Timestamp.now();

    // 게시글만 삭제
    await deleteBoardCompletely(boardId);

    // 신고 문서 상태만 업데이트 (삭제 X)
    await FirebaseFirestore.instance
        .collection('boards')
        .doc(boardId)
        .collection('reports')
        .doc(reportId)
        .update({
      'isResolved': true,
      'resolvedAt': resolvedAt,
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
                  if (!reportSnap.hasData) return const SizedBox();

                  final now = DateTime.now();
                  final List<QueryDocumentSnapshot> reportsToShow = [];

                  for (var doc in reportSnap.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final isResolved = data['isResolved'] == true;
                    final resolvedAt = data['resolvedAt'];

                    // 삭제 조건: 해결된 지 24시간 지난 경우 → 삭제만 하고 continue 하지 않음
                    if (isResolved && resolvedAt is Timestamp) {
                      final resolvedTime = resolvedAt.toDate();
                      if (now.difference(resolvedTime).inHours >= 24) {
                        doc.reference.delete(); // 삭제만 수행
                      }
                    }
                    reportsToShow.add(doc);
                  }

                  if (reportsToShow.isEmpty) return const SizedBox();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: reportsToShow.map((reportDoc) {
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
                              ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(height: 4),
                              Text('해결됨', style: TextStyle(fontSize: 10, color: Colors.green)),
                            ],
                          )
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
