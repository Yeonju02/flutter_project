import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:routinelogapp/shop/payment.dart';

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
  bool get _isAllSelected => selected.values.every((e) => e);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('userId', isEqualTo: widget.userId)
          .limit(1)
          .get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (userSnapshot.data!.docs.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('사용자 정보를 찾을 수 없습니다.')),
          );
        }

        final userDocId = userSnapshot.data!.docs.first.id;

        final cartRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userDocId)
            .collection('cart')
            .orderBy('addedAt', descending: true);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('장바구니', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            backgroundColor: Colors.white,
            leading: const BackButton(),
            actions: [
              TextButton(
                onPressed: () async {
                  final selectedIds = selected.entries
                      .where((entry) => entry.value)
                      .map((entry) => entry.key)
                      .toList();

                  for (final docId in selectedIds) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userDocId)
                        .collection('cart')
                        .doc(docId)
                        .delete();
                  }

                  setState(() {
                    for (final id in selectedIds) {
                      selected.remove(id);
                      quantities.remove(id);
                    }
                  });
                },
                child: const Text('선택 삭제', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () {
                  final newValue = !_isAllSelected;
                  setState(() {
                    for (var key in selected.keys) {
                      selected[key] = newValue;
                    }
                  });
                },
                child: Text(_isAllSelected ? '전체 해제' : '전체 선택'),
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
                final data = doc.data() as Map<String, dynamic>;
                quantities[id] ??= data['quantity'] ?? 1;
                selected[id] ??= true;
              }

              final selectedDocs = docs.where((doc) => selected[doc.id] == true).toList();
              final total = selectedDocs.fold<int>(
                0,
                    (sum, doc) => sum + (doc['productPrice'] as int) * (quantities[doc.id] ?? 1),
              );

              // 👇 이하 기존 UI 그대로...
              return Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.65,
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
                            color: Color(0xFFF0F4FA),
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

                              // 이미지
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      data['thumbNail'],
                                      width: double.infinity,
                                      height: 100,
                                      fit: BoxFit.cover,
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
                              // 색상 표시
                              Text('색상: ${_getColorLabel(data['selectedColor'] ?? '기본색')}'),
                              const SizedBox(height: 4),

                              // 수량 조절
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16),
                                    onPressed: () async {
                                      if (quantities[docId]! > 1) {
                                        setState(() {
                                          quantities[docId] = quantities[docId]! - 1;
                                        });

                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(widget.userId)
                                            .collection('cart')
                                            .doc(docId)
                                            .update({'quantity': quantities[docId]});
                                      }
                                    },
                                  ),
                                  Text('$quantity'),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    onPressed: () async {
                                      setState(() {
                                        quantities[docId] = quantities[docId]! + 1;
                                      });

                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(widget.userId)
                                          .collection('cart')
                                          .doc(docId)
                                          .update({'quantity': quantities[docId]});
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
                            // 선택된 상품 리스트 추출
                            final selectedItems = selectedDocs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final docId = doc.id;

                              return {
                                'productId': data['productId'],
                                'productName': data['productName'],
                                'productPrice': data['productPrice'],
                                'thumbNail': data['thumbNail'],
                                'quantity': quantities[docId],
                                'selectedColor': data['selectedColor'] ?? '기본색', // 없으면 기본값 처리
                              };
                            }).toList();

                            if (selectedItems.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("결제할 상품을 선택해주세요.")),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentPage(products: selectedItems),
                              ),
                            );
                          },
                          icon: const Icon(Icons.payment),
                          label: const Text('주문하기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF92BBE2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      },
    );
  }
  String _getColorLabel(String id) {
    switch (id.toLowerCase()) {
      case 'blue':
        return '블루';
      case 'green':
        return '그린';
      case 'pink':
      case 'pinkaccent':
        return '핑크';
      case 'red':
        return '레드';
      case 'navy':
        return '네이비';
      case 'black':
        return '블랙';
      case 'white':
        return '화이트';
      case 'gray':
      case 'grey':
        return '그레이';
      case 'orange':
        return '오렌지';
      case 'yellow':
        return '옐로우';
      case 'beige':
        return '베이지';
      case 'purple':
        return '퍼플';
      case 'lavender':
        return '라벤더';
      case 'skyblue':
        return '스카이 블루';
      case 'lime':
        return '라임';
      case 'olive':
        return '올리브';
      case 'gold':
        return '골드';
      default:
        return id;
    }
  }

}


