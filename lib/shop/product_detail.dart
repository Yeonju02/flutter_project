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

  @override
  Widget build(BuildContext context) {
    final product = widget.data;
    final List<Map<String, dynamic>> colorOptions =
    List<Map<String, dynamic>>.from(product['colors'] ?? []);
    final List<String> colorList =
    colorOptions.map((e) => e['color'].toString()).toList();
    selectedColor = selectedColor.isEmpty && colorList.isNotEmpty
        ? colorList[0]
        : selectedColor;

    final int totalStock = colorOptions.fold<int>(0, (sum, item) {
      final s = item['stock'];
      return sum + (s is int ? s : (s is double ? s.toInt() : 0));
    });

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
                    final cartRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId!)
                        .collection('cart');

                    final cartItem = {
                      'productId': product['productId'],
                      'productName': product['productName'],
                      'productPrice': product['productPrice'],
                      'thumbNail': colorInfo['imgPath'],
                      'selectedColor': selectedColor,
                      'quantity': quantity,
                      'addedAt': Timestamp.now(),
                    };

                    await cartRef.doc(product['productId']).set(cartItem);

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
                  .doc(product['productId']) // productId 기준
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 24),
                        const SizedBox(width: 4),
                        Text(avg.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text('${docs.length}개의 리뷰'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final review = docs[index].data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text('${review['score']}점'),
                                  const SizedBox(width: 12),
                                  Text(
                                    (review['createdAt'] as Timestamp).toDate().toString().split(' ').first,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('@${review['userId']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(review['content'], style: const TextStyle(height: 1.5)),

                              if (review['reviewImg'] != null && review['reviewImg'] is List) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: (review['reviewImg'] as List).length,
                                    itemBuilder: (context, imgIndex) {
                                      final imgPath = review['reviewImg'][imgIndex];
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
