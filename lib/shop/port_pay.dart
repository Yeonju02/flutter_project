import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/* 포트원 V1 결제 모듈을 불러옵니다. */
import 'package:portone_flutter/iamport_payment.dart';
/* 포트원 V1 결제 데이터 모델을 불러옵니다. */
import 'package:portone_flutter/model/payment_data.dart';
import 'package:routinelogapp/shop/payment_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PortPay extends StatelessWidget {
  final int amount;
  final String buyerName;
  final String buyerTel;
  final String buyerEmail;
  final String buyerAddr;
  final String buyerPostcode;
  final List<Map<String, dynamic>> products;

  const PortPay({
    super.key,
    required this.amount,
    required this.buyerName,
    required this.buyerTel,
    required this.buyerEmail,
    required this.buyerAddr,
    required this.buyerPostcode,
    required this.products
  });

  @override
  Widget build(BuildContext context) {
    return IamportPayment(
      appBar: AppBar(title: const Text('포트원 V1 결제')),
      initialChild: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/iamport-logo.png'),
            const SizedBox(height: 15),
            const Text('잠시만 기다려주세요...', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
      userCode: 'imp38661450',
      data: PaymentData(
        pg: 'html5_inicis',
        payMethod: 'card',
        name: '루틴로그 상품 결제',
        merchantUid: 'mid_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        buyerName: buyerName,
        buyerTel: buyerTel,
        buyerEmail: buyerEmail,
        buyerAddr: buyerAddr,
        buyerPostcode: buyerPostcode,
        appScheme: 'example',
        cardQuota: [2, 3],
      ),
        callback: (Map<String, String> result) async {
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getString('userId');
          bool isSuccess = result['imp_success'] == 'true';

          if (isSuccess && userId != null) {
            final query = await FirebaseFirestore.instance
                .collection('users')
                .where('userId', isEqualTo: userId)
                .limit(1)
                .get();

            if (query.docs.isNotEmpty) {
              final userDoc = query.docs.first;
              final userDocId = userDoc.id;
              final userRef = FirebaseFirestore.instance.collection('users').doc(userDocId);
              final orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';
              final now = Timestamp.now();

              for (var product in products) {
                final productId = product['productId'];
                final quantity = product['quantity'] ?? 1; // 혹은 기본값 1
                final productRef = FirebaseFirestore.instance.collection('products').doc(productId);

                try {
                  await FirebaseFirestore.instance.runTransaction((transaction) async {
                    final snapshot = await transaction.get(productRef);
                    if (!snapshot.exists) throw Exception('상품 없음');
                    final currentStock = snapshot['stock'] ?? 0;
                    if (currentStock < quantity) throw Exception('재고 부족');

                    transaction.update(productRef, {'stock': currentStock - quantity});
                  });
                } catch (e) {

                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('결제 실패'),
                      content: const Text('품절된 상품이 있어 결제를 진행할 수 없습니다.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // 팝업 닫기
                            Navigator.of(context).pop(); // 결제 페이지도 닫고 이전으로
                          },
                          child: const Text('확인'),
                        ),
                      ],
                    ),
                  );
                  return; // 더 이상 진행하지 않음
                }

                await userRef.collection('orders').add({
                  'productId': productId,
                  'productName': product['productName'],
                  'productPrice': product['productPrice'],
                  'status': '결제완료',
                  'orderId': orderId,
                  'orderedAt': now,
                  'account': '',
                });

                await userRef.collection('cart').doc(productId).delete();
              }

              final usedPoint = prefs.getInt('usedPoint') ?? 0;
              if (usedPoint > 0) {
                final currentPoint = userDoc['point'] ?? 0;
                await userRef.update({'point': currentPoint - usedPoint});
              }
            } else {
              isSuccess = false;
            }
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentResultPage(result: result),
            ),
          );
        },
    );
  }
}
