const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendChatNotification = functions.firestore
  .document("chat_rooms/{roomId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.data();
    const receiverId = messageData.receiverId;
    const senderId = messageData.senderId;
    const messageText = messageData.text;

    // Ambil data penerima
    const userDoc = await admin.firestore().collection("users").doc(receiverId).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    const isOnline = userDoc.data().isOnline;
    if (!fcmToken || isOnline) return;

    // Ambil nama pengirim
    const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
    const senderName = senderDoc.exists ? senderDoc.data().username : "Seseorang";

    // Payload notifikasi
    const payload = {
      notification: {
        title: senderName,
        body: messageText,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        senderId: senderId,
      },
    };

    // Kirim ke FCM
    await admin.messaging().sendToDevice(fcmToken, payload);
    console.log("Notifikasi terkirim ke:", receiverId);
  });
