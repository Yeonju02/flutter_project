import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../login/login_page.dart';
import '../board/board_main_screen.dart';
import '../main/main_page.dart';
import '../shop/shop_main.dart';
import '../admin/admin_product_page.dart';
import '../notification/notification_screen.dart';
import 'delivery_address.dart';
import 'privacy_policy_page.dart';

import '../custom/bottom_nav_bar.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MyPageMain();
  }
}

class MyPageMain extends StatefulWidget {
  const MyPageMain({super.key});

  @override
  State<MyPageMain> createState() => _MyPageMainState();
}

class _MyPageMainState extends State<MyPageMain> {
  int currentIndex = 4;
  int selectedTabIndex = 0;
  late List<Widget> tabContents = [];
  int selectedDeliveryTab = 0;

  // 유저 정보 편집 기능
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // final TextEditingController addressController = TextEditingController();

  // 환경설정의 토글버튼 true/false
  bool commentNotification = true;
  bool likeNotification = true;

  /////// -firebase- ///////

  // user의 상세 정보 가져오기
  Map<String, dynamic>? userData;

  Future<void> fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            userData = doc.data();
            nicknameController.text = userData?['nickName'] ?? '';
            emailController.text = userData?['userEmail'] ?? '';
            // addressController.text = userData?['address'] ?? '';
          });
        } else {
          print("사용자 문서가 존재하지 않습니다.");
        }
      } else {
        print("로그인된 사용자가 없습니다.");
      }
    } catch (e) {
      print("fetchUserData 에러: $e");
    }
  }

  String _getImageBySelectedColor(List<dynamic>? colorsList, String selectedColor) {
    if (colorsList == null || colorsList.isEmpty) return '';

    for (final colorMap in colorsList) {
      if (colorMap is Map<String, dynamic>) {
        final color = (colorMap['color'] ?? '').toString().toLowerCase();
        if (color == selectedColor.toLowerCase()) {
          return (colorMap['imgPath'] ?? '').toString().trim();
        }
      }
    }
    // 해당 색상 이미지 없으면 첫번째 색상 이미지 반환
    return (colorsList[0]['imgPath'] ?? '').toString().trim();
  }

// 결제 완료 + 취소 목록 가져오기
  Future<List<Map<String, dynamic>>> fetchOrderList(bool isCompleted) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final ordersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('orders');

    final query = isCompleted
        ? ordersRef.where('status', isEqualTo: '배송완료')
        : ordersRef.where('status', whereIn: ['결제완료', '취소됨']);

    final snapshot = await query.get();
    List<Map<String, dynamic>> results = [];

    for (var doc in snapshot.docs) {
      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      final productId = data['productId'];
      final selectedColor = (data['selectedColor'] ?? '').toString();

      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      final productData = productDoc.data();

      if (productData != null) {
        final colorsList = productData['colors'] as List<dynamic>?;

        final imgPath = _getImageBySelectedColor(colorsList, selectedColor);

        results.add({
          ...data,
          'documentId': doc.id,
          'productName': productData['productName'] ?? '',
          'productPrice': productData['productPrice'] ?? 0,
          'productImage': imgPath.startsWith('http') ? imgPath : '',
        });
      }
    }
    return results;
  }

  // 배송 완료 목록 가져오기
  Future<List<Map<String, dynamic>>> fetchCompletedOrderList() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final ordersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('orders');

    final query = ordersRef.where('status', isEqualTo: '배송완료');

    final snapshot = await query.get();
    List<Map<String, dynamic>> results = [];

    for (var doc in snapshot.docs) {
      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      final productId = data['productId'];
      final selectedColor = (data['selectedColor'] ?? '').toString();

      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      final productData = productDoc.data();

      if (productData != null) {
        final colorsList = productData['colors'] as List<dynamic>?;

        final imgPath = _getImageBySelectedColor(colorsList, selectedColor);

        results.add({
          ...data,
          'documentId': doc.id,
          'productName': productData['productName'] ?? '',
          'productPrice': productData['productPrice'] ?? 0,
          'productImage': imgPath.startsWith('http') ? imgPath : '',
        });
      }
    }
    return results;
  }


  List<Map<String, dynamic>> orderList = [];
  bool isLoading = true;

  void loadOrders() async {
    try {
      setState(() {
        isLoading = true;
      });

      bool isCompleted = selectedDeliveryTab == 1; // 1이면 배송 완료 목록
      orderList = await fetchOrderList(isCompleted);
    } catch (e) {
      print("배송 목록 로드 중 오류: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 1. 프로필 편집 다이얼로그 상태 변수
  XFile? pickedImage; // 이미지 저장
  String? originalImagePath; // 이미지 미리보기

  // 2. 이미지 선택 함수 (Firebase 업로드 X)
  Future<void> pickImageOnly(
      void Function(void Function()) setDialogState) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setDialogState(() {
        pickedImage = image;
      });
    }
  }


  bool? notiEnabled;

  // 현재 알림 상태 가져오기
  Future<void> _fetchNotiSetting() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef = FirebaseFirestore.instance.collection('users').doc(
        user.uid);
    final settingsDocRef = userDocRef.collection('notiSettings').doc('main');

    // notiEnable은 이미 생성된 값이라 그대로 가져옴
    final userDoc = await userDocRef.get();
    final userData = userDoc.data();
    notiEnabled = userData?['notiEnable'] ?? true;

    // notiSettings 문서 확인
    final settingsDoc = await settingsDocRef.get();

    if (settingsDoc.exists) {
      // 기존 데이터 불러오기
      final settingsData = settingsDoc.data();
      commentNotification = settingsData?['comment'] ?? true;
      likeNotification = settingsData?['like'] ?? true;
    } else {
      // 문서 없으면 기본값 생성
      commentNotification = true;
      likeNotification = true;

      await settingsDocRef.set({
        'comment': true,
        'like': true,
      });
    }

    setState(() {});
  }


  Future<void> _updateNotiEnable(bool enable) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Firestore에 notiEnable 필드 업데이트
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'notiEnable': enable,
    });

    // 전체 알림이 꺼졌거나 켜졌을 때 하위 알림 동기화
    commentNotification = enable;
    likeNotification = enable;

    // 하위 알림 설정도 Firestore에 반영
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notiSettings')
        .doc('main')
        .set({
      'comment': commentNotification,
      'like': likeNotification,
    });

    // UI 갱신
    setState(() {});
  }


  Future<void> _updateNotiSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notiSettings')
        .doc('main')
        .set({
      'comment': commentNotification,
      'like': likeNotification,
    });
  }

  List<Map<String, dynamic>> myPosts = [];

  Future<void> fetchMyPosts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('boards')
        .where('userId', isEqualTo: user.uid)
        .get();

    List<Map<String, dynamic>> postsWithThumb = [];

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> postData = doc.data();

      // boardFiles 서브컬렉션에서 isThumbNail == true인 첫번째 문서 가져오기
      final thumbQuery = await FirebaseFirestore.instance
          .collection('boards')
          .doc(doc.id)
          .collection('boardFiles')
          .where('isThumbNail', isEqualTo: true)
          .limit(1)
          .get();

      String? thumbnailPath;
      if (thumbQuery.docs.isNotEmpty) {
        thumbnailPath = thumbQuery.docs.first.data()['filePath'] as String?;
      }

      postsWithThumb.add({
        'id': doc.id,
        ...postData,
        'thumbnail': thumbnailPath,
      });
    }

    setState(() {
      myPosts = postsWithThumb;
      isLoading = false;
    });
  }


  // 회원탈퇴 ( 삭제 기능 x delete만 true로 변경함 )
  void _showDeleteAccountDialog() {
    final TextEditingController passwordController = TextEditingController();
    bool isPasswordValid = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: SizedBox(
                width: 350,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 제목과 닫기 버튼 Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "회원 탈퇴",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        Text(
                          "회원 탈퇴를 진행하려면\n비밀번호를 입력해주세요.",
                          style: TextStyle(fontSize: 16),
                        ),

                        SizedBox(height: 20),

                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "비밀번호",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            setDialogState(() {
                              isPasswordValid = val
                                  .trim()
                                  .length >= 6;
                            });
                          },
                        ),

                        SizedBox(height: 35),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPasswordValid ? Color(
                                  0xFFEF4444) : Colors.grey.shade400,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: isPasswordValid
                                ? () async {
                              final password = passwordController.text.trim();
                              bool success = await _tryDeleteAccount(password);
                              if (success) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("회원 탈퇴가 완료되었습니다.")),
                                );
                                // 탈퇴 후 추가 작업(로그아웃, 화면 이동 등) 필요
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("비밀번호가 올바르지 않습니다.")),
                                );
                              }
                            }
                                : null,
                            child: Text(
                              "탈퇴하기",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  // 로그아웃
  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: 350,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목과 닫기 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "로그아웃",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    "정말 로그아웃 하시겠습니까?",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 35),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop(); // 다이얼로그 닫고

                        // 로그아웃 처리 예시 (FirebaseAuth 기준)
                        await FirebaseAuth.instance.signOut();

                        // 로그아웃 후 로그인 페이지로 이동
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                              (route) => false,
                        );
                      },
                      child: Text(
                        "로그아웃",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 날짜 포맷 함수
  String _formatDate(dynamic createdAt) {
    try {
      if (createdAt is Timestamp) {
        DateTime dateTime = createdAt.toDate();
        return DateFormat('yyyy.MM.dd').format(dateTime);
      } else if (createdAt is DateTime) {
        return DateFormat('yyyy.MM.dd').format(createdAt);
      } else {
        return '';
      }
    } catch (e) {
      return '';
    }
  }


  Future<bool> _tryDeleteAccount(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final cred = EmailAuthProvider.credential(
        email: user.email!, password: password);

    try {
      // 재인증 시도 (비밀번호 확인)
      await user.reauthenticateWithCredential(cred);

      // 재인증 성공 시 Firestore users 문서에서 deleted true로 변경
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'deleted': true});

      // 필요하면 Firebase Auth 유저 삭제도 가능
      // await user.delete();

      return true;
    } catch (e) {
      // 비밀번호 틀림 혹은 기타 오류
      return false;
    }
  }


  @override
  void initState() {
    super.initState();

    // 유저 데이터 불러오기
    fetchUserData();

    // 탭 컨텐츠 초기화
    tabContents = [myPost(), _orderHistory(), _settings()];

    // 배송 대기 목록 초기 로딩
    loadOrders();

    // 알림 상태 가져오기
    _fetchNotiSetting();

    // 내 게시물 가져오기
    fetchMyPosts();
  }

  /////// - 내 탭 매뉴 - ///////

  Widget _buildTabButton(String title, int index) {
    final isSelected = selectedTabIndex == index;
    return TextButton(
      onPressed: () {
        setState(() {
          selectedTabIndex = index;
        });
      },
      style: ButtonStyle(
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory, // 물결 제거
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
    );
  }

  /////// - 프로필 편집 영역 -///////

  // 1) 닫기 버튼 눌렀을 때 나갈지 묻는 확인 다이얼로그 함수
  Widget buildCloseButtonDialog(BuildContext context) {
    return AlertDialog(
      title: Text(
        '변경사항을 저장하지 않고 나가시겠습니까?',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      ),
      content: Text('저장하지 않으면 변경사항이 반영되지 않습니다.'),
      actions: [
        TextButton(
          child: Text('나가기', style: TextStyle(color: Colors.red)),
          onPressed: () {
            setState(() {
              pickedImage = null;
              if (originalImagePath != null) {
                userData?['imgPath'] = originalImagePath;
              }
            });
            Navigator.of(context).pop(); // 다이얼로그 닫기
            Navigator.of(context).pop(); // 프로필 편집 닫기
          },
        ),
        TextButton(
          child: Text('취소'),
          onPressed: () {
            Navigator.of(context).pop(); // 다이얼로그 닫기만
          },
        ),
      ],
    );
  }

  // 2) 프로필 편집 내용 빌드 함수
  Widget buildProfileEditContent(BuildContext context,
      void Function(void Function()) setDialogState,) {
    final originalNickname = nicknameController.text;
    final originalEmail = emailController.text;
    final originalImgPath = userData?['imgPath'];

    return SizedBox(
      width: 350,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 제목 및 닫기 버튼 Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "프로필 편집",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      final nicknameChanged =
                          nicknameController.text != originalNickname;
                      final emailChanged =
                          emailController.text != originalEmail;
                      final imageChanged = pickedImage != null;

                      final isChanged =
                          nicknameChanged || emailChanged || imageChanged;

                      if (isChanged) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => buildCloseButtonDialog(context),
                        );
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),

              SizedBox(height: 16),

              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await pickImageOnly(setDialogState);
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage:
                        pickedImage != null
                            ? FileImage(File(pickedImage!.path))
                            : (originalImgPath != null &&
                            originalImgPath != ''
                            ? NetworkImage(originalImgPath)
                            : null),
                        child:
                        pickedImage == null &&
                            (originalImgPath == null ||
                                originalImgPath == '')
                            ? Icon(Icons.person, size: 40)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(0xFF92BBE2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              Text("내 닉네임", style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              TextField(
                controller: nicknameController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF92BBE2), width: 2),
                  ),
                  hintText: "닉네임을 입력해주세요",
                ),
              ),

              SizedBox(height: 16),

              Text("이메일", style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF92BBE2), width: 2),
                  ),
                  hintText: "이메일을 입력해주세요",
                ),
              ),

              SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF92BBE2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    try {
                      Map<String, dynamic> updateData = {
                        'nickName': nicknameController.text,
                        'userEmail': emailController.text,
                      };

                      String? downloadUrl;

                      if (pickedImage != null) {
                        final ref = FirebaseStorage.instance
                            .ref()
                            .child('user_profile_images')
                            .child('${user.uid}.jpg');

                        await ref.putFile(File(pickedImage!.path));
                        downloadUrl = await ref.getDownloadURL();
                        updateData['imgPath'] = downloadUrl;
                      }

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update(updateData);

                      setState(() {
                        userData?['imgPath'] =
                            downloadUrl ?? userData?['imgPath'];
                        userData?['nickName'] = nicknameController.text;
                        userData?['userEmail'] = emailController.text;
                        pickedImage = null;
                      });

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('프로필이 성공적으로 저장되었습니다.')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $e')));
                    }
                  },
                  child: Text(
                    '저장하기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  /////// - 내 게시물이 보일 부분 - ///////

  // 내 게시물 콘텐츠
  Widget myPost() {
    if (myPosts.isEmpty) {
      return _buildEmptyPostView();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: myPosts.length,
      itemBuilder: (context, index) {
        final post = myPosts[index];
        return _buildPostItem(post);
      },
    );
  }

  Widget _buildEmptyPostView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 72, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "작성한 게시물이 없습니다.",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              // 커뮤니티 게시판 페이지로 이동 (예시)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BoardMainScreen()),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFF272727),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFF272727), width: 1.5),
              ),
              child: Text(
                "커뮤니티 게시판 가기",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(Map<String, dynamic> post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BoardMainScreen()),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        height: 150,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.grey[200]!,
                width: 1
            )
        ),
        child: Row(
          children: [
            // 📄 왼쪽: 텍스트 영역
            Expanded(
              flex: 2, // 너비 비율 조정
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['title'] ?? '',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 15),
                    Text(
                      post['content'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(height: 1.4),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          _formatDate(post['createdAt']),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.favorite, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text('${post['likeCount'] ?? 0}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 🖼 오른쪽: 이미지 영역 (카드를 덮도록)
            ClipRRect(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: (post['thumbnail'] != null && post['thumbnail'] != '')
                  ? Image.network(
                post['thumbnail'],
                width: 150,
                height: double.infinity,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 100,
                height: double.infinity,
                color: Colors.grey[300],
                child: Icon(Icons.image_not_supported,
                    color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }


  /////// - 주문 내역 - ///////

  // 내 주문 내역이 보일 영역
  Widget _orderHistory() {

    orderList.sort((a, b) {
      if (a['status'] == b['status']) return 0;
      if (a['status'] == '취소됨') return 1; // 취소됨은 뒤로
      if (b['status'] == '취소됨') return -1;
      return 0;
    });

    final pendingOrders = orderList
        .where((order) => order['status'] == '결제완료' || order['status'] == '취소됨')
        .toList();

    final completedOrders = orderList
        .where((order) => order['status'] == '배송완료')
        .toList();

    final showList = selectedDeliveryTab == 0 ? pendingOrders : completedOrders;


    return Column(
      children: [
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDeliveryTabButton("배송 대기 목록", 0),
            SizedBox(width: 12),
            _buildDeliveryTabButton("배송 완료 목록", 1),
          ],
        ),
        SizedBox(height: 24),
        Expanded(
          child: isLoading
              ? Center(child: Text("로딩중..."))
              : showList.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  selectedDeliveryTab == 0
                      ? "주문 내역이 없습니다."
                      : "배송 완료된 상품이 없습니다.",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                SizedBox(height: 20),
                if (selectedDeliveryTab == 0) // 배송 대기 탭일 때만 버튼 표시
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ShopMainPage()),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Color(0xFF272727),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Color(0xFF272727), width: 1.5),
                      ),
                      child: Text(
                        "쇼핑하러 가기",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          )
              : ListView.builder(
            itemCount: showList.length,
            itemBuilder: (context, index) {
              final order = showList[index];
              return selectedDeliveryTab == 0
                  ? _buildPendingOrderItem(order)
                  : _buildCompletedOrderItem(order);
            },
          ),
        ),

      ],
    );
  }


  double _getProgress(String status) {
    switch (status) {
      case '결제완료':
        return 0.33;
      case '배송중':
        return 0.66;
      case '배송완료':
        return 1.0;
      default:
        return 0.0;
    }
  }

  // 결제완료 + 취소됨 주문 대기 리스트
  Widget _buildPendingOrderItem(Map<String, dynamic> order) {
    final imgUrl = (order['productImage'] ?? '').toString().trim();
    final hasImage = imgUrl.isNotEmpty && imgUrl.startsWith('http');
    final status = order['status'] ?? '';
    final selectedColor = order['selectedColor'] ?? '';

    Color _statusColor(String target) {
      if (status == '결제완료') {
        return target == '결제완료' ? Colors.black : Colors.grey.shade300;
      } else if (status == target) {
        return Colors.black;
      } else {
        return Colors.grey.shade300;
      }
    }

    double _getProgress(String status) {
      switch (status) {
        case '결제완료':
          return 0.33;
        case '배송중':
          return 0.66;
        case '배송완료':
          return 1.0;
        default:
          return 0.0;
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              hasImage
                  ? Image.network(
                imgUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.broken_image, size: 60);
                },
              )
                  : Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: Icon(Icons.image_not_supported),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['productName'] ?? '상품명 없음',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 4),
                    if (selectedColor.isNotEmpty)
                      Text("선택한 옵션: $selectedColor",
                          style: TextStyle(color: Colors.grey[700])),
                    SizedBox(height: 2),
                  ],
                ),
              ),
              Text(
                "${order['productPrice'] ?? '0'} 원",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 30),

          // status가 '취소됨'일 경우 UI 분기 처리
          if (status == '취소됨') ...[
            Align(
              alignment: Alignment.centerLeft, // 왼쪽 정렬
              child: Text(
                "주문 취소중",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 20,)
          ] else
            ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("배송 대기",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _statusColor('결제완료'),
                      )),
                  Text("배송중",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _statusColor('배송중'),
                      )),
                  Text("배송 완료",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _statusColor('배송완료'),
                      )),
                ],
              ),
              SizedBox(height: 15),
              LinearProgressIndicator(
                value: _getProgress(status),
                color: Colors.black87,
                backgroundColor: Colors.grey.shade300,
              ),
              SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () =>
                      showCancelOrderDialog(context, order['documentId']),
                  child: Text("주문 취소하기", style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
        ],
      ),
    );
  }

  // 배송 완료되자마자 보일 주문 완료 리스트
  Widget _buildCompletedOrderItem(Map<String, dynamic> order) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 상단 상태 및 교환/환불
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("배송 완료", style: TextStyle(fontSize: 12)),
              TextButton(
                onPressed: () {
                  // 교환/환불 로직
                },
                child: Text("교환/환불 신청", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                order['productImage'],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            order['productName'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "${order['productPrice']} 원",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text("상세 정보", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          Center(
            child: ElevatedButton(
              onPressed: () {
                showReviewDialog(context, order);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text("리뷰 작성하기"),
            ),
          ),
        ],
      ),
    );
  }

  // 주문 취소 다이얼로그
  void showCancelOrderDialog(BuildContext context, String documentId) {
    final TextEditingController reasonController = TextEditingController();
    final List<String> cancelReasons = [
      '단순 변심',
      '배송 지연',
      '상품이 예상과 다름',
      '상품 불량',
      '기타',
    ];
    String selectedReason = '단순 변심';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery
                      .of(context)
                      .viewInsets
                      .bottom,
                  left: 16,
                  right: 16,
                  top: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 헤더
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('주문 취소하기', style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),

                      Text('주문 취소 이유를 선택해주세요. \n주문 취소 시 결제 계좌로 자동 환불됩니다.',
                          style: TextStyle(fontWeight: FontWeight.bold,
                              color: Colors.grey[500])),
                      SizedBox(height: 5,),
                      Divider(),
                      SizedBox(height: 5,),
                      ...cancelReasons.map((reason) {
                        return RadioListTile<String>(
                          title: Text(reason),
                          value: reason,
                          groupValue: selectedReason,
                          onChanged: (value) {
                            setState(() {
                              selectedReason = value!;
                            });
                          },
                          activeColor: Colors.redAccent,
                        );
                      }).toList(),

                      if (selectedReason == '기타')
                        TextField(
                          controller: reasonController,
                          decoration: InputDecoration(
                            hintText: '취소 사유를 입력해주세요.',
                            border: UnderlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),

                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final reason = selectedReason == '기타'
                                ? reasonController.text.trim()
                                : selectedReason;

                            if (reason.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('취소 사유를 입력해주세요.')),
                              );
                              return;
                            }

                            // Firestore에 주문 상태 변경
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              final orderRef = FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('orders')
                                  .doc(documentId);

                              await orderRef.update({
                                'status': '취소됨',
                                'cancelReason': reason,
                                'cancelAt': Timestamp.now(),
                              });

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('주문이 취소되었습니다.')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text('주문 취소하기'),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  // 리뷰 작성 다이얼로그
  BuildContext? _dialogContext; // 전역처럼 써도 됨

  void showReviewDialog(BuildContext context, Map<String, dynamic> order) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "리뷰 작성",
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        _dialogContext = ctx;
        return Center(
          child: ReviewDialog(order),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation = Tween<Offset>(
          begin: Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  Widget ReviewDialog(Map<String, dynamic> order) {
    final TextEditingController reviewController = TextEditingController();
    int selectedScore = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 닫기 버튼
                  Row(
                    children: [
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  // 상품 정보
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(order['productImage'], width: 60, height: 60, fit: BoxFit.cover),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order['productName'], style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text("상세 정보", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text("${order['productPrice']} 원", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),

                  SizedBox(height: 20),

                  // 별점 선택 (간격 줄인 버전)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedScore = starIndex;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4), // 간격 줄임
                          child: Icon(
                            selectedScore >= starIndex ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        ),
                      );
                    }),
                  ),

                  SizedBox(height: 20),

                  // 리뷰 입력 (배경색 추가 + 높이 넉넉하게)
                  Container(
                    height: 150,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5), // 연한 회색 배경
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: reviewController,
                      maxLines: null,
                      decoration: InputDecoration.collapsed(
                        hintText: "리뷰를 작성해주세요.\n비속어나 규정 위반 내용은 삭제될 수 있습니다.",
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // 저장 버튼
                  ElevatedButton(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      try {
                        final reviewData = {
                          'userId': user.uid,
                          'score': selectedScore,
                          'contents': reviewController.text,
                          'createAt': Timestamp.now(),
                        };

                        await FirebaseFirestore.instance
                            .collection('products')
                            .doc(order['productId'])
                            .collection('reviews')
                            .doc(user.uid)
                            .set(reviewData);

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('리뷰가 저장되었습니다.')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('리뷰 저장 실패: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF92BBE2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                    ),
                    child: Text("저장하기"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  // 배송 대기 목록 & 배송 완료 목록 버튼 활성화/비활성화 부분
  Widget _buildDeliveryTabButton(String title, int index) {
    final bool isSelected = selectedDeliveryTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDeliveryTab = index;
        });
        loadOrders();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF272727) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF272727), width: 1.5),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Color(0xFF272727),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /////// - 환경 설정- ///////

  // 고객센터 다이얼로그
  void showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: 350,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 + 닫기 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "고객센터",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // 내용 텍스트
                  Text(
                    "고객센터 기능은 추후 개발 예정입니다.",
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),

                  SizedBox(height: 35),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _settings() {
    return StatefulBuilder(
      builder: (context, setState) {
        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            SizedBox(height: 12),
            Text("알림 설정",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Divider(),

            // 기존 알림 설정 토글들
            _buildToggleTile("전체 알림 받기", notiEnabled ?? true, (val) async {
              notiEnabled = val;
              await _updateNotiEnable(val);
              setState(() {});
            }),
            _buildToggleTile("내 게시물 댓글 알림", commentNotification, (val) async {
              commentNotification = val;
              await _updateNotiSettings();
              setState(() {});
            }, enabled: notiEnabled ?? true),
            _buildToggleTile("내 게시물 좋아요 알림", likeNotification, (val) async {
              likeNotification = val;
              await _updateNotiSettings();
              setState(() {});
            }, enabled: notiEnabled ?? true),

            SizedBox(height: 30),
            Text("계정 설정",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Divider(),
            _buildSettingItem("배송지 관리", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeliveryAddressPage()),
              );
            }),
            _buildSettingItem("개인정보 처리방침", () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrivacyPolicyPage()));
            }),
            _buildSettingItem("로그아웃", () {
              _showLogoutDialog();
            }),
            _buildSettingItem("회원 탈퇴", () {
              _showDeleteAccountDialog();
            }, isDestructive: true),

            SizedBox(height: 30),

            // 고객센터 섹션 추가
            Text("고객센터",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Divider(),
            _buildSettingItem("문의하기", () { showComingSoonDialog(context); }),


            SizedBox(height: 50),
          ],
        );
      },
    );
  }


  // 토글버튼
  Widget _buildToggleTile(String title,
      bool value,
      Function(bool) onChanged, {
        bool enabled = true,
      }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: IgnorePointer(
        ignoring: !enabled,
        child: ListTile(
          contentPadding: EdgeInsets.only(left: 24, right: 0),
          title: Text(title,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          trailing: CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF92BBE2),
            trackColor: Colors.grey[300],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title,
      VoidCallback onTap, {
        bool isDestructive = false,
      }) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 24, right: 8),
          title: Text(
            title,
            style: TextStyle(
              color: isDestructive ? Color(0xFFDA2B2B) : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
        ),
        // Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('마이페이지',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        actions: [
          if (userData != null && userData!['status'] == 'A')
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Color(0xFF272727),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.transparent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminProductPage(),
                    ),
                  );
                },
                icon: Icon(Icons.admin_panel_settings, size: 18),
                label: Text("관리자"),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage:
                      userData!['imgPath'] != null &&
                          userData!['imgPath'] != ''
                          ? NetworkImage(userData!['imgPath'])
                          : null,
                      child:
                      userData!['imgPath'] == ''
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData!['nickName'] ?? '',
                            style: const TextStyle(fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(userData!['userEmail'] ?? ''),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black),
                      onPressed: () async {
                        originalImagePath = userData?['imgPath'];
                        pickedImage = null;

                        await fetchUserData();

                        showGeneralDialog(
                          context: context,
                          barrierDismissible: false,
                          barrierLabel: "프로필 편집",
                          transitionDuration: Duration(milliseconds: 300),
                          pageBuilder: (context, animation, secondaryAnimation) {
                            return Center(
                              child: Material(
                                color: Colors.transparent,
                                child: StatefulBuilder(
                                  builder: (context, setDialogState) {
                                    return Dialog(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 10,
                                      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
                                      child: buildProfileEditContent(context, setDialogState),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                          transitionBuilder: (context, animation, secondaryAnimation, child) {
                            final curvedValue = Curves.easeOut.transform(animation.value);
                            return Transform.translate(
                              offset: Offset(0, 50 * (1 - curvedValue)),
                              child: Opacity(
                                opacity: curvedValue,
                                child: child,
                              ),
                            );
                          },
                        );
                      },
                    ),

                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTabButton("내 게시물", 0),
                  _buildTabButton("주문 내역", 1),
                  _buildTabButton("환경 설정", 2),
                ],
              ),
              const Divider(height: 15),
              SizedBox(height: 10,),
              Expanded(
                child: Builder(
                  builder: (_) {
                    if (selectedTabIndex == 0) return myPost();
                    if (selectedTabIndex == 1) return _orderHistory();
                    return _settings();
                  },
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),

          // 하단 네비게이션
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: BottomNavBar(
              currentIndex: 4,
              onTap: (index) {
                if (index == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShopMainPage(),
                    ),
                  );
                } else if (index == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BoardMainScreen(),
                    ),
                  );
                } else if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MainPage()),
                  );
                } else if (index == 3) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationScreen(),)
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
