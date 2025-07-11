import 'package:flutter/material.dart';
import 'package:flutter_shake_animated/flutter_shake_animated.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'point_roulette.dart';
import 'choice_dialog.dart'; // 추가

class PointBoxDialog extends StatefulWidget {
  final String userDocId;

  const PointBoxDialog({super.key, required this.userDocId});

  @override
  State<PointBoxDialog> createState() => _PointBoxDialogState();
}

class _PointBoxDialogState extends State<PointBoxDialog> with TickerProviderStateMixin {
  bool isShaking = false;
  bool showSmoke = false;
  bool isUsed = false;
  bool showPointText = false;
  double usedOpacity = 0.0;

  AnimationController? _smokeController;
  Animation<double>? _scaleAnimation;

  AnimationController? _textScaleController;
  Animation<double>? _textScaleAnimation;

  @override
  void initState() {
    super.initState();

    _smokeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scaleAnimation = Tween<double>(begin: 0.15, end: 1.0).animate(
      CurvedAnimation(parent: _smokeController!, curve: Curves.easeOut),
    );

    _textScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textScaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _textScaleController!, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _smokeController?.dispose();
    _textScaleController?.dispose();
    super.dispose();
  }

  void _onTap() async {
    if (isShaking) return;

    if (!mounted) return;
    setState(() {
      isShaking = true;
      showSmoke = false;
      isUsed = false;
      usedOpacity = 0.0;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() {
      isShaking = false;
      showSmoke = true;
    });

    _smokeController?.forward(from: 0.0);

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() {
      showSmoke = false;
      isUsed = true;
      showPointText = true;
    });

    _textScaleController?.forward(from: 0.0);

    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;
    setState(() {
      usedOpacity = 1.0;
    });
  }

  Future<void> _addFixedPoint(int value) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(widget.userDocId);
    final snapshot = await docRef.get();
    final currentPoint = (snapshot.data()?['point'] ?? 0) as int;
    await docRef.update({'point': currentPoint + value});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: _onTap,
        child: SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isShaking)
                ShakeWidget(
                  duration: const Duration(seconds: 5),
                  shakeConstant: ShakeDefaultConstant1(),
                  autoPlay: true,
                  child: Image.asset('assets/point_box.png', width: 160, height: 160),
                )
              else if (!isUsed)
                Image.asset('assets/point_box.png', width: 160, height: 160)
              else
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: usedOpacity,
                  child: Image.asset('assets/used_point_box.png', width: 160, height: 160),
                ),

              if (showSmoke && _scaleAnimation != null)
                ScaleTransition(
                  scale: _scaleAnimation!,
                  child: Image.asset('assets/smoke.png', width: 350, height: 350),
                ),

              if (showPointText && _textScaleAnimation != null)
                GestureDetector(
                  onTap: () async {
                    final shouldSpin = await showChoiceDialog(
                      context: context,
                      title: '룰렛 도전',
                      content: '룰렛을 돌려 추가 포인트에 도전할까요?',
                    );

                    if (!mounted) return;

                    if (shouldSpin == true) {
                      showDialog(
                        context: context,
                        builder: (_) => PointRouletteDialog(userDocId: widget.userDocId),
                      );

                    } else {
                      await _addFixedPoint(100);
                      if (mounted) Navigator.of(context).pop();
                    }
                  },
                  child: ScaleTransition(
                    scale: _textScaleAnimation!,
                    child: Text(
                      '+100 POINT',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                        shadows: [
                          const Shadow(offset: Offset(1, 1), blurRadius: 2.0, color: Colors.black26),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
