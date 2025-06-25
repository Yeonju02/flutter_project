import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routinelogapp/admin/admin_product_add.dart';
import '../main/main_page.dart';
import '../custom/admin_bottom_bar.dart';
import 'admin_board_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_product_edit.dart';
import 'admin_user_page.dart';

class AdminProductPage extends StatefulWidget {
  const AdminProductPage({super.key});

  @override
  State<AdminProductPage> createState() => _AdminProductPageState();
}

class _AdminProductPageState extends State<AdminProductPage> {
  List<QueryDocumentSnapshot> products = [];
  String? selectedMainCategory;
  String? selectedSubCategory;

  final Map<String, List<String>> categoryMap = {
    '전체': [],
    '수면 용품': ['수면 안대', '숙면베개', '무드등'],
    '생활 용품': ['다이어리', '디퓨저', '마스크팩'],
    '운동 용품': ['운동기구', '물병', '운동복'],
  };

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    setState(() {
      products = snapshot.docs;
    });
  }

  InputDecoration _dropdownInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF0F4FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = products.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final category = data['productCategory'] ?? {};
      final main = category['main'];
      final sub = category['sub'];
      final matchMain = selectedMainCategory == null || selectedMainCategory == '전체' || main == selectedMainCategory;
      final matchSub = selectedSubCategory == null || sub == selectedSubCategory;
      return matchMain && matchSub;
    }).toList();

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
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField2<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: '대분류',
                            filled: true,
                            fillColor: const Color(0xFFF7F8FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          value: selectedMainCategory ?? '전체',
                          items: categoryMap.keys.map((main) => DropdownMenuItem<String>(
                            value: main,
                            child: Text(main, overflow: TextOverflow.visible),
                          )).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedMainCategory = val;
                              selectedSubCategory = null;
                            });
                          },
                          buttonStyleData: const ButtonStyleData(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            height: 30,
                          ),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 250,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 소분류
                      Expanded(
                        child: DropdownButtonFormField2<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: '소분류',
                            filled: true,
                            fillColor: const Color(0xFFF7F8FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          value: selectedSubCategory,
                          items: (selectedMainCategory != null &&
                              selectedMainCategory != '전체' &&
                              categoryMap[selectedMainCategory]!.isNotEmpty)
                              ? categoryMap[selectedMainCategory]!
                              .map((sub) => DropdownMenuItem<String>(
                            value: sub,
                            child: Text(sub, overflow: TextOverflow.visible),
                          ))
                              .toList()
                              : [],
                          onChanged: (val) {
                            setState(() {
                              selectedSubCategory = val;
                            });
                          },
                          buttonStyleData: const ButtonStyleData(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            height: 30,
                          ),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 250,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddProductPage()),
                      ).then((_) {
                        // 상품 추가 후 뒤로가기 눌렀을 때 상품 리스트 다시 불러오기
                        _fetchProducts();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF819CFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('상품 추가', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 30),
                  Expanded(flex: 4, child: Text('상품명', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('가격', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('총 재고', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final doc = filteredProducts[index];
                  final product = doc.data() as Map<String, dynamic>;
                  final colors = product['colors'] as List<dynamic>? ?? [];

                  final firstImg = colors.firstWhere(
                        (e) => e is Map && e['imgPath'] != null,
                    orElse: () => null,
                  );

                  final totalStock = colors.fold<int>(0, (sum, c) {
                    final rawStock = c['stock'];
                    final stock = (rawStock is int)
                        ? rawStock
                        : int.tryParse(rawStock.toString()) ?? 0;
                    return sum + stock;
                  });

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              if (firstImg != null)
                                Image.network(firstImg['imgPath'], width: 40, height: 40)
                              else
                                const Icon(Icons.image, size: 40),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  product['productName'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                              '\₩${product['productPrice']}',
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('$totalStock개'),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditProductPage(doc: doc),
                                    ),
                                  ).then((_) {
                                    _fetchProducts();
                                  });
                                },
                                child: const Text('수정'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: 3, 
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UserAdminPage()));
              break;
            case 1:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminDashboardPage()));
              break;
            case 2:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminBoardPage()));
              break;
          }
        },
      ),
    );
  }
}
