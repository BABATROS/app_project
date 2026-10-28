import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  Future<void> _editUser(
    BuildContext context,
    String userId,
    Map<String, dynamic> user,
  ) async {
    final usernameController = TextEditingController(
      text: user['username']?.toString() ?? '',
    );

    String selectedRole = user['role']?.toString() ?? 'customer';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('แก้ไขผู้ใช้งาน'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'สิทธิ์ผู้ใช้งาน',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'customer',
                        child: Text('Customer'),
                      ),
                      DropdownMenuItem(value: 'seller', child: Text('Seller')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedRole = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final username = usernameController.text.trim();

                    if (username.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กรุณากรอก Username')),
                      );
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .update({'username': username, 'role': selectedRole});

                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );

    usernameController.dispose();

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('แก้ไขข้อมูลผู้ใช้งานเรียบร้อยแล้ว')),
      );
    }
  }

  Future<void> _deleteUser(
    BuildContext context,
    String userId,
    String username,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: Text('ต้องการลบผู้ใช้งาน "$username" ใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบผู้ใช้งานเรียบร้อยแล้ว')));
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่สามารถลบผู้ใช้งานได้')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ผู้ใช้งาน')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('ไม่สามารถโหลดข้อมูลผู้ใช้งานได้'));
          }

          final users = snapshot.data?.docs ?? [];

          if (users.isEmpty) {
            return const Center(child: Text('ยังไม่มีข้อมูลผู้ใช้งาน'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final user = userDoc.data();

              final username = user['username']?.toString() ?? '-';

              final email = user['email']?.toString() ?? '-';

              final role = user['role']?.toString() ?? '-';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(username),
                  subtitle: Text('$email\nสิทธิ์: $role'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'แก้ไข',
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _editUser(context, userDoc.id, user);
                        },
                      ),
                      IconButton(
                        tooltip: 'ลบ',
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _deleteUser(context, userDoc.id, username);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
