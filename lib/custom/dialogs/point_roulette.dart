import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roulette/roulette.dart';

import 'guide_dialog.dart';

class PointRouletteDialog extends StatefulWidget {
  final String userDocId; // 추가

  const PointRouletteDialog({super.key, required this.userDocId}); // 수정

  @override
  State<PointRouletteDialog> createState() => _PointRouletteDialogState();
}

class _PointRouletteDialogState extends State<PointRouletteDialog> {
  final _random = Random();

  late final RouletteGroup group = RouletteGroup([
    RouletteUnit(weight: 20, color: const Color(0xFF5F6CFA), text: 'x0'),
    RouletteUnit(weight: 50, color: const Color(0xFF90F255), text: 'x1'),
    RouletteUnit(weight: 15, color: const Color(0xFFFA7052), text: 'x2'),
    RouletteUnit(weight: 5, color: const Color(0xFFFAE25F), text: 'x3'),
  ]);

  final RouletteController _controller = RouletteController();
  bool isRolling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rollRoulette() async {
    if (isRolling) return;
    setState(() => isRolling = true);

    final index = _getWeightedResultIndex();
    final offset = _random.nextDouble();

    final result = await _controller.rollTo(index, offset: offset);
    if (result) {
      final text = group.units[index].text;
      debugPrint("룰렛 결과 인덱스: $index / 텍스트: $text");
      _showResultDialog(text!);
    }

    setState(() => isRolling = false);
  }

  int _getWeightedResultIndex() {
    final totalWeight = group.units.fold<double>(0, (sum, unit) => sum + unit.weight);
    final rand = _random.nextDouble() * totalWeight;
    double cumulative = 0;

    for (int i = 0; i < group.units.length; i++) {
      cumulative += group.units[i].weight;
      if (rand < cumulative) return i;
    }

    return group.units.length - 1;
  }

  Future<void> _addPoint(int value) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(widget.userDocId);
    final snapshot = await docRef.get();
    final currentPoint = (snapshot.data()?['point'] ?? 0) as int;
    await docRef.update({'point': currentPoint + value});
  }

  void _showResultDialog(String resultText) {
    String title = '';
    String message = '';
    int earnedPoint = 0;

    switch (resultText) {
      case 'x0':
        title = '아쉽습니다!';
        message = '포인트를 획득하지 못했습니다.\n그래도 걱정 마세요.\n다음 레벨업 시에도 기회가 있습니다.';
        break;
      case 'x1':
        title = '본전';
        message = '그래도 본전! 100 포인트를 획득했습니다!';
        earnedPoint = 100;
        break;
      case 'x2':
        title = '축하합니다!';
        message = '200 포인트를 획득했습니다!';
        earnedPoint = 200;
        break;
      case 'x3':
        title = '축하합니다!';
        message = '300 포인트를 획득했습니다!';
        earnedPoint = 300;
        break;
      default:
        title = '결과';
        message = '알 수 없는 결과입니다.';
    }

    showDialog(
      context: context,
      builder: (context) => GuideDialog(
        title: title,
        description: message,
        onConfirm: () async {
          if (earnedPoint > 0) {
            await _addPoint(earnedPoint);
          }
          Navigator.of(context).pop(); // GuideDialog
          Navigator.of(context).pop(); // PointRouletteDialog
          Navigator.of(context).pop(); // PointBoxDialog
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('룰렛 돌리기', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              width: 240,
              height: 240,
              child: Roulette(
                group: group,
                controller: _controller,
                style: const RouletteStyle(
                  centerStickerColor: Color(0xFF77BDFF),
                  dividerThickness: 4,
                  centerStickSizePercent: 0.05,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton(
                  onPressed: isRolling ? null : _rollRoulette,
                  child: const Text('돌리기'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('포기하기'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
