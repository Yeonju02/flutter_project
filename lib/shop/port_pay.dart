import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:portone_flutter/iamport_payment.dart';
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
    required this.products,
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
              final selectedColorRaw = product['selectedColor'];
              final quantity = product['quantity'] ?? 1;
              final productRef = FirebaseFirestore.instance.collection('products').doc(productId);

              try {
                if (selectedColorRaw == null) {
                  throw Exception('선택한 색상이 없습니다.');
                }

                final selectedColor = selectedColorRaw.toString().toLowerCase();

                await FirebaseFirestore.instance.runTransaction((transaction) async {
                  final snapshot = await transaction.get(productRef);
                  if (!snapshot.exists) throw Exception('상품이 존재하지 않습니다.');

                  final stockMap = Map<String, dynamic>.from(snapshot['stock']);
                  final currentStock = stockMap[selectedColor];

                  if (currentStock == null || currentStock < quantity) {
                    throw Exception('선택한 색상의 재고가 부족합니다.');
                  }

                  transaction.update(productRef, {
                    'stock.$selectedColor': currentStock - quantity,
                  });
                });
              } catch (e) {
                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('결제 실패'),
                    content: Text('결제 실패 사유: ${e.toString()}'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // 팝업 닫기
                          Navigator.of(context).pop(); // 결제 페이지 닫기
                        },
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                );
                return;
              }

              final orderItem = {
                'productId': productId,
                'productName': product['productName'],
                'productPrice': product['productPrice'],
                'selectedColor': selectedColorRaw,
                'quantity': quantity,
                'status': '결제완료',
                'orderId': orderId,
                'orderedAt': now,
                'account': '',
              };

              print("🔥 저장할 주문 정보: $orderItem");

              await userRef.collection('orders').add(orderItem);


              await userRef.collection('orders').add({
                'productId': productId,
                'productName': product['productName'],
                'productPrice': product['productPrice'],
                'selectedColor': selectedColorRaw,
                'quantity': quantity,
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
