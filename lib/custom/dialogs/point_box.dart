import 'package:flutter/material.dart';
import 'package:flutter_shake_animated/flutter_shake_animated.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: PointBox()),
    ),
  ));
}

class PointBox extends StatefulWidget {
  const PointBox({super.key});

  @override
  State<PointBox> createState() => _PointBoxState();
}

class _PointBoxState extends State<PointBox> {
  bool isShaking = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isShaking = !isShaking;
        });
      },
      child: isShaking
          ? ShakeWidget(
        duration: const Duration(milliseconds: 800),
        shakeConstant: ShakeDefaultConstant2(),
        autoPlay: true,
        child: Image.asset(
          'assets/point_box.png',
          width: 160,
          height: 160,
        ),
      )
          : Image.asset(
        'assets/point_box.png',
        width: 160,
        height: 160,
      ),
    );
  }
}
