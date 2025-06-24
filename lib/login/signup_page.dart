import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../custom/custom_blue_button.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool agree = false;
  String? selectedEmailDomain;

  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nickNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String passwordStatus = '';
  String confirmPasswordStatus = '';
  Color passwordStatusColor = Colors.red;
  Color confirmPasswordStatusColor = Colors.red;

  bool isUserIdChecked = false;
  bool isNickNameChecked = false;

  final List<String> emailDomains = [
    'naver.com',
    'gmail.com',
    'hanmail.net',
    'kakao.com',
  ];

  @override
  void initState() {
    super.initState();

    passwordController.addListener(() {
      final pwd = passwordController.text;
      final valid = _validatePassword(pwd);

      setState(() {
        if (valid) {
          passwordStatus = '조건 충족';
          passwordStatusColor = Colors.green;
        } else {
          passwordStatus = '비밀번호는 6~20자이며 대소문자, 숫자, 특수문자를 포함해야 합니다.';
          passwordStatusColor = Colors.red;
        }

        _checkPasswordMatch();
      });
    });

    confirmPasswordController.addListener(() {
      _checkPasswordMatch();
    });
  }

  @override
  void dispose() {
    userIdController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nickNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  bool _validatePassword(String password) {
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*])[A-Za-z\d!@#\$%^&*]{6,20}$');
    return regex.hasMatch(password);
  }

  void _checkPasswordMatch() {
    final pwd = passwordController.text;
    final confirmPwd = confirmPasswordController.text;

    setState(() {
      if (confirmPwd.isEmpty) {
        confirmPasswordStatus = '';
      } else if (pwd == confirmPwd) {
        confirmPasswordStatus = '사용 가능한 비밀번호입니다.';
        confirmPasswordStatusColor = Colors.green;
      } else {
        confirmPasswordStatus = '비밀번호가 일치하지 않습니다.';
        confirmPasswordStatusColor = Colors.red;
      }
    });
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _handleSignup() async {
    final userId = userIdController.text.trim();
    final pwd = passwordController.text;
    final confirmPwd = confirmPasswordController.text;
    final nick = nickNameController.text.trim();
    final emailLocal = emailController.text.trim();
    final emailDomain = selectedEmailDomain;

    if (userId.isEmpty || pwd.isEmpty || confirmPwd.isEmpty || nick.isEmpty || emailLocal.isEmpty || emailDomain == null) {
      _showToast("모든 항목을 입력해주세요.");
      return;
    }

    if (!isUserIdChecked) {
      _showToast("아이디 중복 확인을 해주세요.");
      return;
    }

    if (!isNickNameChecked) {
      _showToast("닉네임 중복 확인을 해주세요.");
      return;
    }

    if (!_validatePassword(pwd)) {
      _showToast("비밀번호 조건을 충족해주세요.");
      return;
    }

    if (pwd != confirmPwd) {
      _showToast("비밀번호가 일치하지 않습니다.");
      return;
    }

    if (!agree) {
      _showToast("약관에 동의해야 합니다.");
      return;
    }

    final email = '$emailLocal@$emailDomain';

    try {
      // Firebase Auth 회원가입
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pwd);

      final user = userCredential.user;
      if (user == null) {
        _showToast("회원가입 실패: 사용자 생성 실패");
        return;
      }

      // 이메일 인증 메일 전송
      await user.sendEmailVerification();
      _showToast("이메일 인증 메일을 보냈습니다. 이메일을 확인해주세요.");

      // 이메일 인증 대기
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("이메일 인증 확인"),
          content: Text("이메일 인증을 완료하셨나요?\n확인 후 '네'를 눌러주세요."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("아니요"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("네"),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        _showToast("이메일 인증 후 다시 시도해주세요.");
        await FirebaseAuth.instance.currentUser?.delete();
        return;
      }

      // 인증 여부 재확인
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser == null || !refreshedUser.emailVerified) {
        _showToast("이메일 인증이 아직 완료되지 않았습니다.");
        await FirebaseAuth.instance.currentUser?.delete();
        return;
      }

      final uid = refreshedUser.uid;

      // Firestore에 유저 정보 저장
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'userId': userId,
        'nickName': nick,
        'userEmail': email,
        'level': 1,
        'xp': 0,
        'streakCount': 0,
        'maxStreak': 0,
        'joinedAt': Timestamp.now(),
        'deleted': false,
        'notiEnable': true,
        'address': '',
        'imgPath': '',
        'status': 'U'
      });

      _showToast("회원가입 완료");
      Navigator.pop(context);
    } catch (e) {
      _showToast("회원가입 실패: ${e.toString()}");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text('회원가입', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('아이디'),
              Row(
                children: [
                  Expanded(child: _buildInput(hint: '아이디', controller: userIdController)),
                  SizedBox(width: 8),
                  _buildSmallButton('중복확인', onPressed: () async {
                    final input = userIdController.text.trim();
                    if (input.isEmpty) return;

                    final exists = await isUserIdDuplicate(input);
                    setState(() {
                      isUserIdChecked = !exists;
                    });

                    final msg = exists ? '이미 사용 중인 아이디입니다.' : '사용 가능한 아이디입니다.';
                    _showToast(msg);
                  }),
                ],
              ),
              SizedBox(height: 4),
              _buildHelperText('4~12자 / 영문 소문자 (숫자 조합 가능)'),

              SizedBox(height: 24),
              _buildLabel('비밀번호'),
              _buildInput(hint: '비밀번호', controller: passwordController, obscure: true),
              SizedBox(height: 4),
              Text(passwordStatus, style: TextStyle(color: passwordStatusColor, fontSize: 12)),

              SizedBox(height: 12),
              _buildInput(hint: '비밀번호 확인', controller: confirmPasswordController, obscure: true),
              SizedBox(height: 4),
              Text(confirmPasswordStatus, style: TextStyle(color: confirmPasswordStatusColor, fontSize: 12)),

              SizedBox(height: 24),
              _buildLabel('닉네임'),
              Row(
                children: [
                  Expanded(child: _buildInput(hint: '닉네임', controller: nickNameController)),
                  SizedBox(width: 8),
                  _buildSmallButton('중복확인', onPressed: () async {
                    final input = nickNameController.text.trim();
                    if (input.isEmpty) return;

                    final exists = await isNickNameDuplicate(input);
                    setState(() {
                      isNickNameChecked = !exists;
                    });

                    final msg = exists ? '이미 사용 중인 닉네임입니다.' : '사용 가능한 닉네임입니다.';
                    _showToast(msg);
                  }),
                ],
              ),
              SizedBox(height: 4),
              _buildHelperText('규정에 어긋나는 비속어를 포함할 수 없습니다.'),

              SizedBox(height: 24),
              _buildLabel('이메일'),
              Row(
                children: [
                  Expanded(child: _buildInput(hint: '이메일', controller: emailController)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('@'),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      hint: Text('선택'),
                      items: emailDomains
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedEmailDomain = value;
                        });
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),
              Row(
                children: [
                  Checkbox(
                    value: agree,
                    onChanged: (val) {
                      setState(() {
                        agree = val ?? false;
                      });
                    },
                  ),
                  Text('어플의 지침에 동의합니다'),
                ],
              ),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA5C8F8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('회원가입', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildHelperText(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 4.0),
      child: Text(text, style: TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }

  Widget _buildSmallButton(String text, {required VoidCallback onPressed}) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA5C8F8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}
// id중복검사
Future<bool> isUserIdDuplicate(String userId) async {
  final query = await FirebaseFirestore.instance
      .collection('users')
      .where('userId', isEqualTo: userId)
      .get();
  return query.docs.isNotEmpty;
}
// 닉네임중복검사
Future<bool> isNickNameDuplicate(String nickName) async {
  final query = await FirebaseFirestore.instance
      .collection('users')
      .where('nickName', isEqualTo: nickName)
      .get();
  return query.docs.isNotEmpty;
}
