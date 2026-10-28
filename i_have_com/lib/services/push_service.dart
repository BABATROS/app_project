import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'chat_notification_service.dart';

/// Push Notification (แอปอยู่เบื้องหลังหรือปิดอยู่)
/// เรียก PushService.init() ครั้งเดียวตอนเริ่มแอป ต่อจาก ChatNotificationService.init()
/// ทำงานเฉพาะ Android / iOS (ข้ามบน Web)
class PushService {
  PushService._();

  static StreamSubscription<User?>? _authSub;
  static StreamSubscription<String>? _refreshSub;
  static String? _lastUid;

  static void init() {
    if (kIsWeb) return;

    _authSub?.cancel();

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        await _refreshSub?.cancel();
        _refreshSub = null;

        // ออกจากระบบ: ยกเลิก token ของเครื่องนี้ เพื่อไม่ให้ได้รับแจ้งเตือนของบัญชีเดิม
        if (_lastUid != null) {
          _lastUid = null;
          await _deleteLocalToken();
        }
        return;
      }

      // สลับบัญชีโดยไม่ผ่านการออกจากระบบ
      if (_lastUid != null && _lastUid != user.uid) {
        await _deleteLocalToken();
      }

      _lastUid = user.uid;
      await _register(user.uid);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_openFromPush);

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _openFromPush(message);
    });
  }

  static Future<void> _register(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission();

      final token = await messaging.getToken();
      if (token != null) await _saveToken(uid, token);

      await _refreshSub?.cancel();
      _refreshSub = messaging.onTokenRefresh.listen(
        (newToken) => _saveToken(uid, newToken),
      );
    } catch (e) {
      debugPrint('Register push token failed: $e');
    }
  }

  static Future<void> _saveToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint('Save FCM token failed: ${e.code}');
    }
  }

  static Future<void> _deleteLocalToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('Delete FCM token failed: $e');
    }
  }

  static void _openFromPush(RemoteMessage message) {
    final senderId = message.data['senderId']?.toString() ?? '';
    if (senderId.isEmpty) return;

    final rawName = message.data['senderName']?.toString().trim() ?? '';
    final senderName = rawName.isEmpty ? 'ผู้ใช้งาน' : rawName;

    // รอให้ Navigator พร้อมก่อน (กรณีเปิดแอปจากสถานะปิด)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatNotificationService.openChat(senderId, senderName);
    });
  }
}
