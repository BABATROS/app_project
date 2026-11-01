// หน้าผู้ดูแลระบบสำหรับดูรายการร้านค้าที่ลงทะเบียนไว้ใน Firestore
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminShopsPage extends StatelessWidget {
  const AdminShopsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ร้านค้า')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('shops')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('ไม่สามารถโหลดข้อมูลร้านค้าได้'));
          }

          final shops = snapshot.data?.docs ?? [];

          if (shops.isEmpty) {
            return const Center(child: Text('ยังไม่มีข้อมูลร้านค้า'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final shop = shops[index].data();

              final shopName = shop['shopName']?.toString() ?? '-';

              final ownerId = shop['ownerId']?.toString() ?? '-';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.store)),
                  title: Text(shopName),
                  subtitle: Text('เจ้าของร้าน: $ownerId'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
