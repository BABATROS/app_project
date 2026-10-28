import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'owner_dashboard.dart';

class ShopSetupPage extends StatefulWidget {
  const ShopSetupPage({super.key});

  @override
  State<ShopSetupPage> createState() => _ShopSetupPageState();
}

class _ShopSetupPageState extends State<ShopSetupPage> {
  final TextEditingController shopNameController = TextEditingController();

  bool saving = false;

  @override
  void dispose() {
    shopNameController.dispose();
    super.dispose();
  }

  Future<void> createShop() async {
    final shopName = shopNameController.text.trim();

    if (shopName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อร้าน')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อน')));
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await FirebaseFirestore.instance.collection('shops').add({
        'shopName': shopName,
        'ownerId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('สร้างร้านสำเร็จ')));

      shopNameController.clear();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OwnerDashboard()),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สร้างร้านไม่สำเร็จ: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สร้างร้านของฉัน')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            const Icon(Icons.storefront, size: 80),

            const SizedBox(height: 20),

            const Text(
              'สร้างร้านของฉัน',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: shopNameController,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'ชื่อร้าน',
                hintText: 'กรอกชื่อร้านของคุณ',
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: saving ? null : createShop,
                child: saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('สร้างร้าน', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
