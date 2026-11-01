// หน้าผู้ดูแลระบบสำหรับตรวจสอบรายการคำสั่งซื้อที่จัดเก็บใน Firestore
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('คำสั่งซื้อ')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('ไม่สามารถโหลดข้อมูลคำสั่งซื้อได้'),
            );
          }

          final orders = snapshot.data?.docs ?? [];

          if (orders.isEmpty) {
            return const Center(child: Text('ยังไม่มีข้อมูลคำสั่งซื้อ'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data();

              final userId = order['userId']?.toString() ?? '-';
              final shopId = order['shopId']?.toString() ?? '-';
              final totalAmount = order['totalAmount']?.toString() ?? '0';
              final status = order['status']?.toString() ?? '-';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                  title: Text('ยอดรวม: $totalAmount บาท'),
                  subtitle: Text(
                    'ผู้สั่งซื้อ: $userId\n'
                    'ร้านค้า: $shopId\n'
                    'สถานะ: $status',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
