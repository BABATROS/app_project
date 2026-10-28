import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_screen.dart';
import 'new_chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('กรุณาเข้าสู่ระบบก่อน')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('แชทของฉัน')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const NewChatScreen()),
          );
        },
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('เริ่มแชทใหม่'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db
            .collection('chats')
            .where('participants', arrayContains: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error;

            if (error is FirebaseException) {
              debugPrint('CHAT LIST ERROR: ${error.code} - ${error.message}');
            } else {
              debugPrint('CHAT LIST ERROR: $error');
            }

            return _ErrorView(message: _getErrorMessage(error, 'รายการแชต'));
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = (snapshot.data?.docs ?? []).toList();

          chats.sort((a, b) {
            final aTime = a.data()['updatedAt'];
            final bTime = b.data()['updatedAt'];

            final aMillis = aTime is Timestamp
                ? aTime.millisecondsSinceEpoch
                : 0;
            final bMillis = bTime is Timestamp
                ? bTime.millisecondsSinceEpoch
                : 0;

            return bMillis.compareTo(aMillis);
          });

          final validChats = chats.where((chat) {
            final participants = chat.data()['participants'];

            return participants is List &&
                participants.contains(user.uid) &&
                participants.any((id) => id is String && id != user.uid);
          }).toList();

          if (validChats.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 64),
                    SizedBox(height: 16),
                    Text('ยังไม่มีบทสนทนา', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text('กด “เริ่มแชทใหม่” เพื่อพูดคุยกับผู้ใช้'),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: validChats.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = validChats[index];
              final data = chat.data();

              final participants = (data['participants'] as List)
                  .whereType<String>()
                  .toList();

              final otherIds = participants
                  .where((id) => id != user.uid)
                  .toList();

              if (otherIds.isEmpty) {
                return const SizedBox.shrink();
              }

              final otherId = otherIds.first;
              final rawNames = data['participantNames'];

              final names = rawNames is Map
                  ? Map<String, dynamic>.from(rawNames)
                  : <String, dynamic>{};

              final rawName = names[otherId]?.toString().trim() ?? '';
              final otherName = rawName.isEmpty ? 'ผู้ใช้งาน' : rawName;

              final lastMessage =
                  data['lastMessage']?.toString() ?? 'เริ่มสนทนา';

              return _ChatListTile(
                key: ValueKey(chat.id),
                db: _db,
                chatId: chat.id,
                userId: user.uid,
                otherUserName: otherName,
                lastMessage: lastMessage,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ChatScreen(
                        chatId: chat.id,
                        otherUserId: otherId,
                        otherUserName: otherName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

String _getErrorMessage(Object? error, String section) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'ไม่มีสิทธิ์เข้าถึง$section\n'
            'กรุณาตรวจสอบ Firestore Rules ที่เผยแพร่จริง';

      case 'unavailable':
        return 'เชื่อมต่อ Firebase ไม่ได้\n'
            'กรุณาตรวจสอบอินเทอร์เน็ต';

      case 'unauthenticated':
        return 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';

      case 'failed-precondition':
        return 'เงื่อนไขการโหลด$sectionไม่ผ่าน\n'
            'โปรดตรวจสอบรายละเอียดใน Terminal';

      default:
        return 'โหลด$sectionไม่สำเร็จ\n'
            'รหัสข้อผิดพลาด: ${error.code}';
    }
  }

  return 'โหลด$sectionไม่สำเร็จ\n$error';
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _ChatListTile extends StatelessWidget {
  final FirebaseFirestore db;
  final String chatId;
  final String userId;
  final String otherUserName;
  final String lastMessage;
  final VoidCallback onTap;

  const _ChatListTile({
    super.key,
    required this.db,
    required this.chatId,
    required this.userId,
    required this.otherUserName,
    required this.lastMessage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chatRef = db.collection('chats').doc(chatId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: chatRef.collection('reads').doc(userId).snapshots(),
      builder: (context, readSnapshot) {
        if (readSnapshot.hasError) {
          debugPrint('CHAT READ STATUS ERROR [$chatId]: ${readSnapshot.error}');
        }

        final readData = readSnapshot.data?.data();
        final rawReadAt = readData?['lastReadAt'];

        final Timestamp? readTimestamp = rawReadAt is Timestamp
            ? rawReadAt
            : null;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: chatRef.collection('messages').snapshots(),
          builder: (context, messageSnapshot) {
            if (messageSnapshot.hasError) {
              debugPrint(
                'CHAT MESSAGES ERROR [$chatId]: '
                '${messageSnapshot.error}',
              );
            }

            var unreadCount = 0;

            for (final doc
                in messageSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
              final message = doc.data();

              if (message['senderId'] == userId) continue;

              final createdAt = message['createdAt'];
              if (createdAt is! Timestamp) continue;

              if (readTimestamp == null ||
                  createdAt.compareTo(readTimestamp) > 0) {
                unreadCount++;
              }
            }

            final subtitle = messageSnapshot.hasError
                ? 'ไม่สามารถโหลดข้อความล่าสุดได้'
                : lastMessage;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(
                otherUserName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (unreadCount > 0)
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onError,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: onTap,
            );
          },
        );
      },
    );
  }
}
