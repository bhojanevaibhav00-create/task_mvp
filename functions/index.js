const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();


// ================= MEMBER ADDED =================
exports.notifyMemberAdded = functions.firestore
.document("projects/{projectId}")
.onUpdate(async (change, context) => {

  const before = change.before.data();
  const after = change.after.data();

  const beforeMembers = before.members || [];
  const afterMembers = after.members || [];

  const newMembers = afterMembers.filter(
    uid => !beforeMembers.includes(uid)
  );

  for (const uid of newMembers) {

    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) return;

    const token = userDoc.data().fcmToken;
    if (!token) return;

    await admin.messaging().send({
      token: token,
      notification: {
        title: "Project Added",
        body: `You were added to project "${after.name}"`,
      },
      data: {
        type: "project",
        projectId: context.params.projectId,
      },
    });
  }
});


// ================= TASK ASSIGNED =================
exports.notifyTaskAssigned = functions.firestore
.document("projects/{projectId}/tasks/{taskId}")
.onWrite(async (change, context) => {

  const after = change.after.data();
  if (!after) return;

  const assigneeUid = after.assigneeUid;
  if (!assigneeUid) return;

  const userDoc = await db.collection("users")
      .doc(assigneeUid)
      .get();

  if (!userDoc.exists) return;

  const token = userDoc.data().fcmToken;
  if (!token) return;

  await admin.messaging().send({
    token: token,
    notification: {
      title: "Task Assigned",
      body: `You have been assigned: ${after.title}`,
    },
    data: {
      type: "assignment",
      taskId: context.params.taskId,
      projectId: context.params.projectId,
    },
  });
});


// ================= TASK UPDATED =================
exports.notifyTaskUpdated = functions.firestore
.document("projects/{projectId}/tasks/{taskId}")
.onUpdate(async (change, context) => {

  const before = change.before.data();
  const after = change.after.data();

  if (before.title === after.title &&
      before.description === after.description) {
    return;
  }

  const assigneeUid = after.assigneeUid;
  if (!assigneeUid) return;

  const userDoc = await db.collection("users")
      .doc(assigneeUid)
      .get();

  if (!userDoc.exists) return;

  const token = userDoc.data().fcmToken;
  if (!token) return;

  await admin.messaging().send({
    token: token,
    notification: {
      title: "Task Updated",
      body: `Task "${after.title}" was updated`,
    },
    data: {
      type: "task",
      taskId: context.params.taskId,
      projectId: context.params.projectId,
    },
  });
});