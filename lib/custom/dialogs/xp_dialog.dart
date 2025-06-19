import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../effect/xp_animation.dart';
import '../dialogs/point_box_dialog.dart';

class XpDialog extends StatefulWidget {
  final int currentLevel;
  final int currentXP;
  final int earnedXP;
  final String userDocId;

  const XpDialog({
    super.key,
    required this.currentLevel,
    required this.currentXP,
    required this.earnedXP,
    required this.userDocId,
  });

  @override
  State<XpDialog> createState() => _XpDialogState();
}

class _XpDialogState extends State<XpDialog> with TickerProviderStateMixin {
  late AnimationController _barController;
  late Animation<double> _progressAnimation;

  int displayLevel = 0;
  int xpInBar = 0;
  bool showXPText = false;

  List<int> xpStages = [];
  int currentStage = 0;
  bool didLevelUp = false;

  @override
  void initState() {
    super.initState();

    displayLevel = widget.currentLevel;
    int remainingXP = widget.earnedXP;
    int currentXP = widget.currentXP;

    if (currentXP + remainingXP <= 100) {
      xpStages.add(currentXP + remainingXP);
    } else {
      xpStages.add(100);
      remainingXP -= (100 - currentXP);
      while (remainingXP >= 100) {
        xpStages.add(100);
        remainingXP -= 100;
      }
      if (remainingXP > 0) xpStages.add(remainingXP);
    }

    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _startNextAnimation(from: currentXP.toDouble());

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        showXPText = true;
      });
    });
  }

  void _startNextAnimation({required double from}) {
    if (currentStage >= xpStages.length) return;

    final to = xpStages[currentStage].toDouble();

    _progressAnimation = Tween<double>(
      begin: from / 100,
      end: to / 100,
    ).animate(CurvedAnimation(
      parent: _barController,
      curve: Curves.easeInOut,
    ))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (!mounted) return;
          setState(() {
            xpInBar = xpStages[currentStage];
          });

          if (xpInBar == 100) {
            displayLevel += 1;
            xpInBar = 0;
            didLevelUp = true;
          }

          currentStage += 1;

          if (currentStage < xpStages.length) {
            _startNextAnimation(from: 0);
          } else {
            FirebaseFirestore.instance.collection('users').doc(widget.userDocId).update({
              'xp': xpInBar,
              'level': displayLevel,
            }).then((_) {
              if (didLevelUp && mounted) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (!mounted) return;
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => PointBoxDialog(userDocId: widget.userDocId),
                  );
                });
              }
            }).catchError((e) {
              print("저장 실패: $e");
            });
          }
        }
      });

    _barController.reset();
    _barController.forward();
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            XpAnimation(xp: widget.earnedXP),
            const SizedBox(height: 30),
            AnimatedBuilder(
              animation: _barController,
              builder: (context, child) {
                final currentAnimatedXP =
                (_progressAnimation.value * 100).round().clamp(0, 100);
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Lv. $displayLevel", style: const TextStyle(color: Colors.black87)),
                        Text("$currentAnimatedXP / 100 XP",
                            style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _progressAnimation.value.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade300,
                      color: Colors.lightBlue,
                      minHeight: 12,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: showXPText ? 1.0 : 0.0,
              child: Text(
                "경험치 ${widget.earnedXP}XP 획득!",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB3D4F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text("돌아가기", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
