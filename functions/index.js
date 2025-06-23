const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest } = require("firebase-functions/v2/https");
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

// 매분마다 루틴시작 알림 보내기
exports.notifyUpcomingRoutines = onSchedule(
  {
    schedule: "* * * * *",
    timeZone: "Asia/Seoul",
  },
  async (event) => {
    const nowUTC = new Date();
    const now = new Date(nowUTC.getTime() + 9 * 60 * 60 * 1000); //ktc로 보정
    const dateStr = now.toISOString().slice(0, 10);
    const timeStr = formatAMPM(now);

    console.log(`[현재 시각] date: ${dateStr}, time: ${timeStr}`);

    const usersSnapshot = await admin.firestore().collection("users").get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) {
        console.log(` FCM 토큰 없음`);
        continue;
      }

      console.log(`fcmToken: ${fcmToken}`);

      const routineSnapshot = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .collection("routineLogs")
        .where("date", "==", dateStr)
        .where("startTime", "==", timeStr)
        .where("isFinished", "==", false)
        .get();

      if (routineSnapshot.empty) {
        console.log(`[${userId}] 해당 시간(date: ${dateStr}, time: ${timeStr})에 시작하는 미완료 루틴 없음 `);
      } else {
        console.log(`[${userId}] 루틴 ${routineSnapshot.size}개 찾음`);
      }

      for (const routineDoc of routineSnapshot.docs) {
        const data = routineDoc.data();
        const title = data.title || "루틴";

        console.log(`[푸시 전송] userId: ${userId}, title: ${title}, fcmToken: ${fcmToken}`);

        try {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: "루틴 시작 알림",
              body: `"${title}" 루틴 시작 시간입니다!`,
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
        } catch (err) {
          console.error(`[${userId}] 알림 전송 실패`, err);
        }
      }
    }

    return null;
  }
);

function formatAMPM(date) {
  let hours = date.getHours();
  let minutes = date.getMinutes();
  const ampm = hours >= 12 ? "PM" : "AM";

  hours = hours % 12;
  if (hours === 0) hours = 12;

  const minutesStr = minutes < 10 ? "0" + minutes : minutes.toString();

  return `${hours}:${minutesStr} ${ampm}`;
}