// สร้างคำสั่งซื้อจากตะกร้าปัจจุบัน โดยตรวจร้าน/สต็อกก่อนบันทึกลง Firestore
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ถูกเรียกจากหน้าตะกร้าเพื่อยืนยันสต็อกและสร้างเอกสารคำสั่งซื้อ
  Future<String> createOrder() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('กรุณาเข้าสู่ระบบก่อนสั่งซื้อ');
    }

    final cart = CartModel.instance;
    final cartItems = cart.items;

    if (cartItems.isEmpty) {
      throw Exception('ไม่มีสินค้าในตะกร้า');
    }

    // ตรวจสอบสินค้าและหาร้านค้า
    String? shopId;

    final items = <Map<String, dynamic>>[];

    for (final item in cartItems) {
      final productId = item.product.id;

      final productDoc = await _firestore
          .collection('products')
          .doc(productId)
          .get();

      if (!productDoc.exists) {
        throw Exception('ไม่พบสินค้า ${item.product.name}');
      }

      final productData = productDoc.data();

      if (productData == null) {
        throw Exception('ข้อมูลสินค้าไม่ถูกต้อง');
      }

      final productShopId = productData['shopId']?.toString();

      if (productShopId == null || productShopId.isEmpty) {
        throw Exception(
          'สินค้า ${item.product.name} ยังไม่ได้เชื่อมกับร้านค้า',
        );
      }

      // ระบบรองรับสินค้าจากร้านเดียวต่อ 1 Order
      if (shopId == null) {
        shopId = productShopId;
      } else if (shopId != productShopId) {
        throw Exception('สามารถสั่งซื้อสินค้าจากร้านเดียวต่อครั้งเท่านั้น');
      }

      final price = (productData['price'] as num?)?.toDouble() ?? 0;

      final stock = (productData['stock'] as num?)?.toInt() ?? 0;

      if (item.quantity <= 0) {
        throw Exception('จำนวนสินค้าไม่ถูกต้อง');
      }

      if (item.quantity > stock) {
        throw Exception(
          'สินค้า ${productData['name'] ?? item.product.name} มีไม่เพียงพอ',
        );
      }

      items.add({
        'productId': productId,
        'name': productData['name'] ?? item.product.name,
        'price': price,
        'quantity': item.quantity,
        'subtotal': price * item.quantity,
      });
    }

    if (shopId == null) {
      throw Exception('ไม่พบร้านค้าของสินค้า');
    }

    final totalAmount = items.fold<double>(
      0,
      (total, item) => total + (item['subtotal'] as num).toDouble(),
    );

    // สร้าง Order
    final orderRef = await _firestore.collection('orders').add({
      'userId': user.uid,
      'shopId': shopId,
      'items': items,
      'totalAmount': totalAmount,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return orderRef.id;
  }
}
