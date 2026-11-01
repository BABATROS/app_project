// หน้าแชตระหว่างผู้ใช้สองคน รับ/ส่งข้อความและบันทึกสถานะอ่านข้อความใน Firestore
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_notification_service.dart';

const Color _chatOrange = Color(0xFFFF6B00);
const Color _chatBlack = Color(0xFF202020);
const Color _chatBackground = Color(0xFFF7F7F7);
const Color _chatBorder = Color(0xFFEEEEEE);

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? chatId;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.chatId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  bool _sending = false;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messageSubscription;

  String? _lastReadMessageId;
  String? _previousActiveChatId;

  String get _chatId {
    final suppliedChatId = widget.chatId;

    if (suppliedChatId != null && suppliedChatId.isNotEmpty) {
      return suppliedChatId;
    }

    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final ids = [currentUid, widget.otherUserId]..sort();

    return '${ids[0]}_${ids[1]}';
  }

  DocumentReference<Map<String, dynamic>> get _chatRef =>
      _db.collection('chats').doc(_chatId);

  CollectionReference<Map<String, dynamic>> get _messages =>
      _chatRef.collection('messages');

  DocumentReference<Map<String, dynamic>> get _readRef =>
      _chatRef.collection('reads').doc(_auth.currentUser!.uid);

  @override
  void initState() {
    super.initState();

    final user = _auth.currentUser;

    if (user != null && widget.otherUserId != user.uid) {
      _previousActiveChatId = ChatNotificationService.activeChatId;
      ChatNotificationService.activeChatId = _chatId;
      _listenForMessages();
    }
  }

  void _listenForMessages() {
    _messageSubscription = _messages
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;
            _markAsRead(snapshot);
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('CHAT LOAD ERROR: $error');
            debugPrintStack(stackTrace: stackTrace);
          },
        );
  }

  Future<void> _markAsRead(QuerySnapshot<Map<String, dynamic>> snapshot) async {
    final user = _auth.currentUser;

    if (user == null || snapshot.docs.isEmpty) return;

    final latestMessage = snapshot.docs.first;
    final latestTimestamp = latestMessage.data()['createdAt'];

    if (latestTimestamp is! Timestamp) return;
    if (_lastReadMessageId == latestMessage.id) return;

    try {
      // ใช้ชื่อฟิลด์เดียวกับที่ Firestore Rules กำหนดไว้
      await _readRef.set({
        'lastReadAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _lastReadMessageId = latestMessage.id;
    } on FirebaseException catch (e) {
      _lastReadMessageId = null;
      debugPrint('MARK CHAT AS READ ERROR: ${e.code} - ${e.message}');
    } catch (e) {
      _lastReadMessageId = null;
      debugPrint('MARK CHAT AS READ ERROR: $e');
    }
  }

  String _myDisplayName(User user, Map<String, dynamic> data) {
    final value =
        data['displayName'] ??
        data['name'] ??
        data['username'] ??
        user.displayName ??
        user.email;

    final name = value?.toString().trim() ?? '';

    return name.isEmpty ? 'ผู้ใช้งาน' : name;
  }

  Future<void> _sendMessage() async {
    final user = _auth.currentUser;
    final text = _messageController.text.trim();

    if (user == null || text.isEmpty || _sending) return;

    if (widget.otherUserId.trim().isEmpty || widget.otherUserId == user.uid) {
      _showMessage('ไม่สามารถแชทกับผู้ใช้งานนี้ได้');
      return;
    }

    setState(() => _sending = true);

    try {
      // อ่านชื่อผู้ส่ง แล้วบันทึกข้อมูลห้องกับข้อความใน batch เดียวกัน
      final userDoc = await _db.collection('users').doc(user.uid).get();

      final myName = _myDisplayName(user, userDoc.data() ?? {});

      final participantIds = [user.uid, widget.otherUserId]..sort();
      final messageRef = _messages.doc();
      final batch = _db.batch();

      batch.set(_chatRef, {
        'participants': participantIds,
        'participantNames': {
          user.uid: myName,
          widget.otherUserId: widget.otherUserName,
        },
        'lastMessage': text,
        'lastSenderId': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.set(messageRef, {
        'senderId': user.uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (!mounted) return;

      _messageController.clear();
    } on FirebaseException catch (e) {
      debugPrint('SEND MESSAGE ERROR: ${e.code} - ${e.message}');

      if (!mounted) return;

      final errorMessage = switch (e.code) {
        'permission-denied' =>
          'ไม่มีสิทธิ์ส่งข้อความ กรุณาตรวจสอบสมาชิกแชตและ Firestore Rules',
        'unavailable' => 'เชื่อมต่อ Firestore ไม่ได้ กรุณาลองใหม่',
        _ => 'ส่งข้อความไม่สำเร็จ (${e.code})',
      };

      _showMessage(errorMessage);
    } catch (e) {
      debugPrint('Send message error: $e');

      if (mounted) {
        _showMessage('เกิดข้อผิดพลาดในการส่งข้อความ กรุณาลองใหม่');
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    if (ChatNotificationService.activeChatId == _chatId) {
      ChatNotificationService.activeChatId = _previousActiveChatId;
    }

    _messageSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('กรุณาเข้าสู่ระบบก่อน')));
    }

    if (widget.otherUserId == user.uid) {
      return const Scaffold(
        body: Center(child: Text('ไม่สามารถแชทกับตัวเองได้')),
      );
    }

    return Scaffold(
      backgroundColor: _chatBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          tooltip: 'ย้อนกลับ',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _chatBlack,
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _chatOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: _chatOrange,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName.trim().isEmpty
                        ? 'ผู้ใช้งาน'
                        : widget.otherUserName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _chatBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'แชทข้อความ',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(height: 1, color: _chatBorder),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messages
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  final error = snapshot.error;

                  debugPrint('CHAT LOAD ERROR: $error');

                  String message = 'โหลดข้อความไม่สำเร็จ';

                  if (error is FirebaseException) {
                    switch (error.code) {
                      case 'permission-denied':
                        message = 'ไม่มีสิทธิ์อ่านข้อความ กรุณาตรวจสอบสมาชิกแชตและ Firestore Rules';
                        break;
                      case 'unavailable':
                        message = 'เชื่อมต่อ Firebase ไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ต';
                        break;
                      case 'failed-precondition':
                        message = 'คำสั่งค้นหาต้องการการตั้งค่าเพิ่มเติม กรุณาตรวจสอบ Error';
                        break;
                      case 'unauthenticated':
                        message = 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';
                        break;
                      default:
                        message = 'โหลดข้อความไม่สำเร็จ (${error.code})';
                    }
                  }

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 42,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _chatOrange),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: _chatBorder),
                            ),
                            child: const Icon(
                              Icons.forum_rounded,
                              color: _chatOrange,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'เริ่มต้นบทสนทนา',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _chatBlack,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'ส่งข้อความแรกของคุณได้เลย',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final isMe = data['senderId'] == user.uid;
                    final text = data['text']?.toString() ?? '';
                    final timestamp = data['createdAt'];

                    final timeText = timestamp is Timestamp
                        ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:'
                              '${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                        : '';

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
                        decoration: BoxDecoration(
                          color: isMe ? _chatOrange : Colors.white,
                          border: isMe ? null : Border.all(color: _chatBorder),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 5),
                            bottomRight: Radius.circular(isMe ? 5 : 18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text,
                              style: TextStyle(
                                color: isMe ? Colors.white : _chatBlack,
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                            if (timeText.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  timeText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : Colors.black45,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _chatBorder)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      enabled: !_sending,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ข้อความ...',
                        hintStyle: const TextStyle(
                          color: Colors.black38,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: _chatBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _chatBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: _chatOrange,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: IconButton(
                      tooltip: 'ส่งข้อความ',
                      onPressed: _sending ? null : _sendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: _chatOrange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _chatOrange.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _sending
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 21),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
