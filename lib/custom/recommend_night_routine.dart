import 'package:flutter/material.dart';

class RecommendNightRoutineBox extends StatelessWidget {
  final String title;
  final double score;
  final VoidCallback onApply;

  const RecommendNightRoutineBox({
    super.key,
    required this.title,
    required this.score,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2F42), // 어두운 배경
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),

          // 별점 정보와 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('•', style: TextStyle(fontSize: 16, color: Colors.white)),
                  const SizedBox(width: 8),
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '평균 별점 : ${score.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
              TextButton(
                onPressed: onApply,
                child: const Text(
                  '적용하기',
                  style: TextStyle(
                    color: Color(0xFF90CAF9), // 연한 파랑
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
