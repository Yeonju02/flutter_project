import 'package:flutter/material.dart';


//사용시에는 아래처럼 쓰면 됨
//CustomBlueButton(
//  text: '보여줄 텍스트',
//  onPressed: () {
//    //실행할 함수
//  },
//),
class CustomBlueButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomBlueButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF92BBE2),
        minimumSize: Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}
