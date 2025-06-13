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
import 'delivery_address.dart';

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

  // 배송 대기, 배송 완료 목록 가져오기
  Future<List<Map<String, dynamic>>> fetchOrderList(bool isCompleted) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    Query query = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid);

    if (isCompleted) {
      // 배송 완료 목록
      query = query.where('status', isEqualTo: 'completed');
    } else {
      // 배송 대기 목록 (배송 전, 배송 중)
      query = query.where('status', whereIn: ['pending', 'shipping']);
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
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
  Future<void> pickImageOnly(void Function(void Function()) setDialogState) async {
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

    // notiEnable 필드 가져오기
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data();
      notiEnabled = userData?['notiEnable'] ?? true;
    } else {
      notiEnabled = true;
    }

    // notiSettings 서브 컬렉션 문서 가져오기
    final settingsDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notiSettings')
        .doc('main')
        .get();

    if (settingsDoc.exists) {
      final settingsData = settingsDoc.data();
      commentNotification = settingsData?['comment'] ?? true;
      likeNotification = settingsData?['like'] ?? true;
    } else {
      commentNotification = true;
      likeNotification = true;
    }

    // 상태 갱신
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              isPasswordValid = val.trim().length >= 6;
                            });
                          },
                        ),

                        SizedBox(height: 35),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPasswordValid ? Color(0xFFEF4444) : Colors.grey.shade400,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

    final cred = EmailAuthProvider.credential(email: user.email!, password: password);

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
  Widget buildProfileEditContent(
    BuildContext context,
    void Function(void Function()) setDialogState,
  ) {
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['title'] ?? '',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              : orderList.isEmpty
              ? _buildEmptyOrderView()
              : ListView.builder(
            itemCount: orderList.length,
            itemBuilder: (context, index) {
              final order = orderList[index];
              return order['status'] == 'pending'
                  ? _buildPendingOrderItem(order)
                  : _buildCompletedOrderItem(order);
            },
          ),
        ),
      ],
    );
  }
  Widget _buildPendingOrderItem(Map<String, dynamic> order) {
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
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("배송 대기", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("배송중", style: TextStyle(color: Colors.grey)),
              Text("배송 완료", style: TextStyle(color: Colors.grey)),
            ],
          ),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: 0.33,
            color: Colors.black87,
            backgroundColor: Colors.grey.shade300,
          ),
          SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                // 주문 취소 로직
              },
              child: Text("주문 취소하기", style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

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
          Row(
            children: [
              Image.network(order['productImage'], width: 60, height: 60, fit: BoxFit.cover),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text("배송 완료", style: TextStyle(fontSize: 12)),
                        Spacer(),
                        TextButton(
                          onPressed: () {
                            // 교환/환불 로직
                          },
                          child: Text("교환/환불 신청", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                    Text(order['productName'], style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("상세 정보", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Text("${order['productPrice']} 원", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: () {
                // 리뷰 작성 로직
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





  Widget _buildEmptyOrderView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "배송 내역이 없습니다.",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          SizedBox(height: 20),
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

  // 환경 설정 콘텐츠가 보일 영역
  Widget _settings() {
    return StatefulBuilder(
      builder: (context, setState) {
        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            SizedBox(height: 12),
            Text("알림 설정", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Divider(),

            // 전체 알림
            _buildToggleTile("전체 알림 받기", notiEnabled ?? true, (val) async {
              notiEnabled = val;
              await _updateNotiEnable(val);
              setState(() {});
            }),

            // 댓글 알림
            _buildToggleTile("내 게시물 댓글 알림", commentNotification, (val) async {
              commentNotification = val;
              await _updateNotiSettings();
              setState(() {});
            }, enabled: notiEnabled ?? true),

            // 좋아요 알림
            _buildToggleTile("내 게시물 좋아요 알림", likeNotification, (val) async {
              likeNotification = val;
              await _updateNotiSettings();
              setState(() {});
            }, enabled: notiEnabled ?? true),

            SizedBox(height: 50),
            Text("계정 설정", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Divider(),
            _buildSettingItem("배송지 관리", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeliveryAddressPage()),
              );
            }),
            _buildSettingItem("개인정보 처리방침", () {}),
            _buildSettingItem("로그아웃", () {
              _showLogoutDialog();
            }),
            _buildSettingItem("회원 탈퇴", () {
              _showDeleteAccountDialog();
            }, isDestructive: true),
            SizedBox(height: 50),
          ],
        );
      },
    );
  }

  // 토글버튼
  Widget _buildToggleTile(
    String title,
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
          title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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

  Widget _buildSettingItem(
    String title,
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
        title: const Text('마이페이지', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // 기존 콘텐츠
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
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(userData!['userEmail'] ?? ''),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.black),
                      onPressed: () async {
                        originalImagePath = userData?['imgPath'];
                        pickedImage = null;

                        await fetchUserData();
                        showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setDialogState) {
                                return Dialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 10,
                                  insetPadding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                  ),
                                  child: this.buildProfileEditContent(
                                    context,
                                    setDialogState,
                                  ),
                                );
                              },
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
              const SizedBox(height: 80), // 네비게이션 바 높이 고려 여유 공간
            ],
          ),

          // 하단 네비게이션 삽입
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: BottomNavBar(
              currentIndex: 4, // 마이페이지니까 4번
              onTap: (index) {
                if (index == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ShopMainPage(),
                    ),
                  );
                } else if (index == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BoardMainScreen(),
                    ),
                  );
                } else if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MainPage()),
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
