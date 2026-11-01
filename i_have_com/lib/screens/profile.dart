// หน้าโปรไฟล์ของผู้ใช้ แสดงข้อมูลบัญชีและบันทึกการแก้ไขชื่อกลับไปยัง Firebase
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  String _originalName = '';

  static const Color orange = Color(0xFFFF6B00);
  static const Color dark = Color(0xFF191919);
  static const Color muted = Color(0xFF777777);
  static const Color background = Color(0xFFF7F7F7);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final user = FirebaseAuth.instance.currentUser;
    final name = _nameController.text.trim();

    if (user == null) return;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อ')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
      }, SetOptions(merge: true));

      await user.updateDisplayName(name);

      if (!mounted) return;

      setState(() {
        _originalName = name;
        _isEditing = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกชื่อเรียบร้อยแล้ว')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: const Text('บัญชีของฉัน'),
          backgroundColor: Colors.white,
        ),
        body: const Center(child: Text('กรุณาเข้าสู่ระบบก่อน')),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: dark,
        elevation: 0,
        title: const Text(
          'บัญชีของฉัน',
          style: TextStyle(
            color: dark,
            fontWeight: FontWeight.w800,
            fontSize: 21,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('ไม่สามารถโหลดข้อมูลบัญชีได้'));
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: orange),
            );
          }

          final data = snapshot.data!.data() ?? {};

          final name =
              (data['name'] ?? data['displayName'] ?? user.displayName ?? '')
                  .toString();

          if (!_isEditing && name != _originalName) {
            _originalName = name;
            _nameController.text = name;
          }

          final isSeller = data['role'] == 'seller';
          final role = isSeller ? 'ผู้ขาย' : 'ผู้ซื้อ';

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // Profile header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFF0E5),
                        border: Border.all(
                          color: orange.withValues(alpha: 0.25),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isSeller
                            ? Icons.storefront_rounded
                            : Icons.person_rounded,
                        size: 49,
                        color: orange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name.isEmpty ? 'ผู้ใช้งาน' : name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: dark,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E5),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSeller
                                ? Icons.verified_user_outlined
                                : Icons.person_outline_rounded,
                            color: orange,
                            size: 17,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            role,
                            style: const TextStyle(
                              color: dark,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'I HAVE COM  •  YOUR TECH, YOUR STYLE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'ข้อมูลส่วนตัว',
                style: TextStyle(
                  color: dark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'ตรวจสอบและจัดการข้อมูลบัญชีของคุณ',
                style: TextStyle(color: muted, fontSize: 13),
              ),

              const SizedBox(height: 16),

              // Name field
              _buildFieldCard(
                icon: Icons.person_outline_rounded,
                label: 'ชื่อผู้ใช้',
                child: TextField(
                  controller: _nameController,
                  readOnly: !_isEditing || _isSaving,
                  style: const TextStyle(
                    color: dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _inputDecoration(hint: 'กรอกชื่อผู้ใช้'),
                ),
              ),

              const SizedBox(height: 12),

              // Email field
              _buildFieldCard(
                icon: Icons.email_outlined,
                label: 'อีเมล',
                child: TextFormField(
                  key: ValueKey(user.email),
                  initialValue: user.email ?? 'ไม่มีอีเมล',
                  readOnly: true,
                  style: const TextStyle(color: muted, fontSize: 15),
                  decoration: _inputDecoration(hint: 'อีเมลที่ใช้เข้าสู่ระบบ'),
                ),
              ),

              const SizedBox(height: 22),

              if (!_isEditing)
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _isEditing = true);
                    },
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text(
                      'แก้ไขชื่อ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                )
              else ...[
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveName,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isSaving ? 'กำลังบันทึก...' : 'บันทึกชื่อ',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: orange.withValues(alpha: 0.55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            setState(() {
                              _nameController.text = _originalName;
                              _isEditing = false;
                            });
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: dark,
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('ยกเลิก'),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFieldCard({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: orange, size: 19),
              const SizedBox(width: 9),
              Text(
                label,
                style: const TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
      filled: true,
      fillColor: background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: orange, width: 1.5),
      ),
    );
  }
}
