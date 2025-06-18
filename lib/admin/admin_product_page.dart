import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routinelogapp/admin/admin_product_add.dart';
import '../main/main_page.dart';
import '../custom/admin_bottom_bar.dart';
import 'admin_product_edit.dart';
import 'admin_user_page.dart';

// 기존 import 유지
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
    '모닝 루틴': ['모닝 저널', '아로마오일'],
    '수면 용품': ['수면 안대', '숙면베개', '무드등'],
    '운동 용품': ['요가매트', '물병', '운동복'],
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
                          decoration: _dropdownInputDecoration('대분류'),
                          value: selectedMainCategory ?? '전체',
                          items: categoryMap.keys
                              .map((main) => DropdownMenuItem<String>(
                            value: main,
                            child: Text(main, overflow: TextOverflow.visible),
                          ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedMainCategory = val;
                              selectedSubCategory = null;
                            });
                          },
                          buttonStyleData: const ButtonStyleData(
                            height: 28,
                            padding: EdgeInsets.symmetric(horizontal: 14),
                          ),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 250,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 소분류
                      Expanded(
                        child: DropdownButtonFormField2<String>(
                          isExpanded: true,
                          decoration: _dropdownInputDecoration('소분류'),
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
                            height: 28,
                            padding: EdgeInsets.symmetric(horizontal: 14),
                          ),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 250,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FA),
                              borderRadius: BorderRadius.circular(12),
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
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductPage()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA5C8F8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  Expanded(flex: 4, child: Text('상품명', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('가격', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('총 재고', style: TextStyle(fontWeight: FontWeight.bold))),
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
                              Text(product['productName'] ?? ''),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('\₩${product['productPrice']}'),
                        ),
                        Expanded(
                          flex: 2,
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
                                  );
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
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserAdminPage()),
            );
          }
        },
      ),
    );
  }
}
