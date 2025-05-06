const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

//
// Sends a push when a new borrow request is created
//
exports.notifyNewRequest = functions.firestore
    .document("borrow_requests/{id}")
    .onCreate(async (snap, context) => {
      const data = snap.data();
      if (!data) return null;

      const adminsSnap = await admin.firestore()
          .collection("users")
          .where("role", "==", "Admin")
          .get();

      const tokens = [];
      for (const adminDoc of adminsSnap.docs) {
        const tokSnap = await adminDoc.ref
            .collection("tokens")
            .get();
        tokSnap.docs.forEach((d) => tokens.push(d.id));
      }
      const shortId = context.params.id.substr(0, 6);
      const payload = {
        notification: {
          title: "New borrow request 🆕",
          body: `New request (${shortId})`,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          requestId: context.params.id,
        },
      };

      const res = await admin.messaging().sendEachForMulticast({
        tokens,
        ...payload,
      });

      // Clean up invalid tokens
      const invalid = [];
      res.responses.forEach((r, i) => {
        if (!r.success) invalid.push(tokens[i]);
      });
      await Promise.all(
          invalid.map((tok) =>
            admin.firestore()
                .collectionGroup("tokens")
                .where(
                    admin.firestore.FieldPath.documentId(),
                    "==",
                    tok,
                )
                .get()
                .then((q) => q.forEach((d) => d.ref.delete())),
          ),
      );

      return null;
    });

//
// Sends a push when a request’s status changes to "Approved"
//
exports.notifyRequestApproved = functions.firestore
    .document("borrow_requests/{id}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();
      if (!before || !after) return null;
      if (
        before.status === after.status ||
      after.status !== "Approved"
      ) {
        return null;
      }

      const userId = after.userID;
      const tokensSnap = await admin.firestore()
          .collection("users")
          .doc(userId)
          .collection("tokens")
          .get();
      if (tokensSnap.empty) return null;

      const tokens = tokensSnap.docs.map((d) => d.id);
      const shortId = context.params.id.substr(0, 6);
      const payload = {
        notification: {
          title: "Request approved ✅",
          body: `Request (${shortId}) approved`,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          requestId: context.params.id,
        },
      };

      const res = await admin.messaging().sendEachForMulticast({
        tokens,
        ...payload,
      });

      // Clean up invalid tokens
      const invalid = [];
      res.responses.forEach((r, i) => {
        if (!r.success) invalid.push(tokens[i]);
      });
      await Promise.all(
          invalid.map((tok) =>
            admin.firestore()
                .collectionGroup("tokens")
                .where(
                    admin.firestore.FieldPath.documentId(),
                    "==",
                    tok,
                )
                .get()
                .then((q) => q.forEach((d) => d.ref.delete())),
          ),
      );

      return null;
    });

exports.sendOverdueNotifications = functions.https.onCall(
    async (data, context) => {
      const now = admin.firestore.Timestamp.now();

      // 1) find overdue approved requests
      const snap = await admin.firestore()
          .collection("borrow_requests")
          .where("status", "==", "Approved")
          .where("returnDate", "<", now)
          .get();
      if (snap.empty) {
        return {count: 0};
      }

      // 2) gather tokens per user
      const tokensByUser = {};
      const rIDs = {};
      for (const doc of snap.docs) {
        const userId = doc.data().userID;
        tokensByUser[userId] = tokensByUser[userId] || [];
        rIDs[userId] = doc.id;
        const tkSnap = await admin.firestore()
            .collection("users")
            .doc(userId)
            .collection("tokens")
            .get();
        tkSnap.docs.forEach((t) =>
          tokensByUser[userId].push(t.id),
        );
      }

      // 3) send notifications & clean invalid tokens
      let totalSent = 0;
      for (const [userId, tokens] of Object.entries(tokensByUser)) {
        if (tokens.length === 0) continue;

        const userCount = snap.docs.filter(
            (d) => d.data().userID === userId,
        ).length;

        const payload = {
          notification: {
            title: "Overdue equipment 📌",
            body: `You have ${userCount} overdue request(s).`,
          },
          data: {click_action: "FLUTTER_NOTIFICATION_CLICK",
            requestId: rIDs[userId]},
        };

        const res = await admin.messaging()
            .sendEachForMulticast({tokens, ...payload});

        res.responses.forEach((r, idx) => {
          if (r.success) {
            totalSent++;
          } else {
            const bad = tokens[idx];
            admin.firestore()
                .collectionGroup("tokens")
                .where(
                    admin.firestore.FieldPath.documentId(),
                    "==",
                    bad,
                )
                .get()
                .then((q) =>
                  q.forEach((d) => d.ref.delete()),
                );
          }
        });
      }

      return {count: totalSent};
    },
);

exports.notifyRequestReturned = functions.firestore
    .document("borrow_requests/{id}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();
      if (!before || !after) return null;
      if (before.status === after.status || after.status !== "Returned") {
        return null;
      }

      const userId = after.userID;
      const tokensSnap = await admin
          .firestore()
          .collection("users")
          .doc(userId)
          .collection("tokens")
          .get();
      if (tokensSnap.empty) return null;

      const tokens = tokensSnap.docs.map((d) => d.id);
      const shortId = context.params.id.substr(0, 6);
      const payload = {
        notification: {
          title: "Equipments returned 🔄",
          body: `Request (${shortId}) returned`,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          requestId: context.params.id,
        },
      };

      const res = await admin.messaging().sendEachForMulticast({
        tokens,
        ...payload,
      });
      const invalid = [];
      res.responses.forEach((r, i) => {
        if (!r.success) invalid.push(tokens[i]);
      });
      await Promise.all(
          invalid.map((tok) =>
            admin
                .firestore()
                .collectionGroup("tokens")
                .where(admin.firestore.FieldPath.documentId(), "==", tok)
                .get()
                .then((q) => q.forEach((d) => d.ref.delete())),
          ),
      );
      return null;
    });

