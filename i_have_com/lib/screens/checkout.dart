import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const CheckoutPage({super.key, required this.cartItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool loading = false;

  double get totalPrice {
    double total = 0;

    for (final item in widget.cartItems) {
      final price = (item['price'] as num?)?.toDouble() ?? 0;
      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;

      total += price * quantity;
    }

    return total;
  }

  Future<void> _placeOrder() async {
    if (widget.cartItems.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ไม่มีสินค้าในตะกร้า')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนสั่งซื้อ')),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      /*
       * ตรวจสอบสินค้าและดึง shopId
       */
      final List<Map<String, dynamic>> orderItems = [];

      String? shopId;

      for (final item in widget.cartItems) {
        final productId = item['productId']?.toString();

        if (productId == null || productId.isEmpty) {
          throw Exception('ไม่พบรหัสสินค้า');
        }

        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();

        if (!productDoc.exists) {
          throw Exception('ไม่พบสินค้า');
        }

        final productData = productDoc.data();

        if (productData == null) {
          throw Exception('ข้อมูลสินค้าไม่ถูกต้อง');
        }

        final productShopId = productData['shopId']?.toString();

        if (productShopId == null || productShopId.isEmpty) {
          throw Exception('สินค้านี้ยังไม่ได้เชื่อมกับร้านค้า');
        }

        /*
         * ตอนนี้ระบบรองรับการสั่งซื้อจากร้านเดียวต่อ 1 Order
         */
        if (shopId == null) {
          shopId = productShopId;
        } else if (shopId != productShopId) {
          throw Exception('สามารถสั่งซื้อสินค้าจากร้านเดียวต่อครั้งเท่านั้น');
        }

        final quantity = (item['quantity'] as num?)?.toInt() ?? 1;

        final price = (productData['price'] as num?)?.toDouble() ?? 0;

        final stock = (productData['stock'] as num?)?.toInt() ?? 0;

        if (quantity <= 0) {
          throw Exception('จำนวนสินค้าไม่ถูกต้อง');
        }

        if (quantity > stock) {
          throw Exception('สินค้า ${productData['name'] ?? ''} มีไม่เพียงพอ');
        }

        orderItems.add({
          'productId': productId,
          'name': productData['name'],
          'price': price,
          'quantity': quantity,
        });
      }

      /*
       * สร้าง Order
       */
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'shopId': shopId,
        'items': orderItems,
        'total': totalPrice,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('สั่งซื้อสำเร็จ')));

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('สั่งซื้อไม่สำเร็จ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ยืนยันคำสั่งซื้อ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.cartItems.length,
                itemBuilder: (context, index) {
                  final item = widget.cartItems[index];

                  final name = item['name']?.toString() ?? 'สินค้า';

                  final price = (item['price'] as num?)?.toDouble() ?? 0;

                  final quantity = (item['quantity'] as num?)?.toInt() ?? 1;

                  return Card(
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text(
                        '${price.toStringAsFixed(2)} บาท × $quantity',
                      ),
                      trailing: Text(
                        '${(price * quantity).toStringAsFixed(2)} บาท',
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ยอดรวม',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${totalPrice.toStringAsFixed(2)} บาท',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _placeOrder,
                child: Text(loading ? 'กำลังสั่งซื้อ...' : 'ยืนยันการสั่งซื้อ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
