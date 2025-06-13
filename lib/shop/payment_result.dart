import 'package:flutter/material.dart';

import '../main/main_page.dart';

class PaymentResultPage extends StatelessWidget {
  final Map<String, String> result;

  const PaymentResultPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isSuccess = result['imp_success'] == 'true';
    final message = isSuccess
        ? '✅ 결제가 완료되었습니다!'
        : '❌ 결제가 실패했습니다.\n사유: ${result['error_msg'] ?? '알 수 없음'}';

    return Scaffold(
      appBar: AppBar(title: const Text('결제 결과')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: isSuccess ? Colors.green : Colors.red,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => MainPage()),
                        (route) => false,
                  );
                },
                child: const Text('메인으로 돌아가기'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
