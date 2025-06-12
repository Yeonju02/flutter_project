import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:routinelogapp/shop/payment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;
  const ProductDetailPage({super.key, required this.data});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;
  String selectedColor = 'blue';
  final formatter = NumberFormat('#,###');

  double averageScore = 0.0;
  int totalReviews = 0;
  Map<int, int> scoreCountMap = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

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

  void _calculateReviewStats(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      setState(() {
        averageScore = 0.0;
        totalReviews = 0;
        scoreCountMap = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      });
      return;
    }

    int totalScore = 0;
    Map<int, int> tempMap = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (var doc in docs) {
      final score = (doc['score'] as num?)?.round() ?? 0;
      totalScore += score;
      if (tempMap.containsKey(score)) tempMap[score] = tempMap[score]! + 1;
    }

    setState(() {
      averageScore = (totalScore / docs.length).toDouble();
      totalReviews = docs.length;
      scoreCountMap = tempMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text('상세정보'),
        leading: const BackButton(),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '총 가격\n${formatter.format(product['productPrice'] * quantity)}원',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final cartRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId!)
                        .collection('cart');

                    final cartItem = {
                      'productId': product['productId'],
                      'productName': product['productName'],
                      'productPrice': product['productPrice'],
                      'thumbNail': product['imgPath'],
                      'selectedColor': selectedColor,
                      'quantity': quantity,
                      'addedAt': Timestamp.now(),
                    };

                    await cartRef.add(cartItem);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('장바구니에 담겼습니다.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('담아두기'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    final orderItem = {
                      'productId': product['productId'],
                      'productName': product['productName'],
                      'productPrice': product['productPrice'],
                      'thumbNail': product['imgPath'],
                      'selectedColor': selectedColor,
                      'quantity': quantity,
                    };

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentPage(products: [orderItem]),
                      ),
                    );
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('주문하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                product['imgPath'],
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            // 이름 + 별점
            Text(product['productName'],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .doc(product['productId'])
                  .collection('reviews')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('리뷰 없음', style: TextStyle(color: Colors.grey));
                }

                final docs = snapshot.data!.docs;
                int totalScore = 0;
                for (var doc in docs) {
                  final rawScore = doc['score'];
                  double scoreDouble;
                  if (rawScore is num) {
                    scoreDouble = rawScore.toDouble();
                  } else if (rawScore is String) {
                    scoreDouble = double.tryParse(rawScore) ?? 0.0;
                  } else {
                    scoreDouble = 0.0;
                  }
                  totalScore += scoreDouble.round();
                }

                final avg = totalScore / docs.length;

                return Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text('별점 ${avg.toStringAsFixed(1)}  (${docs.length} Reviews)',
                        style: const TextStyle(fontSize: 14)),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // 설명
            const Text('제품 설명', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              product['description'],
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),

            // 색상 선택
            const Text('색', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildColorOption('blue', Colors.blue),
                _buildColorOption('green', Colors.green),
                _buildColorOption('pink', Colors.pinkAccent),
              ],
            ),
            const SizedBox(height: 20),

            // 수량 조절
            Row(
              children: [
                const Text('갯수', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      if (quantity > 1) quantity--;
                    });
                  },
                ),
                Text('$quantity', style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      quantity++;
                    });
                  },
                ),
              ],
            ),

            // 리뷰 목록
            const Divider(height: 32),
            const Text('리뷰', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .doc(product['productId']) // productId 기준으로 조회
                  .collection('reviews')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _calculateReviewStats(docs);
                });

                if (docs.isEmpty) {
                  return const Text('아직 작성된 리뷰가 없습니다.');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 24),
                        const SizedBox(width: 4),
                        Text(averageScore.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text('$totalReviews개의 상품리뷰가 있습니다.'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Column(
                      children: [5, 4, 3, 2, 1].map((star) {
                        final count = scoreCountMap[star] ?? 0;
                        final percent = totalReviews == 0 ? 0 : (count / totalReviews * 100).round();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text('$star'),
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              const SizedBox(width: 6),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: percent / 100,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('$percent%'),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 사용자 정보 + 별점
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text('${data['score']}점'),
                                  const SizedBox(width: 12),
                                  Text(
                                    (data['createdAt'] as Timestamp).toDate().toString().split(' ').first,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('@${data['userId']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(data['content'], style: const TextStyle(height: 1.5)),

                              // 이미지 (있을 경우)
                              if (data['reviewImg'] != null && data['reviewImg'] is List) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: (data['reviewImg'] as List).length,
                                    itemBuilder: (context, imgIndex) {
                                      final imgPath = data['reviewImg'][imgIndex];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.asset(
                                            imgPath,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(String colorId, Color color) {
    final isSelected = selectedColor == colorId;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = colorId;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _getColorLabel(colorId),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _getColorLabel(String id) {
    switch (id.toLowerCase()) {
      case 'blue':
        return '블루';
      case 'lightblue':
        return '라이트 블루';
      case 'navy':
        return '네이비';
      case 'skyblue':
        return '스카이 블루';
      case 'green':
        return '그린';
      case 'lightgreen':
        return '라이트 그린';
      case 'olive':
        return '올리브';
      case 'lime':
        return '라임';
      case 'red':
        return '레드';
      case 'pink':
      case 'pinkaccent':
        return '핑크';
      case 'hotpink':
        return '핫핑크';
      case 'orange':
        return '오렌지';
      case 'yellow':
        return '옐로우';
      case 'gold':
        return '골드';
      case 'brown':
        return '브라운';
      case 'beige':
        return '베이지';
      case 'purple':
        return '퍼플';
      case 'lavender':
        return '라벤더';
      case 'white':
        return '화이트';
      case 'black':
        return '블랙';
      case 'gray':
      case 'grey':
        return '그레이';
      default:
        return id; // 정의되지 않은 색상은 그대로 표시
    }
  }
}
