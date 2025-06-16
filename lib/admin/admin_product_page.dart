import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routinelogapp/admin/admin_product_add.dart';
import '../main/main_page.dart';
import '../custom/admin_bottom_bar.dart';

class AdminProductPage extends StatefulWidget {
  const AdminProductPage({super.key});

  @override
  State<AdminProductPage> createState() => _AdminProductPageState();
}

class _AdminProductPageState extends State<AdminProductPage> {
  String? selectedStatus = 'Status';
  List<QueryDocumentSnapshot> products = [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF819CFF),
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 28),
            const SizedBox(width: 6),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MainPage()));
              },
              child: const Text('Main', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Product name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'Status', child: Text('Status')),
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        selectedStatus = val;
                      });
                    },
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3173F6)),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductPage()));
                },
                child: const Text('Add Product'),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              color: Colors.grey.shade200,
              child: const Row(
                children: [
                  Expanded(flex: 4, child: Text('Product')),
                  Expanded(flex: 2, child: Text('Price')),
                  Expanded(flex: 2, child: Text('Stock')),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index].data() as Map<String, dynamic>;
                  final firstColor = (product['colors'] as List?)?.firstWhere(
                        (e) => e is Map<String, dynamic>,
                    orElse: () => null,
                  ) as Map<String, dynamic>?;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              if (firstColor?['imgPath'] != null)
                                Image.network(
                                  firstColor!['imgPath'],
                                  width: 40,
                                  height: 40,
                                  errorBuilder: (c, o, s) => const Icon(Icons.image_not_supported),
                                )
                              else
                                const Icon(Icons.image, size: 40),
                              const SizedBox(width: 8),
                              Text(product['productName'] ?? ''),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('\$${product['productPrice'] ?? ''}'),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  // TODO: 수정 페이지로 이동
                                },
                                child: const Text('Edit'),
                              ),
                              if (firstColor?['stock'] == 0)
                                const Text('Out of Stock', style: TextStyle(color: Colors.red, fontSize: 12)),
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
          // TODO: 페이지 이동 구현
        },
      ),
    );
  }
}
