const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// ส่ง Push ให้ผู้รับเมื่อมีข้อความใหม่ใน chats/{chatId}/messages/{messageId}
exports.notifyNewMessage = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const message = event.data && event.data.data();
    if (!message || !message.senderId) return;

    const db = admin.firestore();

    const chatSnap = await db.doc(`chats/${event.params.chatId}`).get();
    const chat = chatSnap.data();
    if (!chat || !Array.isArray(chat.participants)) return;

    const receiverId = chat.participants.find((id) => id !== message.senderId);
    if (!receiverId) return;

    const userRef = db.doc(`users/${receiverId}`);
    const userSnap = await userRef.get();
    const tokens = (userSnap.get("fcmTokens") || []).filter(Boolean);
    if (tokens.length === 0) return;

    const senderName =
      (chat.participantNames && chat.participantNames[message.senderId]) ||
      "ข้อความใหม่";

    const text = String(message.text || "").slice(0, 120);

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title: senderName, body: text },
      data: {
        senderId: String(message.senderId),
        senderName: String(senderName),
        chatId: String(event.params.chatId),
      },
      android: { priority: "high" },
    });

    // ลบ token ที่ใช้ไม่ได้แล้ว
    const invalid = [];
    response.responses.forEach((r, i) => {
      const code = r.error && r.error.code;
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        invalid.push(tokens[i]);
      }
    });

    if (invalid.length > 0) {
      await userRef.update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalid),
      });
    }
  }
);