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
  String selectedColor = '';
  final formatter = NumberFormat('#,###');

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

  Future<String> getMaskedUserId(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(docId).get();
      final userId = doc['userId'] ?? '알 수 없음';
      if (userId.length <= 4) return userId;
      return userId.substring(0, 4) + '*' * (userId.length - 4);
    } catch (e) {
      return '유저정보 없음';
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.data;

    print('✅ productId: ${product['productId']}');

    final List<Map<String, dynamic>> colorOptions =
    List<Map<String, dynamic>>.from(product['colors'] ?? []);
    final List<String> colorList =
    colorOptions.map((e) => e['color'].toString()).toList();
    selectedColor = selectedColor.isEmpty && colorList.isNotEmpty
        ? colorList[0]
        : selectedColor;

    final colorInfo = colorOptions.firstWhere(
            (e) => e['color'] == selectedColor,
        orElse: () => colorOptions.first);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('상세정보',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
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
                    if (userId == null) return;

                    // 🔍 userId 기준으로 문서 찾기
                    final query = await FirebaseFirestore.instance
                        .collection('users')
                        .where('userId', isEqualTo: userId)
                        .limit(1)
                        .get();

                    if (query.docs.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('사용자 정보를 찾을 수 없습니다.')),
                      );
                      return;
                    }

                    final userDocId = query.docs.first.id;
                    final cartRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(userDocId)
                        .collection('cart');

                    final cartDocId = '${product['productId']}_$selectedColor';

                    final cartItem = {
                      'productId': product['productId'],
                      'productName': product['productName'],
                      'productPrice': product['productPrice'],
                      'thumbNail': colorInfo['imgPath'],
                      'selectedColor': selectedColor,
                      'quantity': quantity,
                      'addedAt': Timestamp.now(),
                    };

                    final existing = await cartRef.doc(cartDocId).get();

                    if (existing.exists) {
                      // 이미 있으면 수량만 증가
                      await cartRef.doc(cartDocId).update({
                        'quantity': FieldValue.increment(quantity),
                        'addedAt': Timestamp.now(), // 최근 담은 시간 갱신
                      });
                    } else {
                      // 없으면 새로 저장
                      await cartRef.doc(cartDocId).set(cartItem);
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('장바구니에 담겼습니다.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE0E0E0),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
                      'thumbNail': colorInfo['imgPath'],
                      'selectedColor': selectedColor,
                      'quantity': quantity,
                    };

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PaymentPage(products: [orderItem]),
                      ),
                    );
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('주문하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF92BBE2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
              child: Image.network(
                colorInfo['imgPath'],
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            // 이름
            Text(product['productName'],
                style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            const Text('제품 설명',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(product['description'], style: const TextStyle(height: 1.5)),
            const SizedBox(height: 12),

            const Text('색상 선택',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colorOptions.map((colorData) {
                final colorId = colorData['color'].toString();
                final stock = colorData['stock'] ?? 0;
                return Column(
                  children: [
                    _buildColorOption(colorId, _mapColorIdToColor(colorId)),
                    const SizedBox(height: 4),
                    Text('재고 $stock개',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                const Text('수량', style: TextStyle(fontWeight: FontWeight.bold)),
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

            const Divider(height: 32),
            const Text('리뷰', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .doc(product['productId'])
                  .collection('reviews')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Text('아직 작성된 리뷰가 없습니다.');
                }

                double totalScore = 0;
                for (var doc in docs) {
                  final score = (doc['score'] ?? 0).toDouble();
                  totalScore += score;
                }

                final avg = docs.isEmpty ? 0 : totalScore / docs.length;

                String maskId(String id) {
                  if (id.length <= 4) return id;
                  return id.substring(0, 4) + '*' * (id.length - 4);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildRatingSummary(docs),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final review = docs[index].data() as Map<String, dynamic>;
                        final reviewDocId = review['userId'];

                        final contents = review['contents'] ?? '';
                        final createdAt = (review['createdAt'] as Timestamp?)?.toDate();
                        final formattedDate = createdAt != null
                            ? DateFormat('yyyy.MM.dd').format(createdAt)
                            : '날짜 없음';

                        final score = review['score'] ?? 0;
                        final List<dynamic>? reviewImgs = review['reviewImg'] as List?;

                        return FutureBuilder<String>(
                          future: getMaskedUserId(reviewDocId),
                          builder: (context, snapshot) {
                            final maskedId = snapshot.data ?? '...';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 16, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text('$score점'),
                                      const SizedBox(width: 12),
                                      Text(formattedDate,
                                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(width: 8),
                                      Text('@$maskedId',
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(contents, style: const TextStyle(height: 1.5)),

                                  if (reviewImgs != null && reviewImgs.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 100,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: reviewImgs.length,
                                        itemBuilder: (context, imgIndex) {
                                          final imgPath = reviewImgs[imgIndex];
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Image.network(
                                                imgPath,
                                                width: 100,
                                                height: 100,
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
                          }
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

  Widget buildRatingSummary(List<QueryDocumentSnapshot> docs) {
    final Map<int, int> ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var doc in docs) {
      int score = (doc['score'] ?? 0).toInt();
      if (ratingCounts.containsKey(score)) {
        ratingCounts[score] = ratingCounts[score]! + 1;
      }
    }

    int total = docs.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 24),
            const SizedBox(width: 4),
            Text(
              (ratingCounts.entries.fold(0, (sum, e) => sum + e.key * e.value) / (total == 0 ? 1 : total)).toStringAsFixed(1),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text('$total개의 상품리뷰가 있습니다.'),
          ],
        ),
        const SizedBox(height: 12),
        for (int i = 5; i >= 1; i--) ...[
          Row(
            children: [
              Text('$i점'),
              const SizedBox(width: 4),
              Expanded(
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : ratingCounts[i]! / total,
                  backgroundColor: Colors.grey[300],
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 6),
              Text('${((ratingCounts[i]! / (total == 0 ? 1 : total)) * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 4),
        ]
      ],
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
        return id;
    }
  }
}

Color _mapColorIdToColor(String id) {
  switch (id.toLowerCase()) {
    case 'blue':
      return Colors.blue;
    case 'lightblue':
      return Colors.lightBlue;
    case 'navy':
      return Colors.blue.shade900;
    case 'skyblue':
      return Colors.lightBlueAccent;
    case 'green':
      return Colors.green;
    case 'lightgreen':
      return Colors.lightGreen;
    case 'olive':
      return const Color(0xFF808000);
    case 'lime':
      return Colors.lime;
    case 'red':
      return Colors.red;
    case 'pink':
      return Colors.pink;
    case 'pinkaccent':
      return Colors.pinkAccent;
    case 'hotpink':
      return const Color(0xFFFF69B4);
    case 'orange':
      return Colors.orange;
    case 'yellow':
      return Colors.yellow;
    case 'gold':
      return const Color(0xFFFFD700);
    case 'brown':
      return Colors.brown;
    case 'beige':
      return const Color(0xFFF5F5DC);
    case 'purple':
      return Colors.purple;
    case 'lavender':
      return const Color(0xFFE6E6FA);
    case 'white':
      return Colors.white;
    case 'black':
      return Colors.black;
    case 'gray':
    case 'grey':
      return Colors.grey;
    default:
      return Colors.grey;
  }
}
