import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../custom/dialogs/daily_mission_list_dialog.dart';

class DailyMissionTab extends StatefulWidget {
  const DailyMissionTab({super.key});

  @override
  State<DailyMissionTab> createState() => _DailyMissionTabState();
}

class _DailyMissionTabState extends State<DailyMissionTab> {
  bool missionsCompleted = false;

  @override
  void initState() {
    super.initState();
    _handleDailyMissionState();
  }

  Future<void> _handleDailyMissionState() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;

    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

    String? matchedDocId;
    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      if (data['userId'] == userId) {
        matchedDocId = doc.id;
        break;
      }
    }

    if (matchedDocId == null) return;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastVisit = prefs.getString('lastVisitDate');
    final isNewDay = lastVisit == null || lastVisit != todayStr;

    final userMissionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(matchedDocId)
        .collection('missions');

    if (isNewDay) {
      await prefs.setString('lastVisitDate', todayStr);
      await prefs.setBool('missionsCompleted', false);

      final missionsSnapshot = await FirebaseFirestore.instance.collection('missions').get();
      final batch = FirebaseFirestore.instance.batch();

      for (final doc in missionsSnapshot.docs) {
        final data = doc.data();
        batch.set(userMissionRef.doc(doc.id), {
          'missionTitle': data['missionTitle'],
          'missionXp': data['missionXp'],
          'maxCount': data['maxCount'],
          'recentCount': 0,
          'missionRewarded': false,
        });
      }
      await batch.commit();
    }

    final missionQuery = await userMissionRef
        .where('missionTitle', isEqualTo: '출석하기')
        .limit(1)
        .get();

    if (missionQuery.docs.isNotEmpty) {
      final doc = missionQuery.docs.first;
      final data = doc.data();
      final current = data['recentCount'] ?? 0;
      final max = data['maxCount'] ?? 1;

      if (current < max) {
        await userMissionRef.doc(doc.id).update({'recentCount': current + 1});

        final allMissionQuery = await userMissionRef
            .where('missionTitle', isEqualTo: '모든 미션 완료하기')
            .limit(1)
            .get();

        if (allMissionQuery.docs.isNotEmpty) {
          final allDoc = allMissionQuery.docs.first;
          final allData = allDoc.data();
          final allCurrent = allData['recentCount'] ?? 0;
          if (allCurrent < (allData['maxCount'] ?? 1)) {
            await userMissionRef.doc(allDoc.id).update({'recentCount': allCurrent + 1});
          }
        }
      }
    }

    final completed = prefs.getBool('missionsCompleted') ?? false;
    setState(() {
      missionsCompleted = completed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = missionsCompleted;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => const DailyMissionListDialog(),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          color: isComplete ? Colors.grey[200] : const Color(0xFF94B4DA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                isComplete
                    ? "오늘의 일일 미션을 \n모두 완료했어요!"
                    : "새로운 일일 미션이 \n도착했어요!",
                style: TextStyle(
                  color: isComplete ? Colors.black87 : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Image.asset(
              'assets/arrow_icon.png',
              width: 50,
              height: 50,
            ),
          ],
        ),
      ),
    );
  }
}
