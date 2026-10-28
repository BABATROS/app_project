import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  // ประเภทบัญชีเริ่มต้นเป็นลูกค้า
  String selectedRole = 'customer';

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('รหัสผ่านไม่ตรงกัน')));
      return;
    }

    setState(() => loading = true);

    User? newUser;

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      newUser = credential.user;

      if (newUser == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }

      await newUser.updateDisplayName(username);

      // บันทึกข้อมูลบัญชีผู้ใช้
      await FirebaseFirestore.instance.collection('users').doc(newUser.uid).set(
        {
          'username': username,
          'email': email,
          'role': selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // บันทึกชื่อที่ใช้แสดงในระบบแชท
      await FirebaseFirestore.instance
          .collection('publicProfiles')
          .doc(newUser.uid)
          .set({'username': username, 'displayName': username});

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('สมัครสมาชิกสำเร็จ')));

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'สมัครสมาชิกไม่สำเร็จ';

      if (e.code == 'email-already-in-use') {
        message = 'อีเมลนี้มีบัญชีอยู่แล้ว';
      } else if (e.code == 'invalid-email') {
        message = 'รูปแบบอีเมลไม่ถูกต้อง';
      } else if (e.code == 'weak-password') {
        message = 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
      } else if (e.code == 'network-request-failed') {
        message = 'เชื่อมต่ออินเทอร์เน็ตไม่ได้';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      debugPrint('REGISTER ERROR: $e');
      // ถ้าสร้างบัญชีแล้ว แต่บันทึกโปรไฟล์ไม่สำเร็จ
      // ลบบัญชีที่เพิ่งสร้าง เพื่อไม่ให้เหลือบัญชีที่ตั้งค่าไม่ครบ
      if (newUser != null) {
        try {
          await newUser.delete();
        } catch (_) {
          // หากลบไม่สำเร็จ ให้แจ้งข้อผิดพลาดด้านล่าง
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'บันทึกข้อมูลไม่สำเร็จ กรุณาตรวจสอบ Firebase Rules แล้วลองใหม่',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),

                const Text(
                  'สร้างบัญชี',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                const Text(
                  'สมัครสมาชิกเพื่อเริ่มใช้งาน I HAVE COM',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 40),

                const Text(
                  'ชื่อผู้ใช้',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    hintText: 'กรอกชื่อผู้ใช้',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),

                const Text(
                  'อีเมล',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'กรอกอีเมล',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  'ประเภทบัญชี',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.account_circle_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'customer', child: Text('ลูกค้า')),
                    DropdownMenuItem(
                      value: 'seller',
                      child: Text('ผู้ขาย / เจ้าของร้าน'),
                    ),
                  ],
                  onChanged: loading
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              selectedRole = value;
                            });
                          }
                        },
                ),

                const SizedBox(height: 20),

                const Text(
                  'รหัสผ่าน',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'กรอกรหัสผ่าน',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'ยืนยันรหัสผ่าน',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'กรอกรหัสผ่านอีกครั้ง',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: loading ? null : register,
                  child: Text(
                    loading ? 'กำลังสมัครสมาชิก...' : 'สมัครสมาชิก',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('มีบัญชีอยู่แล้ว? เข้าสู่ระบบ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
