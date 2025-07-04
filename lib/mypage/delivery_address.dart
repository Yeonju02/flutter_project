import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class DeliveryAddressPage extends StatelessWidget {
  const DeliveryAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DeliveryAddress();
  }
}

class DeliveryAddress extends StatefulWidget {
  const DeliveryAddress({super.key});

  @override
  State<DeliveryAddress> createState() => _DeliveryAddressState();
}

class _DeliveryAddressState extends State<DeliveryAddress> {
  final user = FirebaseAuth.instance.currentUser;

  Future<List<Map<String, dynamic>>> fetchAddresses() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('address')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['docId'] = doc.id; // 문서 ID 포함
      return data;
    }).toList();
  }

  Future<void> setDefaultAddress(String selectedDocId) async {
    final addressRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('address');

    final snapshot = await addressRef.get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({
        'isDefault': doc.id == selectedDocId,
      });
    }

    setState(() {}); // 변경 사항 UI 반영
  }

  // 배송지 목록 보여주기
  void showAddAddressDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final passwordController = TextEditingController();

    final List<String> deliveryRequests = ['문 앞', '경비실', '택배함'];

    String? selectedRequest = deliveryRequests[0];
    bool isGatePasswordSelected = false;

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
                          Text('배송지 추가', style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: '받는 사람(이름)',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),

                      TextField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          hintText: '전화번호',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: UnderlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 20),

                      TextField(
                        controller: addressController,
                        decoration: InputDecoration(
                          hintText: '주소',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),

                      Text(
                        '배송 요청사항',
                        style: TextStyle(color: Color(0xFF92BBE2),
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      ...deliveryRequests.map((option) {
                        return RadioListTile<String>(
                          title: Text(option),
                          value: option,
                          groupValue: selectedRequest,
                          onChanged: (value) {
                            setState(() {
                              selectedRequest = value;
                            });
                          },
                          activeColor: Color(0xFF92BBE2),
                        );
                      }).toList(),
                      SizedBox(height: 16),

                      Text(
                        '공동 현관 출입',
                        style: TextStyle(color: Color(0xFF92BBE2),
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      RadioListTile<bool>(
                        title: Text('공동 현관 비밀번호 있음'),
                        value: true,
                        groupValue: isGatePasswordSelected,
                        onChanged: (value) {
                          setState(() {
                            isGatePasswordSelected = value!;
                          });
                        },
                        activeColor: Color(0xFF92BBE2),
                      ),
                      RadioListTile<bool>(
                        title: Text('출입 제한 없음'),
                        value: false,
                        groupValue: isGatePasswordSelected,
                        onChanged: (value) {
                          setState(() {
                            isGatePasswordSelected = value!;
                          });
                        },
                        activeColor: Color(0xFF92BBE2),
                      ),

                      if (isGatePasswordSelected)
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 16.0, right: 16, top: 8),
                          child: TextField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              hintText: '공동 현관 비밀번호 입력',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: UnderlineInputBorder(),
                            ),
                            obscureText: true,
                            keyboardType: TextInputType.number,
                          ),
                        ),

                      SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty ||
                                phoneController.text.trim().isEmpty ||
                                addressController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('이름, 전화번호, 주소를 모두 입력해주세요.')),
                              );
                              return;
                            }
                            if (isGatePasswordSelected && passwordController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('공동 현관 비밀번호를 입력해주세요.')),
                              );
                              return;
                            }

                            final addressRef = FirebaseFirestore.instance
                                .collection('users')
                                .doc(user!.uid)
                                .collection('address');

                            // 기존 주소가 하나도 없으면 처음 추가하는 주소이므로 isDefault = true
                            final snapshot = await addressRef.get();
                            final isFirst = snapshot.docs.isEmpty;

                            final data = {
                              'name': nameController.text.trim(),
                              'phone': phoneController.text.trim(),
                              'address': addressController.text.trim(),
                              'request': selectedRequest ?? '',
                              'gatePassword': isGatePasswordSelected ? passwordController.text.trim() : '없음',
                              'isDefault': isFirst,  // 처음이면 true, 아니면 false
                              'createdAt': Timestamp.now(),
                            };

                            await addressRef.add(data);
                            Navigator.pop(context);
                            setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF92BBE2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text('저장하기'),
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

    setState(() {});
  }

  // 2. 수정 다이얼로그 함수
  void showEditAddressDialog(Map<String, dynamic> addressData, String docId) {
    final nameController = TextEditingController(text: addressData['name']);
    final phoneController = TextEditingController(text: addressData['phone']);
    final addressController = TextEditingController(
        text: addressData['address']);
    final passwordController = TextEditingController(
        text: addressData['gatePassword'] == '없음'
            ? ''
            : addressData['gatePassword']);

    final List<String> deliveryRequests = ['문 앞', '경비실', '택배함'];
    String? selectedRequest = addressData['request'] ?? deliveryRequests[0];
    bool isGatePasswordSelected = addressData['gatePassword'] != null &&
        addressData['gatePassword'] != '없음';

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('배송지 수정', style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      // 이름 입력
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: '받는 사람(이름)',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),

                      // 전화번호 입력
                      TextField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          hintText: '전화번호',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: UnderlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 20),

                      // 주소 입력
                      TextField(
                        controller: addressController,
                        decoration: InputDecoration(
                          hintText: '주소',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),

                      // 배송 요청사항 라디오 그룹
                      Text(
                        '배송 요청사항',
                        style: TextStyle(color: Color(0xFF92BBE2),
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      ...deliveryRequests.map((option) {
                        return RadioListTile<String>(
                          title: Text(option),
                          value: option,
                          groupValue: selectedRequest,
                          onChanged: (value) {
                            setState(() {
                              selectedRequest = value;
                            });
                          },
                          activeColor: Color(0xFF92BBE2),
                        );
                      }).toList(),
                      SizedBox(height: 16),

                      // 공동 현관 비밀번호 선택 라디오
                      Text(
                        '공동 현관 출입',
                        style: TextStyle(color: Color(0xFF92BBE2),
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      RadioListTile<bool>(
                        title: Text('공동 현관 비밀번호 있음'),
                        value: true,
                        groupValue: isGatePasswordSelected,
                        onChanged: (value) {
                          setState(() {
                            isGatePasswordSelected = value!;
                          });
                        },
                        activeColor: Color(0xFF92BBE2),
                      ),
                      RadioListTile<bool>(
                        title: Text('출입 제한 없음'),
                        value: false,
                        groupValue: isGatePasswordSelected,
                        onChanged: (value) {
                          setState(() {
                            isGatePasswordSelected = value!;
                          });
                        },
                        activeColor: Color(0xFF92BBE2),
                      ),

                      if (isGatePasswordSelected)
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 16.0, right: 16, top: 8),
                          child: TextField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              hintText: '공동 현관 비밀번호 입력',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: UnderlineInputBorder(),
                            ),
                            obscureText: true,
                            keyboardType: TextInputType.number,
                          ),
                        ),

                      SizedBox(height: 24),

                      // 저장하기 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text
                                .trim()
                                .isEmpty ||
                                phoneController.text
                                    .trim()
                                    .isEmpty ||
                                addressController.text
                                    .trim()
                                    .isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('이름, 전화번호, 주소를 모두 입력해주세요.')),
                              );
                              return;
                            }
                            if (isGatePasswordSelected && passwordController
                                .text
                                .trim()
                                .isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('공동 현관 비밀번호를 입력해주세요.')),
                              );
                              return;
                            }

                            final data = {
                              'name': nameController.text.trim(),
                              'phone': phoneController.text.trim(),
                              'address': addressController.text.trim(),
                              'request': selectedRequest ?? '',
                              'gatePassword': isGatePasswordSelected
                                  ? passwordController.text.trim()
                                  : '없음',
                            };

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user!.uid)
                                .collection('address')
                                .doc(docId)
                                .update(data);

                            Navigator.pop(context);
                            setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF92BBE2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text('저장하기'),
                        ),
                      ),


                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          // 삭제 버튼 onPressed 부분 수정
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('배송지 삭제'),
                                content: Text('이 배송지를 삭제하시겠습니까?'),
                                actions: [
                                  TextButton(
                                    child: Text('취소'),
                                    onPressed: () => Navigator.pop(context, false),
                                  ),
                                  TextButton(
                                    child: Text('삭제'),
                                    onPressed: () => Navigator.pop(context, true),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final addressCollection = FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user!.uid)
                                  .collection('address');

                              // 현재 삭제하려는 주소가 기본 배송지인지 확인
                              final docSnapshot = await addressCollection.doc(docId).get();
                              final isDefault = docSnapshot.data()?['isDefault'] == true;

                              // 삭제
                              await addressCollection.doc(docId).delete();

                              if (isDefault) {
                                // 남은 배송지 중 가장 첫 번째 문서 가져오기
                                final remainingAddresses = await addressCollection.get();

                                if (remainingAddresses.docs.isNotEmpty) {
                                  final firstDoc = remainingAddresses.docs.first;
                                  // 기본 배송지로 변경
                                  await addressCollection.doc(firstDoc.id).update({'isDefault': true});
                                }
                              }

                              Navigator.pop(context);  // 모달 닫기
                              setState(() {});
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: Text('삭제하기'),
                        ),
                      ),

                      SizedBox(height: 30),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          '배송지 관리',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SizedBox.expand(
        child: Stack(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .collection('address')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final addresses = docs
                    .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'docId': doc.id,
                })
                    .toList();

                // 기본 배송지 위로 정렬
                addresses.sort((a, b) {
                  if (a['isDefault'] == true) return -1;
                  if (b['isDefault'] == true) return 1;
                  return 0;
                });

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      if (addresses.isEmpty) ...[
                        SizedBox(height: 100), // 약간 위쪽 띄우기용
                        Text(
                          '등록된 배송지가 없습니다.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 40),
                      ] else ...[
                        ...addresses.map((addr) {
                          return GestureDetector(
                            onTap: () async {
                              await setDefaultAddress(addr['docId']);
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: 16),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: addr['isDefault'] == true
                                      ? Colors.blueAccent
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        addr['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: addr['isDefault'] == true
                                              ? Colors.black
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                      if (addr['isDefault'] == true)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '기본 배송지',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Divider(),
                                  Text('주소',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: addr['isDefault'] == true
                                            ? Colors.black
                                            : Colors.grey.shade400,
                                      )),
                                  Text(
                                    '${addr['address']}',
                                    style: TextStyle(
                                      color: addr['isDefault'] == true
                                          ? Colors.black
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text('전화번호',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: addr['isDefault'] == true
                                            ? Colors.black
                                            : Colors.grey.shade400,
                                      )),
                                  Text(
                                    '${addr['phone']}',
                                    style: TextStyle(
                                      color: addr['isDefault'] == true
                                          ? Colors.black
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () =>
                                            showEditAddressDialog(addr, addr['docId']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          elevation: 3,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 14, horizontal: 24),
                                        ),
                                        child: Text('수정하기'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: showAddAddressDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 3,
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Center(child: Text('배송지 추가하기')),
                      ),
                    ],
                  ),
                );
              },
            ),

          ],
        ),
      ),
    );
  }

}
