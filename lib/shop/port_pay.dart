import 'package:flutter/material.dart';

/* 포트원 V1 결제 모듈을 불러옵니다. */
import 'package:portone_flutter/iamport_payment.dart';
/* 포트원 V1 결제 데이터 모델을 불러옵니다. */
import 'package:portone_flutter/model/payment_data.dart';

class PortPay extends StatelessWidget {
  final int amount;
  final String buyerName;
  final String buyerTel;
  final String buyerEmail;
  final String buyerAddr;
  final String buyerPostcode;

  const PortPay({
    super.key,
    required this.amount,
    required this.buyerName,
    required this.buyerTel,
    required this.buyerEmail,
    required this.buyerAddr,
    required this.buyerPostcode,
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
      callback: (Map<String, String> result) {
        Navigator.pushReplacementNamed(
          context,
          '/result',
          arguments: result,
        );
      },
    );
  }
}
