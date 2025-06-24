import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routinelogapp/admin/user_detail_page.dart';
import '../custom/admin_bottom_bar.dart';
import '../main/main_page.dart';
import 'admin_board_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_product_page.dart';

class UserAdminPage extends StatefulWidget {
  const UserAdminPage({super.key});

  @override
  State<UserAdminPage> createState() => _UserAdminPageState();
}

class _UserAdminPageState extends State<UserAdminPage> {
  String selectedFilter = '최신순';
  final List<String> filterList = ['최신순', '오래된순', '탈퇴한 회원', 'Admin', 'User'];

  String searchText = '';

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query;

    if (selectedFilter == '탈퇴한 회원') {
      query = FirebaseFirestore.instance
          .collection('users')
          .where('deleted', isEqualTo: true);
    } else if (selectedFilter == '오래된순') {
    query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('joinedAt', descending: false);
    } else if (selectedFilter == 'Admin') {
    query = FirebaseFirestore.instance
        .collection('users')
        .where('status', isEqualTo: 'A');
    } else if (selectedFilter == 'User') {
    query = FirebaseFirestore.instance
        .collection('users')
        .where('status', isEqualTo: 'U');
    } else {
    query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('joinedAt', descending: true);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF819CFF),
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
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildSearchBar(),
          _buildFilterDropdown(),
          SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('에러 발생'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final userId = data['userId']?.toString().toLowerCase() ?? '';
                  return userId.contains(searchText);
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    return _buildUserCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 1:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminDashboardPage()));
              break;
            case 2:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminBoardPage()));
              break;
            case 3:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminProductPage()));
              break;
          }
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchText = value.trim().toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: '검색',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF92BBE2)),
          filled: true,
          fillColor: const Color(0xFFF7F8FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: DropdownButtonHideUnderline(
          child: DropdownButton2<String>(
            value: selectedFilter,
            customButton: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedFilter,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            dropdownStyleData: DropdownStyleData(
              width: 140,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FA),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: filterList.map((filter) {
              return DropdownMenuItem<String>(
                value: filter,
                child: Text(filter, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedFilter = value!;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isDeleted = user['deleted'] == true;
    final isAdmin = user['status'] == 'A';
    final profileImg = user['imgPath'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFA5C8F8),
            backgroundImage:
            profileImg.isNotEmpty ? NetworkImage(profileImg) : null,
            child: profileImg.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['userId'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(user['userEmail'] ?? '', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDeleted ? Colors.transparent : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isDeleted ? '탈퇴' : (isAdmin ? 'Admin' : 'User'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDeleted ? Colors.red : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF819CFF)
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserDetailPage(userData: user),
                ),
              );
            },
            child: const Text('보기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

}
