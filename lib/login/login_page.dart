import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main/main_page.dart';
import 'find_account_page.dart';
import 'signup_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userIdController = TextEditingController();
  final passwordController = TextEditingController();

  final Color fieldColor = const Color(0xFFF5F7FA);
  final Color buttonColor = const Color(0xFFA5C8F8);

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  Future<void> _handleLogin() async {
    String userId = userIdController.text.trim();
    String password = passwordController.text.trim();

    if (userId.isEmpty || password.isEmpty) {
      _showToast("아이디와 비밀번호를 입력하세요.");
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _showToast("존재하지 않는 아이디입니다.");
        return;
      }

      final userDoc = query.docs.first;
      final userEmail = userDoc['userEmail'];
      final isDeleted = userDoc['deleted'] ?? false;
      
      if (isDeleted == true) {
        _showToast("탈퇴한 회원입니다. 로그인할 수 없습니다.");
        return;
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userEmail,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
      await prefs.setString('userEmail', userEmail);

      _showToast("로그인 성공");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } catch (e) {
      _showToast("로그인 실패: ${e.toString()}");
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      // 먼저 기존 계정 로그아웃
      await GoogleSignIn().signOut();

      // 그 다음 로그인 시도 → 항상 계정 선택창이 뜸
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _showToast("구글 로그인이 취소되었습니다.");
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Firestore에 사용자 정보 저장 (처음 로그인 시)
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .where('userEmail', isEqualTo: user.email)
            .limit(1)
            .get();

        if (userDoc.docs.isEmpty) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'userId': user.email!.split('@').first,
            'userEmail': user.email,
            'nickName': user.displayName ?? '사용자',
            'imgPath': user.photoURL ?? '',
            'joinedAt': Timestamp.now(),
            'status': 'U',
            'level': 1,
            'xp': 0,
            'streakCount': 0,
            'maxStreak': 0,
            'deleted': false,
            'notiEnable': true,
            'address': '',
            'point': 0
          });
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', user.email ?? '');
        await prefs.setString('userId', user.email!.split('@').first);

        _showToast("구글 로그인 성공!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      }
    } catch (e) {
      _showToast("구글 로그인 실패: ${e.toString()}");
    }
  }


  Widget _buildInputField(String hint, TextEditingController controller, {bool obscure = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Image.asset(
                        'assets/logo2.png',
                        height: 150,
                      ),
                      const SizedBox(height: 50),
                      _buildInputField('아이디', userIdController),
                      _buildInputField('비밀번호', passwordController, obscure: true),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text('로그인', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: const [
                          Expanded(child: Divider(color: Colors.grey)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('또는', style: TextStyle(color: Colors.grey)),
                          ),
                          Expanded(child: Divider(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      InkWell(
                        onTap: _handleGoogleLogin,
                        child: Image.asset(
                          'assets/google_icon.png',
                          height: 60,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => SignupPage()));
                            },
                            child: const Text("회원가입", style: TextStyle(color: Color(0xFF7EA9D2))),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const FindAccountPage()));
                            },
                            child: const Text('아이디/비밀번호 찾기', style: TextStyle(color: Color(0xFF7EA9D2))),
                          ),
                          const Text('문의하기', style: TextStyle(color: Color(0xFF7EA9D2))),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
