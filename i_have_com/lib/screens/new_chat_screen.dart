// หน้าเลือกผู้ใช้เพื่อเริ่มบทสนทนาใหม่ โดยค้นหาโปรไฟล์สาธารณะและเปิดหน้าแชต
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _keyword = '';
  String? _openingUserId;

  String _displayName(Map<String, dynamic> data) {
    final value =
        data['displayName'] ??
        data['name'] ??
        data['username'] ??
        data['email'];

    final name = value?.toString().trim() ?? '';
    return name.isEmpty ? 'ผู้ใช้งาน' : name;
  }

  String _canonicalChatId(String uid, String otherUserId) {
    final ids = [uid, otherUserId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> _openChat(String otherUserId, String otherUserName) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || currentUser.uid == otherUserId) {
      return;
    }

    if (_openingUserId != null) return;

    setState(() => _openingUserId = otherUserId);

    try {
      String? existingChatId;

      // ค้นหาห้องเดิมก่อน เพื่อรองรับห้องที่ใช้ ID แบบเก่า
      final result = await _db
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      for (final doc in result.docs) {
        final participants = doc.data()['participants'];

        if (participants is List &&
            participants.contains(currentUser.uid) &&
            participants.contains(otherUserId)) {
          existingChatId = doc.id;
          break;
        }
      }

      if (!mounted) return;

      final chatId =
          existingChatId ?? _canonicalChatId(currentUser.uid, otherUserId);

      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            chatId: chatId,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
          ),
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint('OPEN CHAT ERROR: ${e.code} - ${e.message}');

      if (mounted) {
        final message = e.code == 'permission-denied'
            ? 'ไม่มีสิทธิ์ค้นหาห้องแชท กรุณาตรวจสอบ Firestore Rules'
            : 'เปิดห้องแชทไม่สำเร็จ (${e.code})';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      debugPrint('OPEN CHAT ERROR: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('เปิดห้องแชทไม่สำเร็จ')));
      }
    } finally {
      if (mounted) {
        setState(() => _openingUserId = null);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('กรุณาเข้าสู่ระบบก่อน')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('เริ่มแชทใหม่')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อหรืออีเมล',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'ล้างคำค้นหา',
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _keyword = '');
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _keyword = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db.collection('publicProfiles').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SelectableText(
                        'โหลดรายชื่อผู้ใช้ไม่ได้\n'
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = (snapshot.data?.docs ?? []).where((doc) {
                  if (doc.id == currentUser.uid) return false;

                  final data = doc.data();
                  final name = _displayName(data).toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();

                  if (_keyword.isEmpty) return true;

                  return name.contains(_keyword) || email.contains(_keyword);
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      _keyword.isEmpty
                          ? 'ยังไม่มีผู้ใช้อื่นให้เริ่มแชท'
                          : 'ไม่พบผู้ใช้ที่ตรงกับคำค้นหา',
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = users[index];
                    final data = doc.data();
                    final name = _displayName(data);
                    final email = (data['email'] ?? '').toString().trim();
                    final isOpening = _openingUserId == doc.id;

                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: Text(name),
                      subtitle: email.isEmpty ? null : Text(email),
                      trailing: isOpening
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chat_outlined),
                      onTap: _openingUserId == null
                          ? () => _openChat(doc.id, name)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
