import 'package:flutter/material.dart';
import 'dart:math';

class XpAnimation extends StatefulWidget {
  final int xp;

  const XpAnimation({super.key, required this.xp});

  @override
  State<XpAnimation> createState() => _XpAnimationState();
}

class _XpAnimationState extends State<XpAnimation> with TickerProviderStateMixin {
  late AnimationController _burstController;

  @override
  void initState() {
    super.initState();

    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _burstController.forward();
  }

  @override
  void dispose() {
    _burstController.dispose();
    super.dispose();
  }

  Widget _buildParticle({required double angleDeg, required double distance, required double size, required Color color}) {
    final angle = angleDeg * pi / 180;
    final offset = Offset(cos(angle), sin(angle)) * distance;

    return AnimatedBuilder(
      animation: _burstController,
      builder: (_, __) {
        final scale = Curves.easeOut.transform(_burstController.value);
        return Transform.translate(
          offset: offset * scale,
          child: Opacity(
            opacity: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 하늘색 원 4개
        _buildParticle(angleDeg: 22, distance: 105, size: 12, color: const Color(0xFF68E3FF)),
        _buildParticle(angleDeg: 70, distance: 60, size: 8, color: const Color(0xFF68E3FF)),
        _buildParticle(angleDeg: 178, distance: 83, size: 9, color: const Color(0xFF68E3FF)),
        _buildParticle(angleDeg: 230, distance: 77, size: 8, color: const Color(0xFF68E3FF)),

        // 노란색 원 3개
        _buildParticle(angleDeg: 45, distance: 70, size: 15, color: const Color(0xFFFFC83E)),
        _buildParticle(angleDeg: 165, distance: 65, size: 13, color: const Color(0xFFFFC83E)),
        _buildParticle(angleDeg: -60, distance: 68, size: 23, color: const Color(0xFFFFC83E)),

        // 남색 원 5개
        _buildParticle(angleDeg: 5, distance: 75, size: 25, color: const Color(0xFF1D3250)),
        _buildParticle(angleDeg: -20, distance: 82, size: 8, color: const Color(0xFF1D3250)),
        _buildParticle(angleDeg: -32, distance: 75, size: 12, color: const Color(0xFF1D3250)),
        _buildParticle(angleDeg: 200, distance: 65, size: 16, color: const Color(0xFF1D3250)),
        _buildParticle(angleDeg: 135, distance: 77, size: 20, color: const Color(0xFF1D3250)),


        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF92BBE2),
          ),
          alignment: Alignment.center,
          child: Text(
            "+ ${widget.xp}XP",
            style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
