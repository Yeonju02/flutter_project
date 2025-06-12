import 'package:flutter/material.dart';

class RecommendRoutineBox extends StatelessWidget {
  final String title;
  final double score;
  final VoidCallback onApply; // 콜백으로 제목 전달함

  const RecommendRoutineBox({
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),

          // 점 · 별 · 평균 별점 + 적용하기 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('•', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '평균 별점 : ${score.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
              TextButton(
                onPressed: onApply,
                child: const Text(
                  '적용하기',
                  style: TextStyle(
                    color: Colors.blue,
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
