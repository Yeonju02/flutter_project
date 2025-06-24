import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routinelogapp/board/board_detail_screen.dart';

class ReportListScreen extends StatelessWidget {
  const ReportListScreen({super.key});

  Future<void> deleteBoardCompletely(String boardId) async {
    final boardRef = FirebaseFirestore.instance.collection('boards').doc(boardId);

    Future<void> deleteSubCollection(String subPath) async {
      final subCollection = await boardRef.collection(subPath).get();
      for (var doc in subCollection.docs) {
        await doc.reference.delete();
      }
    }

    await deleteSubCollection('comments');
    await deleteSubCollection('likes');
    await boardRef.delete();
  }

  Future<void> markAsResolved(String boardId, String reportId) async {
    final resolvedAt = Timestamp.now();

    await FirebaseFirestore.instance
        .collection('boards')
        .doc(boardId)
        .update({'isDeleted': true});

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
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('신고', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFFF5F6F8),
        elevation: 0,
        foregroundColor: const Color(0xFF4B4B4B),
      ),
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
                  final reportsToShow = reportSnap.data!.docs;
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
                      final boardIdFromReport = report['boardId'];
                      final reporterId = report['reporterId'];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('boards').doc(boardIdFromReport).get(),
                        builder: (context, boardSnapshot) {
                          final title = (boardSnapshot.hasData && boardSnapshot.data != null && boardSnapshot.data!.exists)
                              ? (boardSnapshot.data!.data() as Map<String, dynamic>)['title'] ?? '제목 없음'
                              : '제목 불러오는 중...';

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(reporterId).get(),
                            builder: (context, userSnapshot) {
                              String nick = '신고자: $reporterId (정보 없음)';
                              if (userSnapshot.hasData &&
                                  userSnapshot.data != null &&
                                  userSnapshot.data!.exists) {
                                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                final userIdText = userData['userId'] ?? '알 수 없음';
                                nick = '신고자: $userIdText';
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                color: const Color(0xFFF5F6F8),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BoardDetailScreen(boardId: boardIdFromReport),
                                      ),
                                    );
                                  },
                                  title: Text(
                                    '[${report['reason']}] $title',
                                    style: const TextStyle(color: Color(0xFF4B4B4B)),
                                  ),
                                  subtitle: Text(
                                    '$nick\n시간: $createdAtText',
                                    style: const TextStyle(color: Color(0xFF4B4B4B)),
                                  ),
                                  trailing: isResolved
                                      ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.check_circle, color: Color(0xFF4B4B4B)),
                                      SizedBox(height: 4),
                                      Text('삭제됨', style: TextStyle(fontSize: 10, color: Color(0xFF4B4B4B))),
                                    ],
                                  )
                                      : ElevatedButton(
                                    onPressed: () => markAsResolved(boardId, reportDoc.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF819CFF), // 버튼 색
                                    ),
                                    child: const Text('삭제', style: TextStyle(color: Colors.white),),
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          );
                        },
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
