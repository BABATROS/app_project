import 'package:flutter/material.dart';

import '../models/cart_model.dart';
import '../services/order.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isOrdering = false;

  static const Color orange = Color(0xFFFF6B00);
  static const Color dark = Color(0xFF191919);
  static const Color muted = Color(0xFF777777);
  static const Color pageBackground = Color(0xFFF7F7F7);

  Future<void> _placeOrder() async {
    if (_isOrdering) return;

    if (CartModel.instance.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเพิ่มสินค้าลงตะกร้าก่อน')),
      );
      return;
    }

    setState(() {
      _isOrdering = true;
    });

    try {
      final orderId = await OrderService().createOrder();

      CartModel.instance.clearCart();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สั่งซื้อสำเร็จ เลขที่คำสั่งซื้อ: $orderId'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สั่งซื้อไม่สำเร็จ: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOrdering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: dark,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'ตะกร้าสินค้า',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 21,
            color: dark,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: CartModel.instance,
        builder: (context, child) {
          final cart = CartModel.instance;
          final items = cart.items;

          if (items.isEmpty) {
            return _buildEmptyCart();
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    // Delivery information
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            color: orange,
                            size: 29,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'พร้อมสำหรับการสั่งซื้อ',
                                  style: TextStyle(
                                    color: dark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'ตรวจสอบสินค้าและจำนวนก่อนยืนยัน',
                                  style: TextStyle(color: muted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.verified_outlined, color: orange),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'รายการสินค้า',
                            style: TextStyle(
                              color: dark,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Text(
                          '${cart.totalQuantity} ชิ้น',
                          style: const TextStyle(
                            color: muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    ...items.map((item) {
                      final product = item.product;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon in place of a product image
                            Container(
                              width: 70,
                              height: 78,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF2E9),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                _productIcon(product.name),
                                color: orange,
                                size: 35,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: dark,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),

                                  const SizedBox(height: 7),

                                  Text(
                                    '฿${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: orange,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      _quantityButton(
                                        icon: Icons.remove_rounded,
                                        onPressed: () {
                                          cart.decreaseQuantity(product);
                                        },
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 13,
                                        ),
                                        child: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: dark,
                                          ),
                                        ),
                                      ),

                                      _quantityButton(
                                        icon: Icons.add_rounded,
                                        onPressed: () {
                                          cart.increaseQuantity(product);
                                        },
                                      ),

                                      const Spacer(),

                                      IconButton(
                                        tooltip: 'ลบสินค้า',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          cart.removeProduct(product);
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.redAccent,
                                          size: 23,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    'รวม ฿${item.subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Bottom total and checkout panel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'จำนวนสินค้า',
                              style: TextStyle(color: muted, fontSize: 14),
                            ),
                          ),
                          Text(
                            '${cart.totalQuantity} ชิ้น',
                            style: const TextStyle(
                              color: dark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'ยอดรวมทั้งหมด',
                              style: TextStyle(
                                color: dark,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '฿${cart.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: orange,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isOrdering ? null : _placeOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orange,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: orange.withValues(
                              alpha: 0.55,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                          child: _isOrdering
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text('กำลังบันทึกคำสั่งซื้อ...'),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_bag_outlined),
                                    SizedBox(width: 10),
                                    Text(
                                      'ยืนยันสั่งซื้อ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: orange.withValues(alpha: 0.12),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 68,
                color: orange,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'ยังไม่มีสินค้าในตะกร้า',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: dark,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'มาเลือกสินค้าไอทีที่คุณชอบกันเถอะ',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 230,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('เลือกซื้อสินค้า'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: orange,
                  side: const BorderSide(color: orange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 31,
      height: 31,
      child: Material(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Icon(icon, size: 18, color: dark),
        ),
      ),
    );
  }

  IconData _productIcon(String name) {
    final text = name.toLowerCase();

    if (text.contains('keyboard') || text.contains('คีย์บอร์ด')) {
      return Icons.keyboard_rounded;
    }
    if (text.contains('mouse') || text.contains('เมาส์')) {
      return Icons.mouse_rounded;
    }
    if (text.contains('laptop') ||
        text.contains('notebook') ||
        text.contains('โน้ตบุ๊ก')) {
      return Icons.laptop_mac_rounded;
    }
    if (text.contains('monitor') || text.contains('จอ')) {
      return Icons.monitor_rounded;
    }
    if (text.contains('headphone') || text.contains('หูฟัง')) {
      return Icons.headphones_rounded;
    }
    if (text.contains('phone') || text.contains('มือถือ')) {
      return Icons.smartphone_rounded;
    }
    if (text.contains('pc') ||
        text.contains('computer') ||
        text.contains('คอม')) {
      return Icons.desktop_windows_rounded;
    }

    return Icons.devices_other_rounded;
  }
}
