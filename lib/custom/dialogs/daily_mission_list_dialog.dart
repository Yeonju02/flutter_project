import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'xp_dialog.dart';

class DailyMissionListDialog extends StatefulWidget {
  const DailyMissionListDialog({super.key});

  @override
  State<DailyMissionListDialog> createState() => _DailyMissionListDialogState();
}

class _DailyMissionListDialogState extends State<DailyMissionListDialog> {
  List<Map<String, dynamic>> missions = [];
  List<String> missionDocIds = [];
  String? userDocId;

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;

    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    for (final doc in usersSnapshot.docs) {
      if (doc.data()['userId'] == userId) {
        userDocId = doc.id;
        break;
      }
    }

    if (userDocId == null) return;

    final missionsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userDocId)
        .collection('missions')
        .get();

    final loadedMissions = <Map<String, dynamic>>[];
    final loadedIds = <String>[];

    for (final doc in missionsSnapshot.docs) {
      final data = doc.data();
      data['docId'] = doc.id;
      loadedMissions.add(data);
      loadedIds.add(doc.id);
    }

    setState(() {
      missions = loadedMissions;
      missionDocIds = loadedIds;
    });
  }

  Future<void> _handleRewardMissions() async {
    if (userDocId == null) return;

    final prefs = await SharedPreferences.getInstance();

    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userDocId)
        .get();
    final userData = userSnapshot.data();
    if (userData == null) return;

    int currentXP = (userData['xp'] ?? 0).toInt();
    int currentLevel = (userData['level'] ?? 1).toInt();
    int earnedXP = 0;
    bool anyRewarded = false;

    final missionsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userDocId)
        .collection('missions')
        .get();

    missions = missionsSnapshot.docs.map((doc) {
      final data = doc.data();
      data['docId'] = doc.id;
      return data;
    }).toList();

    for (int i = 0; i < missions.length; i++) {
      final mission = missions[i];
      final recent = (mission['recentCount'] ?? 0).toInt();
      final max = (mission['maxCount'] ?? 1).toInt();
      final rewarded = mission['missionRewarded'] ?? false;

      if (recent >= max && rewarded == false) {
        final xp = (mission['missionXp'] as num? ?? 0).toInt();
        earnedXP += xp;
        anyRewarded = true;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userDocId)
            .collection('missions')
            .doc(mission['docId'])
            .update({'missionRewarded': true});

        missions[i]['missionRewarded'] = true;
      }
    }

    // 미션 전부 완료되었는지 확인
    final allRewarded = missions.every((m) => m['missionRewarded'] == true);
    if (allRewarded) {
      await prefs.setBool('missionsCompleted', true);
    }

    if (anyRewarded) {
      setState(() {});
    }

    if (earnedXP > 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => XpDialog(
          currentLevel: currentLevel,
          currentXP: currentXP,
          earnedXP: earnedXP,
          userDocId: userDocId!,
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "일일 미션 목록",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadMissions,
                ),
              ],
            ),
            const SizedBox(height: 16),
            missions.isEmpty
                ? const Text("미션 정보를 불러오는 중입니다...")
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("1XP", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 8),
                ...missions
                    .where((m) => m['missionXp'] == 1)
                    .map((m) => _missionItem(
                  m['missionTitle'],
                  m['recentCount'],
                  m['maxCount'],
                  isDone: (m['recentCount'] ?? 0) >= (m['maxCount'] ?? 1),
                  rewarded: m['missionRewarded'] == true,
                )),
                const SizedBox(height: 16),
                const Text("2XP", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 8),
                ...missions
                    .where((m) => m['missionXp'] == 2)
                    .map((m) => _missionItem(
                  m['missionTitle'],
                  m['recentCount'],
                  m['maxCount'],
                  isDone: (m['recentCount'] ?? 0) >= (m['maxCount'] ?? 1),
                  rewarded: m['missionRewarded'] == true,
                )),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _handleRewardMissions,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "미션 완료하기",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _missionItem(String title, int done, int total, {bool isDone = false, bool rewarded = false}) {
    final textStyle = TextStyle(
      fontSize: 14,
      color: rewarded ? Colors.grey : Colors.black,
      decoration: rewarded ? TextDecoration.lineThrough : TextDecoration.none,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            rewarded
                ? Icons.check_box_outline_blank
                : isDone
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: rewarded
                ? Colors.grey
                : isDone
                ? Colors.blue
                : Colors.black38,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: textStyle)),
          Text("$done/$total", style: TextStyle(fontWeight: FontWeight.bold, color: rewarded ? Colors.grey : Colors.black)),
        ],
      ),
    );
  }
}
