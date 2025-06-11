import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> productData;
  final int quantity;
  final String selectedColor;

  const PaymentPage({
    super.key,
    required this.productData,
    required this.quantity,
    required this.selectedColor,
  });

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

  int pointAvailable = 0;
  int pointUsed = 0;
  final pointController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserPoint();
  }

  Future<void> _loadUserPoint() async {
    const userId = 'cyj32148'; // 로그인한 사용자 ID로 대체
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (doc.exists) {
      setState(() {
        pointAvailable = doc.data()?['point'] ?? 0;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    requestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final originalPrice = widget.productData['productPrice'] * widget.quantity;
    final discount = (pointUsed >= 500 && pointUsed % 10 == 0 && pointUsed <= pointAvailable) ? pointUsed : 0;
    final totalPrice = originalPrice - discount;

    return Scaffold(
      appBar: AppBar(title: const Text('결제하기')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 상품 요약
              Text(widget.productData['productName'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('색상: ${widget.selectedColor}, 수량: ${widget.quantity}'),
              const Divider(height: 30),

              // 배송 정보 입력
              const Text('배송 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildTextField(nameController, '이름', '받는 분 이름을 입력하세요'),
              _buildTextField(phoneController, '연락처', '010-xxxx-xxxx'),
              _buildTextField(addressController, '주소', '배송 받을 주소를 입력하세요'),
              _buildTextField(requestController, '요청사항 (선택)', '문 앞에 놔주세요', optional: true),
              const Divider(height: 30),

              const SizedBox(height: 30),
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
                      onChanged: (value) {
                        setState(() {
                          pointUsed = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        pointUsed = pointAvailable;
                        pointController.text = pointUsed.toString();
                      });
                    },
                    child: const Text('모두 사용'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '사용 가능 포인트: ${formatter.format(pointAvailable)}P / 보유 포인트: ${formatter.format(pointAvailable)}P',
                style: const TextStyle(color: Colors.grey),
              ),

              // 총 결제 금액
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('총 결제 금액', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${formatter.format(totalPrice)}원', style: const TextStyle(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 30),

              // 결제 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onPayPressed,
                  child: const Text('결제하기'),
                ),
              )
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

  void _onPayPressed() {
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

  }
}
