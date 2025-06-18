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
    '모닝 루틴': ['모닝 저널', '아로마오일'],
    '운동 용품': ['요가매트', '물병', '운동복'],
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
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔵 메인 카테고리 버튼 (무조건 출력)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categoryMap.keys.map((main) {
                          final isSelected = selectedMainCategory == main;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(main),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  selectedMainCategory = main;
                                  selectedSubCategory = '';
                                });
                              },
                              selectedColor: Color(0xFF92BBE2),
                              backgroundColor: Color(0xFFE0E0E0),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 🔹 서브 카테고리 (선택된 메인카테고리에만 등장)
                    if (selectedMainCategory != '전체' && categoryMap[selectedMainCategory]!.isNotEmpty)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFF0F4FA),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: categoryMap[selectedMainCategory]!.map((sub) {
                              final isSelected = selectedSubCategory == sub;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(sub),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      selectedSubCategory = sub;
                                    });
                                  },
                                  selectedColor: Color(0xFF92BBE2),
                                  backgroundColor: Color(0xFFE0E0E0),
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

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

                    // 👉 필터링된 상품 리스트 임시 저장 (각 데이터에 productId 포함)
                    final filtered = allProducts.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      data['productId'] = doc.id; // 🔸 문서 ID 추가
                      final name = data['productName']?.toString() ?? '';
                      final category = data['productCategory'] ?? {};
                      final main = category['main'] ?? '';
                      final sub = category['sub'] ?? '';

                      final matchesMain = selectedMainCategory == '전체' || main == selectedMainCategory;
                      final matchesSub = selectedSubCategory.isEmpty || sub == selectedSubCategory;
                      final matchesSearch = name.contains(searchText);

                      return matchesMain && matchesSub && matchesSearch;
                    }).map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      data['productId'] = doc.id;
                      return data; // 🔄 data만 리스트에 담음
                    }).toList();

                    // ✅ 최초 한 번만 표시하거나 로딩이 끝난 후 교체
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
                          data: data,
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
                  case 0:
                    break; // 현재 페이지
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


class ProductCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  double avgRating = 0.0;
  int reviewCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchRating();
  }

  void _fetchRating() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.data['productId'])
        .collection('reviews')
        .get();

    double totalScore = 0;
    for (var doc in snapshot.docs) {
      totalScore += (doc['score'] ?? 0).toDouble();
    }

    setState(() {
      reviewCount = snapshot.docs.length;
      avgRating = reviewCount > 0 ? totalScore / reviewCount : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final formatter = NumberFormat('#,###');

    final List colors = data['colors'] ?? [];
    final firstColor = colors.isNotEmpty ? Map<String, dynamic>.from(colors[0]) : null;
    final stock = colors.fold<int>(0, (sum, item) {
      final s = item['stock'];
      return sum + (s is int ? s : (s is double ? s.toInt() : 0));
    });
    final isSoldOut = data['isSoldOut'] == true;

    return GestureDetector(
      onTap: isSoldOut ? null : widget.onTap,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text('별점 ${avgRating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 6),
                        const Text('|', style: TextStyle(color: Colors.black54, fontSize: 16)),
                        const SizedBox(width: 6),
                        Text('$stock개 남음', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
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
