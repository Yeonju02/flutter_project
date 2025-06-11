import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CartPage extends StatefulWidget {
  final String userId;
  const CartPage({super.key, required this.userId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Map<String, int> quantities = {};
  Map<String, bool> selected = {};
  final formatter = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('cart')
        .orderBy('addedAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('장바구니'),
        leading: const BackButton(),
        actions: [
          TextButton(
            onPressed: () {
              final allSelected = selected.values.every((e) => e);
              setState(() {
                for (var key in selected.keys) {
                  selected[key] = !allSelected;
                }
              });
            },
            child: const Text('전체 선택'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: cartRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('장바구니가 비어 있습니다'));

          for (var doc in docs) {
            final id = doc.id;
            quantities[id] ??= 1;
            selected[id] ??= true;
          }

          final selectedDocs = docs.where((doc) => selected[doc.id] == true).toList();
          final total = selectedDocs.fold<int>(
            0,
                (sum, doc) =>
            sum + (doc['productPrice'] as int) * (quantities[doc.id] ?? 1),
          );

          return Column(
            children: [
              Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final docId = doc.id;
                      final quantity = quantities[docId]!;
                      final isSelected = selected[docId]!;

                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 체크박스 (이미지 위)
                            Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (val) {
                                    setState(() {
                                      selected[docId] = val ?? false;
                                    });
                                  },
                                ),
                              ],
                            ),

                            // 이미지 + 삭제버튼
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    data['thumbNail'],
                                    width: double.infinity,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () async {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(widget.userId)
                                          .collection('cart')
                                          .doc(docId)
                                          .delete();
                                      setState(() {
                                        quantities.remove(docId);
                                        selected.remove(docId);
                                      });
                                    },
                                    child: const CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.black54,
                                      child: Icon(Icons.remove, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            Text(
                              data['productName'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('${formatter.format(data['productPrice'])}원'),
                            const SizedBox(height: 4),

                            // 수량 조절
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      if (quantities[docId]! > 1) {
                                        quantities[docId] = quantities[docId]! - 1;
                                      }
                                    });
                                  },
                                ),
                                Text('$quantity'),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      quantities[docId] = quantities[docId]! + 1;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ),

              // 하단 결제 요약
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('총 ${selectedDocs.length}개 주문금액\n${formatter.format(total)}원',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // 결제 로직 연결
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text('결제하기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    )
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
