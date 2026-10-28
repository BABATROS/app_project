import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class ChatNotificationService {
  ChatNotificationService._();

  static StreamSubscription<User?>? _authSub;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatSub;

  /// ห้องแชตที่กำลังเปิดอยู่
  static String? activeChatId;

  /// ป้องกันการแจ้งเตือนข้อความเก่าจาก Snapshot แรก
  static bool _initialSnapshot = true;

  /// ลายเซ็นข้อความล่าสุดของแต่ละห้อง
  static final Map<String, String> _lastSignatures = {};

  /// ป้องกันการแจ้งเตือนซ้ำ
  static final Set<String> _notified = {};

  /// ป้องกันการเริ่มระบบซ้ำ
  static bool _initialized = false;

  /// UID ของผู้ใช้ที่ Listener กำลังติดตาม
  static String? _listeningUid;

  /// เรียกครั้งเดียวหลัง Firebase.initializeApp()
  static void init() {
    if (_initialized) return;

    _initialized = true;

    debugPrint('CHAT NOTIFY: initializing');

    _authSub = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        if (user == null) {
          debugPrint('CHAT NOTIFY: user logged out');
          _stop();
          return;
        }

        debugPrint('CHAT NOTIFY: signed in UID=${user.uid}');

        if (_listeningUid == user.uid && _chatSub != null) {
          return;
        }

        _start(user);
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('CHAT NOTIFY AUTH ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );
  }

  /// เริ่มติดตามห้องแชตของผู้ใช้
  static void _start(User user) {
    _chatSub?.cancel();
    _chatSub = null;

    _listeningUid = user.uid;
    _initialSnapshot = true;

    _lastSignatures.clear();
    _notified.clear();

    debugPrint('CHAT NOTIFY: starting listener for UID=${user.uid}');

    _chatSub = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint(
              'CHAT NOTIFY: docs=${snapshot.docs.length}, '
              'fromCache=${snapshot.metadata.isFromCache}, '
              'hasPendingWrites=${snapshot.metadata.hasPendingWrites}',
            );

            // ตั้งค่าเริ่มต้นจากข้อมูลเซิร์ฟเวอร์เท่านั้น
            if (_initialSnapshot) {
              if (snapshot.metadata.isFromCache) {
                return;
              }

              for (final doc in snapshot.docs) {
                _lastSignatures[doc.id] = _signature(doc.data());
              }

              _initialSnapshot = false;

              debugPrint('CHAT NOTIFY: ready for new messages');
              return;
            }

            for (final change in snapshot.docChanges) {
              final chatId = change.doc.id;

              if (change.type == DocumentChangeType.removed) {
                _lastSignatures.remove(chatId);
                continue;
              }

              final data = change.doc.data();

              if (data == null) {
                debugPrint('CHAT NOTIFY: null document data, ID=$chatId');
                continue;
              }

              if (change.doc.metadata.hasPendingWrites) {
                debugPrint('CHAT NOTIFY: pending write skipped, ID=$chatId');
                continue;
              }

              final newSignature = _signature(data);
              final oldSignature = _lastSignatures[chatId];

              _lastSignatures[chatId] = newSignature;

              if (oldSignature == newSignature) {
                continue;
              }

              final senderId = data['lastSenderId']?.toString();
              final text = data['lastMessage']?.toString().trim() ?? '';
              final updatedAt = data['updatedAt'];

              if (senderId == null ||
                  senderId.isEmpty ||
                  senderId == user.uid ||
                  text.isEmpty) {
                continue;
              }

              if (activeChatId == chatId) {
                debugPrint('CHAT NOTIFY: active chat skipped, ID=$chatId');
                continue;
              }

              if (updatedAt is! Timestamp) {
                debugPrint('CHAT NOTIFY: invalid updatedAt, ID=$chatId');
                continue;
              }

              final notificationKey = '${chatId}_$newSignature';

              if (_notified.contains(notificationKey)) {
                debugPrint('CHAT NOTIFY: duplicate skipped, ID=$chatId');
                continue;
              }

              if (_notified.length >= 500) {
                _notified.clear();
              }

              _notified.add(notificationKey);

              final rawNames = data['participantNames'];

              final Map<String, dynamic> names = rawNames is Map
                  ? Map<String, dynamic>.from(rawNames)
                  : <String, dynamic>{};

              final rawName = names[senderId]?.toString().trim() ?? '';
              final senderName = rawName.isEmpty ? 'ผู้ใช้งาน' : rawName;

              debugPrint(
                'CHAT NOTIFY: new message from $senderName, '
                'chatId=$chatId',
              );

              _showSnackBar(
                chatId: chatId,
                senderId: senderId,
                senderName: senderName,
                text: text,
              );
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (error is FirebaseException) {
              debugPrint(
                'CHAT NOTIFY FIRESTORE ERROR: '
                'code=${error.code}, message=${error.message}',
              );

              if (error.code == 'permission-denied') {
                debugPrint(
                  'ตรวจสอบ Firestore Rules ที่เผยแพร่จริง '
                  'และ UID ใน participants ของ chats',
                );
              }
            } else {
              debugPrint('CHAT NOTIFY ERROR: $error');
            }

            debugPrintStack(stackTrace: stackTrace);
          },
        );
  }

  /// สร้างลายเซ็นจากข้อความล่าสุด
  static String _signature(Map<String, dynamic> data) {
    final senderId = data['lastSenderId']?.toString() ?? '';
    final text = data['lastMessage']?.toString() ?? '';
    final updatedAt = data['updatedAt'];

    String timeKey = '';

    if (updatedAt is Timestamp) {
      timeKey = '${updatedAt.seconds}:${updatedAt.nanoseconds}';
    } else {
      timeKey = updatedAt?.toString() ?? '';
    }

    return '$senderId|$timeKey|$text';
  }

  /// หยุด Listener เมื่อออกจากระบบ
  static void _stop() {
    _chatSub?.cancel();
    _chatSub = null;

    _listeningUid = null;

    _lastSignatures.clear();
    _notified.clear();

    _initialSnapshot = true;
    activeChatId = null;

    appMessengerKey.currentState?.hideCurrentSnackBar();

    debugPrint('CHAT NOTIFY: listener stopped');
  }

  /// แสดง SnackBar แจ้งเตือนข้อความใหม่
  static void _showSnackBar({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
  }) {
    final messenger = appMessengerKey.currentState;

    if (messenger == null) {
      debugPrint('CHAT NOTIFY: ScaffoldMessenger is not ready');
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ข้อความใหม่จาก $senderName',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF252525),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'เปิด',
            textColor: const Color(0xFFFF8A33),
            onPressed: () {
              openChat(senderId, senderName, chatId: chatId);
            },
          ),
        ),
      );
  }

  /// เปิดห้องแชตโดยใช้ chatId จริงจาก Firestore
  static void openChat(
    String otherUserId,
    String otherUserName, {
    String? chatId,
  }) {
    appMessengerKey.currentState?.hideCurrentSnackBar();

    final navigator = appNavigatorKey.currentState;

    if (navigator == null) {
      debugPrint('CHAT NOTIFY: Navigator is not ready');
      return;
    }

    if (chatId == null || chatId.isEmpty) {
      debugPrint('CHAT NOTIFY: cannot open chat without chatId');
      return;
    }

    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          chatId: chatId,
        ),
      ),
    );
  }

  /// ยกเลิก Listener ทั้งหมด
  static Future<void> dispose() async {
    await _authSub?.cancel();
    await _chatSub?.cancel();

    _authSub = null;
    _chatSub = null;

    _initialized = false;
    _listeningUid = null;

    _lastSignatures.clear();
    _notified.clear();

    _initialSnapshot = true;
    activeChatId = null;

    debugPrint('CHAT NOTIFY: disposed');
  }
}
