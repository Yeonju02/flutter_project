import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'cart.dart';
import 'product_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<DocumentSnapshot> _displayedProducts = [];
  String _pendingMainCategory = '';
  String _pendingSubCategory = '';

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
      appBar: AppBar(title: const Text('')),
      body: Stack(
        children: [
          Column(
            children: [
              // 검색창
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: '검색',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // 메인/서브 카테고리 선택
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 메인 카테고리 드롭다운 (왼쪽)
                    DropdownButton<String>(
                      value: categoryMap.containsKey(selectedMainCategory)
                          ? selectedMainCategory
                          : categoryMap.keys.first,
                      items: categoryMap.keys.map((main) {
                        return DropdownMenuItem(
                          value: main,
                          child: Text(main),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null && categoryMap.containsKey(value)) {
                          setState(() {
                            _isLoading = true;
                            _pendingMainCategory = value;
                            _pendingSubCategory = '';
                          });
                          Future.delayed(const Duration(milliseconds: 700), () {
                            setState(() {
                              selectedMainCategory = _pendingMainCategory;
                              selectedSubCategory = _pendingSubCategory;
                              _isLoading = false;
                            });
                          });
                        }
                      },
                    ),

                    const SizedBox(width: 10),

                    // 하위 카테고리 버튼들 (오른쪽)
                    if (selectedMainCategory != '전체' && categoryMap[selectedMainCategory]!.isNotEmpty)
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: categoryMap[selectedMainCategory]!.map((sub) {
                              final isSelected = selectedSubCategory == sub;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLoading = true;
                                      _pendingSubCategory = sub;
                                    });

                                    Future.delayed(const Duration(milliseconds: 700), () {
                                      setState(() {
                                        selectedSubCategory = _pendingSubCategory;
                                        _isLoading = false;
                                      });
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected ? Colors.black : Colors.grey[300],
                                    foregroundColor: isSelected ? Colors.white : Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: const Size(0, 36),
                                  ),
                                  child: Text(sub),
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

                    // 모든 상품 받아오기
                    final allProducts = snapshot.data!.docs;

                    // 👉 필터링된 상품 리스트 임시 저장
                    final filtered = allProducts.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['productName']?.toString() ?? '';
                      final category = data['productCategory'] ?? {};
                      final main = category['main'] ?? '';
                      final sub = category['sub'] ?? '';

                      final matchesMain = selectedMainCategory == '전체' || main == selectedMainCategory;
                      final matchesSub = selectedSubCategory.isEmpty || sub == selectedSubCategory;
                      final matchesSearch = name.contains(searchText);

                      return matchesMain && matchesSub && matchesSearch;
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
                        final data = _displayedProducts[index].data() as Map<String, dynamic>;
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
        ],
      ),

      // 장바구니 버튼
      floatingActionButton: StreamBuilder<QuerySnapshot>(
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
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.shopping_cart, color: Colors.black),
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

      // 하단 네비게이션 바
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: '쇼핑'),
          BottomNavigationBarItem(icon: Icon(Icons.check_box), label: '루틴'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: '알림'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '마이'),
        ],
        onTap: (index) {
          // 필요시 화면 이동 추가
        },
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
    final stock = data['stock'] ?? 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[100],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 이미지 + +버튼
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    image: DecorationImage(
                      image: AssetImage(data['imgPath']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),

            // 상품명
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                data['productName'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            // 별점 + 재고 표시
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  Text(
                    '별점 ${avgRating.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 6),
                  const Text('|', style: TextStyle(color: Colors.black54, fontSize: 16)),
                  const SizedBox(width: 6),
                  Text('$stock개 남음', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),

            // 가격
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
    );
  }
}
