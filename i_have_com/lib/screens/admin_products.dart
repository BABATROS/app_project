// หน้าผู้ดูแลระบบสำหรับค้นหาและตรวจสอบสินค้า รวมถึงสรุปจำนวนสินค้าและสต็อก
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const Color _primaryOrange = Color(0xFFFF6B00);
const Color _primaryBlack = Color(0xFF202020);
const Color _pageBackground = Color(0xFFF7F7F7);
const Color _borderColor = Color(0xFFEEEEEE);

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatPrice(dynamic value) {
    final price = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;

    return price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2);
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  IconData _categoryIcon(String category) {
    final value = category.toLowerCase();

    if (value.contains('computer') ||
        value.contains('คอม') ||
        value.contains('โน้ตบุ๊ก')) {
      return Icons.computer_rounded;
    }

    if (value.contains('accessory') || value.contains('อุปกรณ์เสริม')) {
      return Icons.headphones_rounded;
    }

    if (value.contains('monitor') || value.contains('จอ')) {
      return Icons.monitor_rounded;
    }

    if (value.contains('keyboard') || value.contains('คีย์บอร์ด')) {
      return Icons.keyboard_rounded;
    }

    if (value.contains('mouse') || value.contains('เมาส์')) {
      return Icons.mouse_rounded;
    }

    return Icons.devices_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'จัดการสินค้า',
              style: TextStyle(
                color: _primaryBlack,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'ตรวจสอบรายการสินค้าทั้งหมด',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(height: 1, color: _borderColor),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryOrange),
                  );
                }

                if (snapshot.hasError) {
                  return _buildError();
                }

                final allProducts = snapshot.data?.docs ?? [];

                final products = allProducts.where((doc) {
                  final product = doc.data();
                  final query = _searchQuery.toLowerCase();

                  if (query.isEmpty) return true;

                  final name = product['name']?.toString().toLowerCase() ?? '';
                  final category =
                      product['category']?.toString().toLowerCase() ?? '';
                  final description =
                      product['description']?.toString().toLowerCase() ?? '';

                  return name.contains(query) ||
                      category.contains(query) ||
                      description.contains(query);
                }).toList();

                final totalStock = allProducts.fold<int>(
                  0,
                  (total, doc) => total + _toInt(doc.data()['stock']),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                      child: _buildSummary(
                        totalProducts: allProducts.length,
                        totalStock: totalStock,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value.trim());
                        },
                        decoration: InputDecoration(
                          hintText: 'ค้นหาชื่อสินค้า หรือหมวดหมู่...',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Colors.black38,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: _primaryOrange,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  tooltip: 'ล้างคำค้นหา',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: _primaryOrange,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'รายการสินค้า',
                              style: TextStyle(
                                color: _primaryBlack,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryOrange.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${products.length} รายการ',
                              style: const TextStyle(
                                color: _primaryOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: products.isEmpty
                          ? _buildEmpty(isSearching: _searchQuery.isNotEmpty)
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                              itemCount: products.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final product = products[index].data();

                                return _buildProductCard(
                                  product: product,
                                  productId: products[index].id,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary({required int totalProducts, required int totalStock}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _primaryBlack,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _primaryOrange.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: _primaryOrange,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ภาพรวมสินค้า',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  '$totalProducts รายการสินค้า',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 42, color: Colors.white24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'สต็อกรวม',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 5),
              Text(
                '$totalStock ชิ้น',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({
    required Map<String, dynamic> product,
    required String productId,
  }) {
    final name = product['name']?.toString() ?? 'ไม่มีชื่อสินค้า';
    final category = product['category']?.toString() ?? 'ไม่ระบุหมวดหมู่';
    final price = _formatPrice(product['price']);
    final stock = _toInt(product['stock']);
    final imageUrl = product['imageUrl']?.toString() ?? '';

    final isLowStock = stock <= 5;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 76,
            height: 82,
            decoration: BoxDecoration(
              color: _pageBackground,
              borderRadius: BorderRadius.circular(13),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _productPlaceholder(category),
                  )
                : _productPlaceholder(category),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primaryBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  '$price บาท',
                  style: const TextStyle(
                    color: _primaryOrange,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isLowStock
                        ? const Color(0xFFFFF0E8)
                        : const Color(0xFFEAF7EE),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLowStock
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 13,
                        color: isLowStock
                            ? _primaryOrange
                            : const Color(0xFF25834A),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'คงเหลือ $stock ชิ้น',
                        style: TextStyle(
                          color: isLowStock
                              ? _primaryOrange
                              : const Color(0xFF25834A),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'รหัสสินค้า',
            onPressed: () {
              _showProductId(productId);
            },
            icon: const Icon(
              Icons.info_outline_rounded,
              color: Colors.black45,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productPlaceholder(String category) {
    return Center(
      child: Icon(_categoryIcon(category), size: 35, color: _primaryOrange),
    );
  }

  Widget _buildEmpty({required bool isSearching}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.inventory_2_outlined,
                size: 38,
                color: _primaryOrange,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isSearching ? 'ไม่พบสินค้าที่ค้นหา' : 'ยังไม่มีข้อมูลสินค้า',
              style: const TextStyle(
                color: _primaryBlack,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'ลองเปลี่ยนคำค้นหาแล้วลองอีกครั้ง'
                  : 'รายการสินค้าจะแสดงที่นี่เมื่อมีข้อมูล',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: _primaryOrange,
            ),
            const SizedBox(height: 12),
            const Text(
              'ไม่สามารถโหลดข้อมูลสินค้าได้',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _primaryBlack,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'กรุณาตรวจสอบอินเทอร์เน็ตและสิทธิ์การเข้าถึงข้อมูล',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('ลองอีกครั้ง'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryOrange,
                side: const BorderSide(color: _primaryOrange),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductId(String productId) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ข้อมูลสินค้า',
                  style: TextStyle(
                    color: _primaryBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'รหัสสินค้าใน Firestore',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  productId,
                  style: const TextStyle(
                    color: _primaryOrange,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('ปิด'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
