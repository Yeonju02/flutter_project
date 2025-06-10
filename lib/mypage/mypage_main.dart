import 'package:flutter/material.dart';

void main()=> runApp(myPageMain());

class myPageMain extends StatefulWidget {
  const myPageMain({super.key});

  @override
  State<myPageMain> createState() => _myPageMainState();
}

class _myPageMainState extends State<myPageMain> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(), // 뒤로가기 버튼
        title: Text("마이페이지"),
      ),
      body: Container(),
    );
  }
}

