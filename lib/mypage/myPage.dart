import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../custom/custom_blue_button.dart';



void main() => runApp(MyPage());


class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyPageMain(),
    );
  }
}

class MyPageMain extends StatefulWidget {
  const MyPageMain({super.key});

  @override
  State<MyPageMain> createState() => _MyPageMainState();
}

class _MyPageMainState extends State<MyPageMain> {

  int selectedTabIndex = 0;
  late List<Widget> tabContents = [];
  int selectedDeliveryTab = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tabContents = [
      myPost(),
      _orderHistory(),
      _settings()
    ];
  }


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


  // -프로필 편집 영역-

  Widget confirmExitDialog({
    required BuildContext context,
    required VoidCallback onExit,
    required VoidCallback onCancel,
  }) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 20,
      insetPadding: EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 닫기 버튼
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: onCancel,
                child: Icon(Icons.close, color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 12),

            // 타이틀
            Text(
              '저장하지 않고 나가시겠습니까?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // 서브텍스트
            Text(
              '저장하지 않으면 변경사항이 반영되지 않습니다.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // 버튼들
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: CustomBlueButton(
                    text: '나가기',
                    onPressed: onExit,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CustomBlueButton(
                    text: '취소',
                    onPressed: onCancel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget profileEditDialog(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 10,
          insetPadding: EdgeInsets.symmetric(horizontal: 40),
          child: SizedBox(
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
                        IconButton(
                          icon: Icon(Icons.settings, color: Colors.black),
                          onPressed: () {
                            showDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(0.5),
                              builder: (context) => profileEditDialog(context),
                            );
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[300],
                            child: Icon(Icons.person, size: 48, color: Colors.white),
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
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF92BBE2), width: 2),
                        ),
                        hintText: "닉네임이 들어오는 부분",
                      ),
                    ),

                    SizedBox(height: 16),

                    Text("이메일", style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF92BBE2), width: 2),
                        ),
                        hintText: "이메일이 들어오는 부분",
                      ),
                    ),

                    SizedBox(height: 16),

                    Text("주소", style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF92BBE2), width: 2),
                        ),
                        hintText: "주소를 입력해주세요",
                        hintStyle: TextStyle(color: Colors.grey[300]),
                      ),
                    ),

                    SizedBox(height: 24),

                    CustomBlueButton(
                      text: "저장하기",
                      onPressed: () {
                        Navigator.of(context).pop(); // 편집 다이얼로그 닫기 (저장 처리)
                      },
                    ),

                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // -내 게시물이 보일 부분

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


  // -주문 내역-


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
          child: Center(
            child: Text(selectedDeliveryTab == 0 ? "배송 대기 목록" : "배송 완료 목록"),
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
  
  
  
  // -환경 설정-
  
  
  // 환경 설정 콘텐츠가 보일 영역
  Widget _settings() {
    // 알림 상태 변수들
    bool bgNotification = true;
    bool commentNotification = true;
    bool likeNotification = false;

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
            _buildSettingItem("배송지 관리", () {}),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: BackButton(),
        title: Text("마이페이지", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[100],
                    child: Icon(Icons.person, size: 40, color: Colors.grey[800]),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("김춘삼", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("abcd@efg.com", style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.black),
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierColor: Colors.black.withOpacity(0.5),
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return Dialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 10,
                                insetPadding: EdgeInsets.symmetric(horizontal: 40),
                                child: SizedBox(
                                  width: 350,
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // 제목 및 닫기 버튼 Row로 묶기
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
                                                  // 저장 안 하고 나갈 때 확인 다이얼로그 띄우기
                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        title: Text('저장하지 않고 나가시겠습니까?'),
                                                        content: Text('저장하지 않으면 변경사항이 반영되지 않습니다.'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () {
                                                              // 나가기 - 편집 다이얼로그도 닫기
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
                                                    },
                                                  );
                                                },
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: 16),
                                          Center(
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                CircleAvatar(
                                                  radius: 40,
                                                  backgroundColor: Colors.grey[300],
                                                  child: Icon(Icons.person, size: 48, color: Colors.white),
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

                                          SizedBox(height: 16),

                                          Text("주소", style: TextStyle(fontWeight: FontWeight.w600)),
                                          SizedBox(height: 6),
                                          TextField(
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              enabledBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(color: Colors.grey.shade300),
                                              ),
                                              focusedBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(color: Color(0xFF92BBE2), width: 2),
                                              ),
                                              hintText: "주소를 입력해주세요",
                                              hintStyle: TextStyle(color: Colors.grey[300]),
                                            ),
                                          ),

                                          SizedBox(height: 24),

                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(0xFF92BBE2),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                padding: EdgeInsets.symmetric(vertical: 14),
                                              ),
                                              onPressed: () {
                                                Navigator.of(context).pop(); // 편집 다이얼로그 닫기 (저장 처리 위치)
                                              },
                                              child: Text(
                                                '저장하기',
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            Divider(height: 15),

            
            Expanded(
              child: Builder(
                builder: (_) {
                  if (selectedTabIndex == 0) return myPost();
                  if (selectedTabIndex == 1) return _orderHistory();
                  return _settings();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}



