import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routinelogapp/admin/report_list_page.dart';
import 'package:routinelogapp/board/board_detail_screen.dart';
import '../custom/admin_bottom_bar.dart';
import '../main/main_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_product_page.dart';
import 'admin_user_page.dart';

class AdminBoardPage extends StatefulWidget {
  const AdminBoardPage({super.key});

  @override
  State<AdminBoardPage> createState() => _AdminBoardPageState();
}

class _AdminBoardPageState extends State<AdminBoardPage> {
  String _selectedType = '전체';
  final List<String> _types = ['전체', '게시글', '댓글'];
  String _author = '';
  String _title = '';
  DateTimeRange? _selectedRange;
  List<QueryDocumentSnapshot> _fetchedData = [];

  final Color mainColor = const Color(0xFF819CFF); // 통일된 색상
  final OutlineInputBorder borderStyle = OutlineInputBorder(
    borderSide: const BorderSide(color: Color(0xFF819CFF)),
    borderRadius: BorderRadius.circular(12),
  );

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String extractBoardIdFromCommentPath(String path) {
    final parts = path.split('/');
    final boardIndex = parts.indexOf('boards');
    if (boardIndex != -1 && boardIndex + 1 < parts.length) {
      return parts[boardIndex + 1];
    }
    return ''; // fallback
  }

  Future<void> _fetchData() async {
    List<QueryDocumentSnapshot> combinedData = [];

    if (_selectedType == '게시글' || _selectedType == '전체') {
      final boardSnapshot = await FirebaseFirestore.instance.collection('boards').get();

      for (var doc in boardSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        // 삭제된 게시글 제외
        if (data['isDeleted'] == true) continue;

        final matchesDate = _selectedRange == null ||
            (createdAt != null &&
                createdAt.isAfter(_selectedRange!.start.subtract(const Duration(days: 1))) &&
                createdAt.isBefore(_selectedRange!.end.add(const Duration(days: 1))));

        final matchesTitleOnly = _title.isNotEmpty && _author.isEmpty && (data['title']?.toString().contains(_title) ?? false);
        final matchesAuthorOnly = _author.isNotEmpty && _title.isEmpty && (data['nickName']?.toString().contains(_author) ?? false);
        final matchesBoth = _title.isNotEmpty && _author.isNotEmpty &&
            (data['title']?.toString().contains(_title) ?? false) &&
            (data['nickName']?.toString().contains(_author) ?? false);
        final matchesEmpty = _title.isEmpty && _author.isEmpty;

        if (matchesDate && (matchesTitleOnly || matchesAuthorOnly || matchesBoth || matchesEmpty)) {
          combinedData.add(doc);
        }
      }
    }

    if (_selectedType == '댓글' || _selectedType == '전체') {
      final commentSnapshot = await FirebaseFirestore.instance.collectionGroup('comments').get();

      for (var doc in commentSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        final matchesDate = _selectedRange == null ||
            (createdAt != null &&
                createdAt.isAfter(_selectedRange!.start.subtract(const Duration(days: 1))) &&
                createdAt.isBefore(_selectedRange!.end.add(const Duration(days: 1))));

        final matchesAuthorOnly = _author.isNotEmpty && _title.isEmpty && (data['nickName']?.toString().contains(_author) ?? false);
        final matchesBoth = _author.isNotEmpty && _title.isNotEmpty &&
            (data['nickName']?.toString().contains(_author) ?? false);
        final matchesEmpty = _author.isEmpty && _title.isEmpty;

        // 삭제된 게시글에 속한 댓글이면 건너뛴다
        final boardId = data['boardId'];
        if (boardId != null) {
          final parentSnap = await FirebaseFirestore.instance.collection('boards').doc(boardId).get();
          if (!parentSnap.exists || parentSnap.data()?['isDeleted'] == true) {
            continue;
          }
        }

        if (matchesDate && (matchesAuthorOnly || matchesBoth || matchesEmpty)) {
          combinedData.add(doc);
        }
      }
    }

    combinedData.sort((a, b) {
      final aTime = (a['createdAt'] as Timestamp?)?.toDate();
      final bTime = (b['createdAt'] as Timestamp?)?.toDate();
      return bTime?.compareTo(aTime ?? DateTime(0)) ?? 0;
    });

    setState(() {
      _fetchedData = combinedData;
    });
  }

  Future<void> deleteOrphanComments() async {
    final commentSnapshots =
    await FirebaseFirestore.instance.collectionGroup('comments').get();

    for (var commentDoc in commentSnapshots.docs) {
      try {
        final pathSegments = commentDoc.reference.path.split('/');
        final boardIndex = pathSegments.indexOf('boards');
        if (boardIndex == -1 || boardIndex + 1 >= pathSegments.length) continue;

        final boardId = pathSegments[boardIndex + 1];
        final boardDoc = FirebaseFirestore.instance.collection('boards').doc(boardId);
        final boardSnap = await boardDoc.get();

        if (!boardSnap.exists || boardSnap.data()?['isDeleted'] == true) {
          await commentDoc.reference.delete();
          print('삭제된 게시글의 댓글 제거됨: ${commentDoc.id}');
        }
      } catch (e) {
        print('예외 발생: ${commentDoc.id} - $e');
      }
    }

    print('고아 댓글 정리 완료');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: mainColor,
        title: Row(
          children: [
            Image.asset('assets/admin_logo.png', height: 28),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MainPage())),
              child: const Text('Main', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard(),
            const SizedBox(height: 16),
            _buildFilterSection(),
            const SizedBox(height: 16),
            Expanded(child: _buildDataTable()),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportListScreen()));
                    },
                    child: const Text("신고 목록", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await deleteOrphanComments();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("고아 댓글 정리 완료")),
                        );
                      }
                    },
                    child: const Text("고아 댓글 정리", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: 2, // 현재 탭: 게시판
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserAdminPage()));
              break;
            case 1:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardPage()));
              break;
            case 2:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminBoardPage()));
              break;
            case 3:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminProductPage()));
              break;
          }
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      children: [
        // 제목 검색창
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          child: TextField(
            onChanged: (value) => _title = value,
            decoration: InputDecoration(
              hintText: '제목 검색',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF92BBE2)),
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // 작성자 + 타입
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: TextField(
                  onChanged: (value) => _author = value,
                  decoration: InputDecoration(
                    hintText: '작성자 검색',
                    prefixIcon: const Icon(Icons.person, color: Color(0xFF92BBE2)),
                    filled: true,
                    fillColor: const Color(0xFFF7F8FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  hintText: '종류 선택',
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                borderRadius: BorderRadius.circular(10),
                dropdownColor: Colors.white,
                elevation: 8,
                style: const TextStyle(fontSize: 14, color: Colors.black),
                iconEnabledColor: const Color(0xFF819CFF),
                items: _types.map(
                      (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ),
                ).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                    _fetchData();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 날짜 선택 버튼
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF819CFF)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedRange = picked);
                _fetchData();
              }
            },
            child: Text(
              _selectedRange == null
                  ? '날짜 선택'
                  : '${_selectedRange!.start.toString().split(' ')[0]} ~ ${_selectedRange!.end.toString().split(' ')[0]}',
              style: const TextStyle(color: Color(0xFF1A1C34)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF819CFF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _fetchData,
            child: const Text('검색', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FixedColumnWidth(130),
            1: FixedColumnWidth(130),
            2: FixedColumnWidth(130),
          },
          border: TableBorder.symmetric(
            inside: BorderSide(color: mainColor.withOpacity(0.3), width: 0.5),
            outside: BorderSide(color: mainColor.withOpacity(0.5), width: 0.8),
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(color: mainColor.withOpacity(0.1)),
              children: [
                _buildCell('작성자', isHeader: true),
                _buildCell('제목', isHeader: true),
                _buildCell('작성일', isHeader: true),
              ],
            ),
            ..._fetchedData.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final title = data['title'] ?? data['content'] ?? '';
              final nickname = data['nickName'] ?? '익명';
              final boardId = data['boardId'] ?? doc.id;

              // Firestore 문서 경로를 통해 댓글인지 게시글인지 구분
              final isComment = doc.reference.path.contains('/comments/');
              final docPath = doc.reference.path;

              return TableRow(
                decoration: const BoxDecoration(color: Colors.white),
                children: [
                  _buildClickableCell(nickname, boardId, overridePath: isComment ? docPath : null),
                  _buildClickableCell(title, boardId, overridePath: isComment ? docPath : null),
                  _buildClickableCell(createdAt?.toString().split(' ')[0] ?? '-', boardId, overridePath: isComment ? docPath : null),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildClickableCell(String text, String boardId, {String? overridePath}) {
    return InkWell(
      onTap: () {
        final id = overridePath != null ? extractBoardIdFromCommentPath(overridePath) : boardId;
        if (id.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BoardDetailScreen(boardId: id),
            ),
          );
        }
      },
      child: _buildCell(text),
    );
  }

  Widget _buildCell(String text, {bool isHeader = false}) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: Colors.black,
          fontSize: 14,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatCard() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('adminStats').doc('summary').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.data() == null) {
          return const SizedBox();
        }

        final data = snapshot.data!.data()! as Map<String, dynamic>;
        final totalBoard = data['totalBoard'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.article, color: Color(0xFF819CFF)),
              const SizedBox(width: 12),
              Text(
                '전체 게시글 수: $totalBoard개',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}
