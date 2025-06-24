import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '개인정보 처리방침',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPolicySection(
                  '1. 수집하는 개인정보 항목',
                  '앱은 다음과 같은 정보를 수집할 수 있습니다:\n- 이메일 주소\n- 닉네임\n- 아침 루틴 및 수면 시간 설정 정보',
                ),
                _buildPolicySection(
                  '2. 개인정보의 수집 및 이용 목적',
                  '수집된 정보는 다음의 목적에 사용됩니다:\n- 사용자 맞춤 아침 루틴 및 수면 시간 추천\n- 사용자 프로필 식별 및 데이터 저장',
                ),
                _buildPolicySection(
                  '3. 개인정보의 보관 및 이용 기간',
                  '개인정보는 사용자가 앱을 이용하는 동안 보관되며, 탈퇴 요청 시 즉시 삭제됩니다.',
                ),
                _buildPolicySection(
                  '4. 제3자 제공 및 위탁',
                  '앱은 개인정보를 외부에 제공하거나 위탁하지 않습니다.',
                ),
                _buildPolicySection(
                  '5. 이용자의 권리',
                  '이용자는 앱 내에서 자신의 개인정보를 열람, 수정하거나 삭제를 요청할 수 있습니다.',
                ),
                _buildPolicySection(
                  '6. 문의처',
                  '개인정보 관련 문의사항은 RoutineLog.email@naver.com 으로 연락해 주세요.',
                ),
                SizedBox(height: 100,)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
