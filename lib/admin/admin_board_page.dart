import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routinelogapp/admin/report_list_page.dart';
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

  Future<void> _fetchData() async {
    List<QueryDocumentSnapshot> combinedData = [];

    if (_selectedType == '게시글' || _selectedType == '전체') {
      final boardSnapshot = await FirebaseFirestore.instance.collection('boards').get();

      for (var doc in boardSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

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

  Future<void> _deleteItem(String id, bool isBoard) async {
    if (isBoard) {
      await FirebaseFirestore.instance.collection('boards').doc(id).update({'isDeleted': true});
    } else {
      await FirebaseFirestore.instance.doc(id).delete();
    }
    _fetchData();
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
            Image.asset('assets/logo.png', height: 28),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportListScreen()));
              },
              child: const Text("신고 목록", style: TextStyle(color: Colors.white)),
            )
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
        TextField(
          decoration: InputDecoration(
            labelText: '제목',
            filled: true,
            fillColor: const Color(0xFFF0F4FA),
            border: borderStyle,
            focusedBorder: borderStyle,
          ),
          onChanged: (value) => _title = value,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: '작성자',
                  filled: true,
                  fillColor: const Color(0xFFF0F4FA),
                  border: borderStyle,
                  focusedBorder: borderStyle,
                ),
                onChanged: (value) => _author = value,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: '종류',
                  filled: true,
                  fillColor: const Color(0xFFF0F4FA),
                  border: borderStyle,
                  focusedBorder: borderStyle,
                ),
                items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) => setState(() {
                  _selectedType = value!;
                  _fetchData();
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: mainColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              backgroundColor: mainColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(mainColor.withOpacity(0.1)),
          border: TableBorder.all(width: 0.5, color: mainColor),
          columns: const [
            DataColumn(label: Text('작성자')),
            DataColumn(label: Text('제목')),
            DataColumn(label: Text('작성일')),
            DataColumn(label: Text('상태')),
            DataColumn(label: Text('관리')),
          ],
          rows: _fetchedData.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            return DataRow(cells: [
              DataCell(Text(data['nickName'] ?? '익명')),
              DataCell(Text(data['title'] ?? data['content'] ?? '')),
              DataCell(Text(createdAt != null ? createdAt.toString().split(' ')[0] : '-')),
              DataCell(Text(data['isDeleted'] == true ? '삭제됨' : '정상')),
              DataCell(IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteItem(doc.reference.path.split('/').last, data.containsKey('title')),
              )),
            ]);
          }).toList(),
        ),
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
