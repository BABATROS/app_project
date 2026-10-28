import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติคำสั่งซื้อ')),
      body: user == null
          ? const Center(child: Text('กรุณาเข้าสู่ระบบก่อน'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('โหลดประวัติคำสั่งซื้อไม่สำเร็จ'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text('ยังไม่มีประวัติคำสั่งซื้อ'),
                      ],
                    ),
                  );
                }

                // เรียงคำสั่งซื้อล่าสุดไว้ด้านบน
                docs.sort((a, b) {
                  final aTime = a.data()['createdAt'];
                  final bTime = b.data()['createdAt'];

                  final aDate = aTime is Timestamp
                      ? aTime.toDate()
                      : DateTime.fromMillisecondsSinceEpoch(0);

                  final bDate = bTime is Timestamp
                      ? bTime.toDate()
                      : DateTime.fromMillisecondsSinceEpoch(0);

                  return bDate.compareTo(aDate);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();

                    final items = data['items'] as List<dynamic>? ?? [];

                    final total =
                        (data['totalAmount'] as num?)?.toDouble() ?? 0;

                    final status = data['status'] as String? ?? 'pending';

                    final createdAt = data['createdAt'];

                    final dateText = createdAt is Timestamp
                        ? _formatDate(createdAt.toDate())
                        : 'กำลังบันทึกวันที่...';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: const Icon(
                          Icons.receipt_long,
                          color: Color(0xFFFF6B00),
                        ),
                        title: Text(
                          'คำสั่งซื้อ #${doc.id.substring(0, 6)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '$dateText\n'
                          'ยอดรวม ฿${total.toStringAsFixed(2)}',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('สถานะ: '),
                                    _statusLabel(status),
                                  ],
                                ),
                                const Divider(),
                                const Text(
                                  'รายการสินค้า',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ...items.map((item) {
                                  final product = Map<String, dynamic>.from(
                                    item as Map,
                                  );

                                  final name =
                                      product['name']?.toString() ?? 'สินค้า';

                                  final quantity =
                                      (product['quantity'] as num?)?.toInt() ??
                                      0;

                                  final subtotal =
                                      (product['subtotal'] as num?)
                                          ?.toDouble() ??
                                      0;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text('$name × $quantity'),
                                        ),
                                        Text('฿${subtotal.toStringAsFixed(2)}'),
                                      ],
                                    ),
                                  );
                                }),
                                const Divider(),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'รวม ฿${total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');

    return '$d/$m/$y $h:$min';
  }

  static Widget _statusLabel(String status) {
    final isPending = status == 'pending';

    final label = switch (status) {
      'pending' => 'รอดำเนินการ',
      'paid' => 'ชำระเงินแล้ว',
      'shipped' => 'จัดส่งแล้ว',
      'completed' => 'สำเร็จ',
      'cancelled' => 'ยกเลิก',
      _ => status,
    };

    return Chip(
      label: Text(label),
      backgroundColor: isPending
          ? Colors.orange.shade100
          : Colors.green.shade100,
      visualDensity: VisualDensity.compact,
    );
  }
}
