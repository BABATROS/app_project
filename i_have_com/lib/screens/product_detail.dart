// หน้ารายละเอียดสินค้าที่เปิดจากหน้าร้าน แสดงข้อมูลสินค้าและเพิ่มสินค้าลงตะกร้ากลาง
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../models/cart_model.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  static const Color orange = Color(0xFFFF6B00);
  static const Color black = Color(0xFF191919);
  static const Color grey = Color(0xFF777777);
  static const Color background = Color(0xFFF7F7F7);

  Widget _productImage() {
    Widget placeholder() {
      return const Center(
        child: Icon(Icons.devices_other_rounded, size: 90, color: orange),
      );
    }

    final imageUrl = product.imageUrl;

    if (imageUrl.startsWith('base64:')) {
      try {
        final Uint8List bytes = base64Decode(imageUrl.substring(7));

        return Image.memory(
          bytes,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => placeholder(),
        );
      } catch (_) {
        return placeholder();
      }
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => placeholder(),
      );
    }

    return placeholder();
  }

  void _addToCart(BuildContext context) {
    // ปุ่มเพิ่มลงตะกร้าอัปเดต CartModel กลางที่หน้าตะกร้าใช้แสดงผล
    CartModel.instance.addProduct(product);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('เพิ่ม ${product.name} ลงตะกร้าแล้ว'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'รายละเอียดสินค้า',
          style: TextStyle(color: black, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _productImage(),
              ),
              const SizedBox(height: 20),

              Text(
                product.category.isEmpty ? 'ไม่ระบุหมวดหมู่' : product.category,
                style: const TextStyle(color: grey, fontSize: 13),
              ),
              const SizedBox(height: 8),

              Text(
                product.name,
                style: const TextStyle(
                  color: black,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                '${product.price.toStringAsFixed(2)} บาท',
                style: const TextStyle(
                  color: orange,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'รายละเอียดสินค้า',
                      style: TextStyle(
                        color: black,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      product.description.trim().isEmpty
                          ? 'ยังไม่มีรายละเอียดสินค้า'
                          : product.description,
                      style: const TextStyle(
                        color: grey,
                        fontSize: 14,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, color: grey),
                        const SizedBox(width: 10),
                        const Text(
                          'สินค้าคงเหลือ',
                          style: TextStyle(color: black, fontSize: 14),
                        ),
                        const Spacer(),
                        Text(
                          '${product.stock} ชิ้น',
                          style: TextStyle(
                            color: product.stock > 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: product.stock > 0
                      ? () => _addToCart(context)
                      : null,
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: Text(
                    product.stock > 0 ? 'เพิ่มลงตะกร้า' : 'สินค้าหมด',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
