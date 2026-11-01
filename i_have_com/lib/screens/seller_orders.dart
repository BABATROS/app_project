// หน้าผู้ขายสำหรับติดตามคำสั่งซื้อของร้าน โดยกรองออเดอร์ตาม shopId ใน Firestore
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerOrdersPage extends StatelessWidget {
  const SellerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('กรุณาเข้าสู่ระบบก่อน')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('คำสั่งซื้อ')),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('shops')
            .where('ownerId', isEqualTo: user.uid)
            .limit(1)
            .get(),
        builder: (context, shopSnapshot) {
          if (shopSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (shopSnapshot.hasError) {
            return const Center(child: Text('โหลดข้อมูลร้านไม่สำเร็จ'));
          }

          if (shopSnapshot.data == null || shopSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('ไม่พบร้านของผู้ขาย'));
          }

          final shopId = shopSnapshot.data!.docs.first.id;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('shopId', isEqualTo: shopId)
                .snapshots(),
            builder: (context, orderSnapshot) {
              if (orderSnapshot.hasError) {
                return const Center(child: Text('โหลดคำสั่งซื้อไม่สำเร็จ'));
              }

              if (orderSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final orders = orderSnapshot.data?.docs ?? [];

              if (orders.isEmpty) {
                return const Center(child: Text('ยังไม่มีคำสั่งซื้อ'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index].data();

                  final orderId = orders[index].id;

                  final total = (order['totalAmount'] as num?)?.toDouble() ?? 0;

                  final status = order['status']?.toString() ?? 'pending';

                  final userId = order['userId']?.toString() ?? '-';

                  final items = (order['items'] as List?) ?? [];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'คำสั่งซื้อ #${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text('ลูกค้า: $userId'),

                          const SizedBox(height: 8),

                          const Text(
                            'สินค้า:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 4),

                          ...items.map((item) {
                            final itemData = Map<String, dynamic>.from(item);

                            final name =
                                itemData['name']?.toString() ?? 'สินค้า';

                            final quantity =
                                (itemData['quantity'] as num?)?.toInt() ?? 1;

                            final price =
                                (itemData['price'] as num?)?.toDouble() ?? 0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '$name × $quantity '
                                '(${price.toStringAsFixed(2)} บาท)',
                              ),
                            );
                          }),

                          const Divider(),

                          Text(
                            'ยอดรวม: ${total.toStringAsFixed(2)} บาท',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'สถานะ: ${_statusText(status)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _statusColor(status),
                            ),
                          ),
                        ],
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

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'รอดำเนินการ';

      case 'processing':
        return 'กำลังเตรียมสินค้า';

      case 'completed':
        return 'เสร็จสิ้น';

      case 'cancelled':
        return 'ยกเลิก';

      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;

      case 'processing':
        return Colors.blue;

      case 'completed':
        return Colors.green;

      case 'cancelled':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }
}
