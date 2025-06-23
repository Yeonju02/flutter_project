const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
admin.initializeApp();

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
