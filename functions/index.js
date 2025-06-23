const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
admin.initializeApp();

//루틴 체크해서 streakCount/maxStreak 적용
exports.updateStreaks = onSchedule(
  {
    schedule: "59 23 * * *",
    timeZone: "Asia/Seoul",
  },
  async (event) => {
    const todayStr = new Date().toISOString().slice(0, 10);

    const usersSnapshot = await admin.firestore().collection("users").get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userRef = admin.firestore().collection("users").doc(userId);
      const userData = userDoc.data();

      const currentStreak = userData.streakCount || 0;
      const currentMaxStreak = userData.maxStreak || 0;

      const routineLogsSnapshot = await userRef
        .collection("routineLogs")
        .where("date", "==", todayStr)
        .get();

      const completed = routineLogsSnapshot.docs.filter((doc) => {
        const data = doc.data();
        return data.isFinished === true && (data.xpEarned || 0) > 0;
      });


      if (completed.length >= 5) {
        await userRef.update({
          streakCount: Math.min(currentStreak + 1, 5),
          maxStreak: currentMaxStreak + 1,
        });
      } else {
        await userRef.update({
          streakCount: 0,
          maxStreak: 0,
        });
      }
    }

    return null;
  }
);

// 일일미션 초기화
exports.resetDailyMissions = onSchedule(
  {
    schedule: "59 23 * * *",
    timeZone: "Asia/Seoul",
  },
  async (event) => {
    const usersSnapshot = await admin.firestore().collection("users").get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const missionsSnapshot = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .collection("missions")
        .get();

      const batch = admin.firestore().batch();

      missionsSnapshot.docs.forEach((missionDoc) => {
        const missionRef = missionDoc.ref;
        batch.update(missionRef, {
          recentCount: 0,
          missionRewarded: false,
        });
      });

      await batch.commit();
    }

    return null;
  }
);

// 매분마다 루틴시작 10분 전 알림 보내기
exports.notifyUpcomingRoutines = onSchedule(
  {
    schedule: "* * * * *", // 매 분
    timeZone: "Asia/Seoul",
  },
  async (event) => {
    const now = new Date();
    const nowPlus10 = new Date(now.getTime() + 10 * 60 * 1000);

    const dateStr = nowPlus10.toISOString().slice(0, 10);
    const timeStr = formatAMPM(nowPlus10);

    const usersSnapshot = await admin.firestore().collection("users").get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) continue;

      const routineSnapshot = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .collection("routineLogs")
        .where("date", "==", dateStr)
        .where("startTime", "==", timeStr)
        .get();

      if (!routineSnapshot.empty) {
        for (const routineDoc of routineSnapshot.docs) {
          const data = routineDoc.data();
          const title = data.title || "루틴";

          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: "루틴 10분 전 알림",
              body: `"${title}" 루틴이 10분 뒤에 시작돼요!`,
            },
            android: { priority: "high" },
            apns: {
              payload: {
                aps: {
                  sound: "default",
                },
              },
            },
          });
        }
      }
    }

    return null;
  }
);

// 루틴 시간 포맷 바꾸는 함수
function formatAMPM(date) {
  let hours = date.getHours();
  let minutes = date.getMinutes();
  const ampm = hours >= 12 ? "PM" : "AM";
  hours = hours % 12;
  hours = hours ? hours : 12; // 0시 → 12
  const minutesStr = minutes < 10 ? "0" + minutes : minutes;
  return `${hours}:${minutesStr} ${ampm}`;
}
