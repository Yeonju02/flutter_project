import 'package:flutter/material.dart';

class CycleExplainDialog extends StatelessWidget {
  const CycleExplainDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF182333),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '“이 시간에 자야 피곤하지 않은 이유”',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.lightBlueAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '수면 주기의 비밀',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),

            const SizedBox(height: 20),


            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/sleep_cycle_graph.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),

            // 본문 설명
            const Text(
              '우리의 수면은 단순히 “얼마나 오래 잤는가”보다\n“어느 타이밍에 깨는가”가 더 중요해요.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            const Text(
              '수면 주기(cycle)는 약 90~120분마다 반복되며,\n'
                  '이 주기 안에서 얕은 수면 → 깊은 수면 → 렘수면\n'
                  '순으로 흐릅니다.\n\n'
                  '특히, 깊은 수면(3~4단계) 중에 깬다면, 푹 잔 것 같지 않고\n'
                  '피로가 풀리지 않는 느낌이 듭니다.\n\n'
                  '반면, 렘수면 직후나 얕은 수면 단계에서 깨어나면\n'
                  '개운하고 맑은 정신으로 아침을 시작할 수 있어요.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
