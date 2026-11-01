// หน้าเข้าสู่ระบบ เชื่อม Firebase Authentication และพาผู้ใช้ไปยังหน้าตามสิทธิ์บัญชี
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'register.dart';
import 'home.dart';
import 'owner_dashboard.dart';
import 'shop_setup.dart';
import 'admin.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกอีเมลและรหัสผ่าน')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // 1. เข้าสู่ระบบด้วย Firebase Authentication
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }

      // 2. อ่านข้อมูลผู้ใช้จาก Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      // 3. ตรวจสอบว่ามีโปรไฟล์หรือไม่
      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบข้อมูลโปรไฟล์ กรุณาติดต่อผู้ดูแลระบบ'),
          ),
        );
        return;
      }

      // 4. ตรวจสอบสิทธิ์ผู้ใช้

      // 4. ตรวจสอบสิทธิ์ผู้ใช้
      final role = userDoc.data()?['role'];

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminPage()),
        );
      } else if (role == 'customer') {
        // ลูกค้าไปหน้าร้านค้า
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else if (role == 'seller') {
        // ผู้ขายตรวจสอบว่ามีร้านแล้วหรือยัง
        final shopQuery = await FirebaseFirestore.instance
            .collection('shops')
            .where('ownerId', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (!mounted) return;

        if (shopQuery.docs.isEmpty) {
          // ยังไม่มีร้าน → ไปสร้างร้าน
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ShopSetupPage()),
          );
        } else {
          // มีร้านแล้ว → ไปหน้าจัดการร้าน
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OwnerDashboard()),
          );
        }
      } else {
        // ไม่พบสิทธิ์ที่ระบบอนุญาต
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บัญชีนี้ยังไม่ได้รับสิทธิ์เข้าใช้งาน')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'เข้าสู่ระบบไม่สำเร็จ';

      if (e.code == 'invalid-email') {
        message = 'รูปแบบอีเมลไม่ถูกต้อง';
      } else if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password') {
        message = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      } else if (e.code == 'too-many-requests') {
        message = 'ลองเข้าสู่ระบบใหม่ภายหลัง';
      } else if (e.code == 'network-request-failed') {
        message = 'เชื่อมต่ออินเทอร์เน็ตไม่ได้';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      // หากตรวจสอบโปรไฟล์ไม่สำเร็จ ให้ออกจากระบบ
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ตรวจสอบข้อมูลผู้ใช้ไม่สำเร็จ กรุณาลองใหม่'),
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
      appBar: AppBar(title: const Text('เข้าสู่ระบบ')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'I HAVE COM',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ร้านอุปกรณ์คอมพิวเตอร์และเครื่องใช้ไฟฟ้า',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 50),
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
                  onSubmitted: (_) {
                    if (!loading) login();
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: loading ? null : login,
                  child: Text(
                    loading ? 'กำลังเข้าสู่ระบบ...' : 'เข้าสู่ระบบ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterPage(),
                      ),
                    );
                  },
                  child: const Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
