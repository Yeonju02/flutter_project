import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vmath;

class AnimatedRoulettePage extends StatefulWidget {
  const AnimatedRoulettePage({super.key});

  @override
  State<AnimatedRoulettePage> createState() => _AnimatedRoulettePageState();
}

class _AnimatedRoulettePageState extends State<AnimatedRoulettePage>
    with SingleTickerProviderStateMixin {
  final List<String> sectors = ['0배', '1배', '2배', '3배'];
  final List<double> probabilities = [0.1, 0.6, 0.2, 0.1];

  late AnimationController _controller;
  late Animation<double> _animation;

  double _angle = 0.0;
  String result = '';
  bool _isSpinning = false;
  int basePoint = 100;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  void _startSpin() {
    if (_isSpinning) return;

    _isSpinning = true;

    // 확률 기반 결과 선택
    String selectedSector = _selectByProbability();
    int selectedIndex = sectors.indexOf(selectedSector);

    // 룰렛은 반시계 방향이므로 angle을 반대로 계산
    double perSectorAngle = 360 / sectors.length;
    double targetAngle = 360 * 6 + (selectedIndex * perSectorAngle) + perSectorAngle / 2;

    _animation = Tween<double>(
      begin: _angle,
      end: _angle + vmath.radians(targetAngle),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    ))
      ..addListener(() {
        setState(() {
          _angle = _animation.value;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _isSpinning = false;
          int multiplier = int.parse(selectedSector[0]); // '0배' → 0
          int reward = basePoint * multiplier;
          setState(() {
            result = '🎉 $selectedSector 당첨!\n획득 포인트: $reward';
          });
        }
      });

    _controller.forward(from: 0);
  }

  String _selectByProbability() {
    final random = Random().nextDouble();
    double cumulative = 0;
    for (int i = 0; i < probabilities.length; i++) {
      cumulative += probabilities[i];
      if (random <= cumulative) {
        return sectors[i];
      }
    }
    return sectors.last;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildRouletteWheel() {
    return Transform.rotate(
      angle: _angle,
      child: CustomPaint(
        size: const Size(300, 300),
        painter: _RoulettePainter(sectors),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('룰렛')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              _buildRouletteWheel(),
              const Icon(Icons.arrow_drop_down, size: 50, color: Colors.red),
            ],
          ),
          const SizedBox(height: 20),
          Text(result, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _startSpin,
            child: const Text('룰렛 돌리기'),
          ),
        ],
      ),
    );
  }
}

class _RoulettePainter extends CustomPainter {
  final List<String> sectors;
  final List<Color> colors = [Colors.grey, Colors.blue, Colors.green, Colors.orange];

  _RoulettePainter(this.sectors);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final double sweepAngle = 2 * pi / sectors.length;
    final radius = size.width / 2;
    final center = Offset(radius, radius);

    for (int i = 0; i < sectors.length; i++) {
      paint.color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle,
        sweepAngle,
        true,
        paint,
      );

      // 텍스트
      final textPainter = TextPainter(
        text: TextSpan(
          text: sectors[i],
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final angle = (i + 0.5) * sweepAngle;
      final offset = Offset(
        center.dx + cos(angle) * radius * 0.6 - textPainter.width / 2,
        center.dy + sin(angle) * radius * 0.6 - textPainter.height / 2,
      );

      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
