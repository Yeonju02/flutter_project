import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:routinelogapp/shop/port_pay.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentPage extends StatefulWidget {
  final List<Map<String, dynamic>> products; // 여러 상품
  const PaymentPage({super.key, required this.products});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final formatter = NumberFormat('#,###');
  final _formKey = GlobalKey<FormState>();


  // 배송 정보 입력값
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final requestController = TextEditingController();

  int pointOwned = 0;
  int pointAvailable = 0;
  int pointUsed = 0;
  final pointController = TextEditingController();

  int totalPrice = 0;
  int productTotal = 0;

  // 주문 상품 펼치기
  bool _isExpanded = false;

  // 사용자가 담은 주문상품 리스트
  List<Widget> _buildOrderItemWidgets() {
    final List<Widget> widgets = [];

    for (var product in widget.products) {
      for (int i = 0; i < (product['quantity'] ?? 1); i++) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    product['thumbNail'],
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product['productName'] ?? '',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '${formatter.format(product['productPrice'])}원  1개',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '색상: ${product['selectedColor'] ?? '기본'}',
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }

  @override
  void initState() {
    super.initState();
    _loadUserPoint();
    _calculateTotalPrice();
  }

  int deliveryFee = 0;

  void _calculateTotalPrice() {
    int sum = 0;
    for (var product in widget.products) {
      final price = int.tryParse(product['productPrice'].toString()) ?? 0;
      final rawQty = product['quantity'];
      final qty = rawQty is int ? rawQty : int.tryParse(rawQty.toString()) ?? 1;
      sum += price * qty;
    }

    final discount = (pointUsed >= 500 && pointUsed % 10 == 0 && pointUsed <= pointAvailable) ? pointUsed : 0;
    final fee = (sum - discount) >= 50000 ? 0 : 3000;

    setState(() {
      productTotal = sum;        // 총 상품 금액
      deliveryFee = fee;         // 배송비
      totalPrice = sum - discount + fee;  // 최종 결제 금액
    });
  }

  String? userId;
  String? userEmail;

  Future<void> _loadUserPoint() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      print('❌ SharedPreferences에서 userId 없음');
      return;
    }

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      print('❌ userId가 "$userId"인 문서를 찾을 수 없습니다.');
      return;
    }

    final userDoc = query.docs.first;
    final data = userDoc.data();

    setState(() {
      final rawPoint = data['point'] ?? 0;
      pointOwned = rawPoint;

      final usable = (rawPoint ~/ 10) * 10;
      pointAvailable = usable >= 500 ? usable : 0;

      userEmail = data['userEmail'] ?? ''; // ✅ 이메일 저장
      pointController.text = '0'; // 초기화
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    requestController.dispose();
    super.dispose();
  }

  // UI
  @override
  Widget build(BuildContext context) {
    int getTotalQuantity() {
      return widget.products.fold<int>(0, (sum, item) {
        final qtyRaw = item['quantity'] ?? 1;
        final intQty = qtyRaw is int ? qtyRaw : int.tryParse(qtyRaw.toString()) ?? 1;
        return sum + intQty;
      });
    }

    return Scaffold(
      backgroundColor : Colors.white,
      appBar: AppBar(title: const Text('주문/결제', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '₩50,000 이상 구매 시 배송비 무료 (배송비 ₩3,000)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              // 주문 상품 요약 (펼치기/접기)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('주문상품 총 ${getTotalQuantity()}개',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              if (_isExpanded) ...[
                const SizedBox(height: 8),
                ..._buildOrderItemWidgets(),
              ],

              const Divider(height: 20),

              // 배송 정보 입력
              const Text('배송 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildTextField(nameController, '이름', '받는 분 이름을 입력하세요'),
              _buildTextField(phoneController, '연락처', '010-xxxx-xxxx'),
              _buildTextField(addressController, '주소', '배송 받을 주소를 입력하세요'),
              _buildTextField(requestController, '요청사항 (선택)', '문 앞에 놔주세요', optional: true),
              const Divider(height: 30),

              const SizedBox(height: 10),
              const Text('포인트 사용', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pointController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '사용할 포인트 입력',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final input = int.tryParse(pointController.text) ?? 0;

                      if (input > pointAvailable) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("보유 포인트를 초과했습니다.")),
                        );
                        return;
                      }

                      if (input < 500 || input % 10 != 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("포인트는 500 이상, 10원 단위로만 사용 가능합니다.")),
                        );
                        return;
                      }

                      setState(() {
                        pointUsed = input;
                        _calculateTotalPrice();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF92BBE2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('사용'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '사용 가능 포인트: ${formatter.format(pointAvailable)}P / 보유 포인트: ${formatter.format(pointOwned)}P',
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('총 상품 금액', style: TextStyle(fontSize: 16)),
                  Text('${formatter.format(productTotal)}원'),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('배송비', style: TextStyle(fontSize: 16)),
                  Text('${formatter.format(deliveryFee)}원'),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('총 결제 금액', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${formatter.format(totalPrice)}원', style: const TextStyle(fontSize: 18)),
                ],
              ),
              SizedBox(height: 10,),

              // 결제 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onPayPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF92BBE2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('결제하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: optional ? null : (value) => value == null || value.isEmpty ? '$label을 입력하세요' : null,
      ),
    );
  }

  void _onPayPressed() async {
    if (_formKey.currentState!.validate()) {
      // 여기에 KG이니시스 연동 또는 결제 페이지 이동 로직을 작성
      print('주문 정보:');
      print('이름: ${nameController.text}');
      print('전화번호: ${phoneController.text}');
      print('주소: ${addressController.text}');
      print('요청사항: ${requestController.text}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("결제 진행 중...")),
      );

      // TODO: KG이니시스 웹뷰 결제창 열기 또는 서버 연동
    }

    if (pointUsed > pointAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("보유 포인트를 초과했습니다.")),
      );
      return;
    }

    if (pointUsed > 0 && (pointUsed < 500 || pointUsed % 10 != 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("포인트는 500 이상, 10원 단위로만 사용 가능합니다.")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('usedPoint', pointUsed);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PortPay(
          amount: totalPrice,
          buyerName: nameController.text,
          buyerTel: phoneController.text,
          buyerEmail: userEmail!,
          buyerAddr: addressController.text,
          buyerPostcode: '',
          products: widget.products,
        ),
      ),
    );


  }
}
