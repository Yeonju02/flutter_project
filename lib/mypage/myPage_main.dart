import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';


import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';


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
  bool bgNotification = true;
  bool commentNotification = true;
  bool likeNotification = false;



  /////// -firebase- ///////

  // user의 상세 정보 가져오기
  Map<String, dynamic>? userData;

  Future<void> fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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

    Query query = FirebaseFirestore.instance.collection('orders')
        .where('userId', isEqualTo: user.uid);

    if (isCompleted) {
      // 배송 완료 목록
      query = query.where('status', isEqualTo: 'completed');
    } else {
      // 배송 대기 목록 (배송 전, 배송 중)
      query = query.where('status', whereIn: ['pending', 'shipping']);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

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
  Future<void> pickImageOnly() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source:ImageSource.gallery);
    if(image != null) {
      setState(() {
        pickedImage = image;
      });
    }
  }





  @override
  void initState() {
    super.initState();

    // 유저 데이터 불러오기
    fetchUserData();

    // 탭 컨텐츠 초기화
    tabContents = [
      myPost(),
      _orderHistory(),
      _settings()
    ];

    // 배송 대기 목록 초기 로딩
    loadOrders();
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
          fontSize: 16
        ),
      ),
    );
  }


  /////// - 프로필 편집 영역 -///////


  // 1) 닫기 버튼 눌렀을 때 나갈지 묻는 확인 다이얼로그 함수
  Widget buildCloseButtonDialog(BuildContext context) {
    return AlertDialog(
      title: Text('저장하지 않고 나가시겠습니까?'),
      content: Text('저장하지 않으면 변경사항이 반영되지 않습니다.'),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              pickedImage == null;
              if(originalImagePath != null) {
                userData?['imgPath'] = originalImagePath;
              }
            });
            Navigator.of(context).pop(); // 확인 다이얼로그 닫기
            Navigator.of(context).pop(); // 편집 다이얼로그 닫기
          },
          child: Text('나가기', style: TextStyle(color: Colors.red)),

        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // 확인 다이얼로그 닫기, 편집 유지
          },
          child: Text('취소'),
        ),
      ],
    );
  }

  // 2) 프로필 편집 내용 빌드 함수
  Widget buildProfileEditContent(BuildContext context, void Function(void Function()) setDialogState) {
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
                      final nicknameChanged = nicknameController.text != originalNickname;
                      final emailChanged = emailController.text != originalEmail;
                      final imageChanged = pickedImage != null;

                      final isChanged = nicknameChanged || emailChanged || imageChanged;

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
                        await pickImageOnly();
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: pickedImage != null
                            ? FileImage(File(pickedImage!.path))
                            : (originalImgPath != null && originalImgPath != ''
                            ? NetworkImage(originalImgPath)
                            : null),
                        child: pickedImage == null &&
                            (originalImgPath == null || originalImgPath == '')
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                        userData?['imgPath'] = downloadUrl ?? userData?['imgPath'];
                        userData?['nickName'] = nicknameController.text;
                        userData?['userEmail'] = emailController.text;
                        pickedImage = null;
                      });

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('프로필이 성공적으로 저장되었습니다.')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('저장에 실패했습니다: $e')),
                      );
                    }
                  },
                  child: Text(
                    '저장하기',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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

  // 내 게시물의 영역
  Widget _grayBox() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12)
      ),
    );
  }

  // 내 게시물 콘텐츠
  Widget myPost() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _grayBox(),
        SizedBox(height: 16,),
        _grayBox(),
      ],
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
              ? Text("로딩중...")
              : orderList.isEmpty
              ? Text("배송 내역이 없습니다.")
              : ListView.builder(
            itemCount: orderList.length,
            itemBuilder: (context, index) {
              final order = orderList[index];
              return ListTile(
                title: Text(order['productName'] ?? '상품명 없음'),
                subtitle: Text("가격: ${order['productPrice']}원"),
                trailing: Text(order['status'] == 'pending' ? '배송 대기' : '배송 완료'),
              );
            },
          ),
        ),

      ],
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
          border: Border.all(
            color: Color(0xFF272727),
            width: 1.5,
          ),
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
    // 알림 상태 변수들

    return StatefulBuilder(
      builder: (context, setState) {
        return ListView(
          padding: EdgeInsets.all(16),
          children: [

            SizedBox(height: 12,),

            // 🔔 알림 설정
            Text("알림 설정", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),

            SizedBox(height: 12,),
            Divider(),

            SizedBox(height: 12),
            _buildToggleTile("백그라운드 알림", bgNotification, (val) {
              setState(() => bgNotification = val);
            }),
            _buildToggleTile("내 게시물 댓글 알림", commentNotification, (val) {
              setState(() => commentNotification = val);
            }),
            _buildToggleTile("내 게시물 좋아요 알림", likeNotification, (val) {
              setState(() => likeNotification = val);
            }),

            SizedBox(height: 50),

            // ⚙️ 계정 설정
            Text("계정 설정", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),

            SizedBox(height: 12,),
            Divider(),
            _buildSettingItem("결제 수단 관리", () {}),
            _buildSettingItem("배송지 관리", () {
                Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeliveryAddressPage()),
              );
            }),
            _buildSettingItem("개인정보 처리방침", () {}),
            _buildSettingItem("회원 탈퇴", () {}, isDestructive: true),
          ],
        );
      },
    );
  }

  // 토글버튼
  Widget _buildToggleTile(String title, bool value, Function(bool) onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: 24, right: 0),
      title: Text(title),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: Color(0xFF92BBE2), // ON 색상
        trackColor: Colors.grey[300],    // OFF 트랙 색상
      ),
    );
  }

  Widget _buildSettingItem(String title, VoidCallback onTap, {bool isDestructive = false}) {
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
        title: const Text("마이페이지", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 기존 콘텐츠
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: userData!['imgPath'] != null && userData!['imgPath'] != ''
                          ? NetworkImage(userData!['imgPath'])
                          : null,
                      child: userData!['imgPath'] == '' ? const Icon(Icons.person, size: 40) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userData!['nickName'] ?? '', style: const TextStyle(fontSize: 20)),
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
                          context: context,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setDialogState) {
                                return Dialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 10,
                                  insetPadding: const EdgeInsets.symmetric(horizontal: 40),
                                    child: this.buildProfileEditContent(context, setDialogState)

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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopMainPage()));
                } else if (index == 1) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BoardMainScreen()));
                } else if (index == 2) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MainPage()));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}



