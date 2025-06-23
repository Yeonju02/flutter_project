import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../board/board_main_screen.dart';
import '../main/main_page.dart';
import '../mypage/myPage_main.dart';
import '../notification/notification_screen.dart';
import 'cart.dart';
import 'product_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../custom/bottom_nav_bar.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class ShopMainPage extends StatefulWidget {
  const ShopMainPage({super.key});
  @override
  State<ShopMainPage> createState() => _ShopMainPageState();
}

class _ShopMainPageState extends State<ShopMainPage> {
  String selectedMainCategory = '전체';
  String selectedSubCategory = '';
  String searchText = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _displayedProducts = [];
  int _currentIndex = 0;

  // 예시 카테고리 맵
  final Map<String, List<String>> categoryMap = {
    '전체': [],
    '수면 용품': ['수면 안대', '숙면베개', '무드등'],
    '생활 용품': ['다이어리', '디퓨저', '마스크팩'],
    '운동 용품': ['운동기구', '물병', '운동복'],
  };

  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor : Colors.white,
      appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('쇼핑몰', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 검색창
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  onChanged: (value) {
                    searchText = value;
                  },
                  onSubmitted: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: '검색',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF92BBE2),),
                    filled: true,
                    fillColor: Color(0xFFF7F8FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // 메인/서브 카테고리 선택 영역
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categoryMap.keys.map((cat) {
                      final isSelected = selectedMainCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(showCheckmark: false,
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              selectedMainCategory = cat;
                              selectedSubCategory = '';
                            });
                          },
                          selectedColor: const Color(0xFF92BBE2),
                          backgroundColor: const Color(0xFFE0E0E0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF92BBE2) : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              if (selectedMainCategory != '전체' && categoryMap[selectedMainCategory]!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categoryMap[selectedMainCategory]!.map((sub) {
                        final isSelected = selectedSubCategory == sub;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(showCheckmark: false,
                            label: Text(
                              sub,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                selectedSubCategory = sub;
                              });
                            },
                            selectedColor: const Color(0xFF92BBE2),
                            backgroundColor: const Color(0xFFE0E0E0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF92BBE2) : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              // 상품 리스트
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allProducts = snapshot.data!.docs;

                    final filtered = allProducts.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {
                        ...data,
                        'productId': doc.id,
                      };
                    }).where((data) {
                      final name = data['productName']?.toString() ?? '';
                      final category = data['productCategory'] ?? {};
                      final main = category['main'] ?? '';
                      final sub = category['sub'] ?? '';

                      final matchesMain = selectedMainCategory == '전체' || main == selectedMainCategory;
                      final matchesSub = selectedSubCategory.isEmpty || sub == selectedSubCategory;
                      final matchesSearch = name.contains(searchText);

                      return matchesMain && matchesSub && matchesSearch;
                    }).toList();

                    if (!_isLoading) {
                      _displayedProducts = filtered;
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.9,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _displayedProducts.length,
                      itemBuilder: (context, index) {
                        final data = _displayedProducts[index];
                        return ProductCard(
                          key: ValueKey(data['productId']),
                          data: data,
                          productId: data['productId'],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ProductDetailPage(data: data)),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: BottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });

                switch (index) {
                  case 1:
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => BoardMainScreen()));
                    break;
                  case 2:
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => MainPage()));
                    break;
                  case 3:
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => NotificationScreen()));
                    break;
                  case 4:
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => MyPageMain()));
                    break;
                }
              },
            ),
          ),
          Positioned(
            bottom: 130,
            right: 20,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId!)
                  .collection('cart')
                  .snapshots(),
              builder: (context, snapshot) {
                int cartCount = snapshot.data?.docs.length ?? 0;
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CartPage(userId: userId!)),
                        );
                      },
                      backgroundColor: const Color(0xFF92BBE2),
                      child: const Icon(Icons.shopping_cart, color: Colors.white),
                    ),
                    if (cartCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text(
                            '$cartCount',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),

    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String productId;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.data,
    required this.productId,
    required this.onTap,
  });

  Future<Map<String, dynamic>> _fetchRating() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .get();

    double totalScore = 0;
    for (var doc in snapshot.docs) {
      final score = doc['score'];
      if (score != null) {
        totalScore += (score as num).toDouble();
      }
    }

    return {
      'avg': snapshot.docs.isNotEmpty ? totalScore / snapshot.docs.length : 0.0,
      'count': snapshot.docs.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final List colors = data['colors'] ?? [];
    final firstColor = colors.isNotEmpty ? Map<String, dynamic>.from(colors[0]) : null;
    final stock = colors.fold<int>(0, (sum, item) {
      final s = item['stock'];
      return sum + (s is int ? s : (s is double ? s.toInt() : 0));
    });
    final isSoldOut = data['isSoldOut'] == true;

    return GestureDetector(
      onTap: isSoldOut ? null : onTap,
      child: Opacity(
        opacity: isSoldOut ? 0.5 : 1.0,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이미지
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      image: DecorationImage(
                        image: firstColor != null && firstColor['imgPath'] != null
                            ? NetworkImage(firstColor['imgPath'])
                            : const AssetImage('assets/no_image.png') as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      data['productName'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _fetchRating(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('별점 로딩중...', style: TextStyle(fontSize: 13)),
                        );
                      }
                      final avg = snapshot.data!['avg'] as double;
                      final count = snapshot.data!['count'] as int;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            Text('별점 ${avg.toStringAsFixed(1)}', style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 6),
                            const Text('|', style: TextStyle(color: Colors.black54, fontSize: 16)),
                            const SizedBox(width: 6),
                            Text('$stock개 남음', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      '${formatter.format(data['productPrice'])}원',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            if (isSoldOut)
              Positioned.fill(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '품절',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
