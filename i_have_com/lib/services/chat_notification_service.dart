import 'package:flutter/material.dart';

import '../screens/chat_screen.dart';
import '../screens/chat_notification_service.dart' as chat_ui;

class ChatNotificationService {
  ChatNotificationService._();

  static void init() {}

  static void openChat(String senderId, String senderName) {
    final navigator = chat_ui.appNavigatorKey.currentState;

    if (navigator == null) {
      debugPrint('Navigator is not ready yet.');
      return;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) =>
            ChatScreen(otherUserId: senderId, otherUserName: senderName),
      ),
    );
  }
}
