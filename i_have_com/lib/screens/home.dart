import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/logout_button.dart';
import '../models/product_model.dart';
import '../services/product.dart';
import '../models/cart_model.dart';
import 'cart.dart';
import 'order_history.dart';
import 'owner_dashboard.dart';
import 'profile.dart';
import 'chat_list_screen.dart';
import 'product_detail.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color orange = Color(0xFFFF6B00);
  static const Color black = Color(0xFF191919);
  static const Color grey = Color(0xFF777777);
  static const Color background = Color(0xFFF7F7F7);
  static const Color line = Color(0xFFEEEEEE);

  String _searchQuery = '';
  String _selectedCategory = 'ทั้งหมด';
  double? _maxPrice;

  static const List<String> _categories = [
    'ทั้งหมด',
    'คอมพิวเตอร์',
    'อุปกรณ์',
    'อุปกรณ์คอมพิวเตอร์',
    'มือถือ',
    'เครื่องใช้ไฟฟ้า',
  ];

  List<Product> _filterProducts(List<Product> products) {
    final query = _searchQuery.trim().toLowerCase();

    return products.where((product) {
      final matchesName = product.name.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == 'ทั้งหมด' ||
          product.category.trim() == _selectedCategory;
      final matchesPrice = _maxPrice == null || product.price <= _maxPrice!;

      return matchesName && matchesCategory && matchesPrice;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'ทั้งหมด';
      _maxPrice = null;
    });
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const CartPage()),
    );
  }

  void _openOrderHistory() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const OrderHistoryPage()),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
    );
  }

  void _openChats() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const ChatListScreen()),
    );
  }

  Widget _userGreeting() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Text(
        'สวัสดี 👋',
        style: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w800,
          color: black,
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name =
            data?['name'] ??
            data?['displayName'] ??
            user.displayName ??
            'ผู้ใช้งาน';

        return Text(
          'สวัสดี, $name 👋',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: black,
            height: 1.3,
          ),
        );
      },
    );
  }

  Widget _sellerManagementButton() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        if (snapshot.data!.data()?['role'] != 'seller') {
          return const SizedBox.shrink();
        }

        return IconButton(
          tooltip: 'จัดการสินค้า',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFFFF0E5),
            foregroundColor: orange,
          ),
          icon: const Icon(Icons.inventory_2_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const OwnerDashboard()),
            );
          },
        );
      },
    );
  }

  IconData _categoryIcon(String category) {
    final value = category.toLowerCase();

    if (value.contains('คอมพิวเตอร์') || value.contains('computer')) {
      return Icons.computer_rounded;
    }
    if (value.contains('มือถือ') ||
        value.contains('โทรศัพท์') ||
        value.contains('phone')) {
      return Icons.smartphone_rounded;
    }
    if (value.contains('เครื่องใช้ไฟฟ้า') ||
        value.contains('ไฟฟ้า') ||
        value.contains('electric')) {
      return Icons.electrical_services_rounded;
    }
    if (value.contains('อุปกรณ์')) {
      return Icons.devices_other_rounded;
    }

    return Icons.memory_rounded;
  }

  Widget _productImage(String imageUrl, {double iconSize = 64}) {
    Widget placeholder() {
      return Center(
        child: Icon(
          _categoryIcon(_selectedCategory),
          size: iconSize,
          color: orange,
        ),
      );
    }

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

  Widget _sectionTitle(String title, {String? subtitle, Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: black,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: grey),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildStoreBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: black,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -18,
            child: Icon(
              Icons.memory_rounded,
              size: 135,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'I HAVE COM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              const Text(
                'อุปกรณ์ที่ใช่\nสำหรับทุกไอเดีย',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'ค้นหาคอมพิวเตอร์และอุปกรณ์ที่คุณต้องการ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedCategory = 'ทั้งหมด';
                    _maxPrice = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: orange,
                  side: const BorderSide(color: orange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 11,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'เลือกซื้อสินค้า',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(width: 7),
                    Icon(Icons.arrow_forward_rounded, size: 17),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) {
        setState(() => _searchQuery = value);
      },
      decoration: InputDecoration(
        hintText: 'ค้นหาสินค้า หรืออุปกรณ์...',
        hintStyle: const TextStyle(fontSize: 12, color: grey),
        prefixIcon: const Icon(Icons.search_rounded, color: orange),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'ล้างการค้นหา',
                onPressed: () {
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: orange, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = _selectedCategory == category;

          return ChoiceChip(
            label: Text(category),
            selected: selected,
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: orange,
            side: BorderSide(color: selected ? orange : line),
            labelStyle: TextStyle(
              color: selected ? Colors.white : black,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (_) {
              setState(() => _selectedCategory = category);
            },
          );
        },
      ),
    );
  }

  Widget _buildPriceFilter() {
    return DropdownButtonFormField<double?>(
      initialValue: _maxPrice,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'ช่วงราคาสินค้า',
        labelStyle: const TextStyle(fontSize: 12, color: grey),
        prefixIcon: const Icon(Icons.tune_rounded, color: orange, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: orange),
        ),
      ),
      items: const [
        DropdownMenuItem<double?>(value: null, child: Text('ทุกราคา')),
        DropdownMenuItem<double?>(value: 500, child: Text('ไม่เกิน 500 บาท')),
        DropdownMenuItem<double?>(
          value: 1000,
          child: Text('ไม่เกิน 1,000 บาท'),
        ),
        DropdownMenuItem<double?>(
          value: 5000,
          child: Text('ไม่เกิน 5,000 บาท'),
        ),
      ],
      onChanged: (value) {
        setState(() => _maxPrice = value);
      },
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
            ? 3
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.58,
          ),
          itemBuilder: (context, index) {
            return _productCard(context, products[index]);
          },
        );
      },
    );
  }

  Widget _buildProductResults() {
    return StreamBuilder<List<Product>>(
      stream: ProductService().getProducts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('โหลดสินค้าไม่สำเร็จ: ${snapshot.error}');

          return _messageCard(
            icon: Icons.cloud_off_outlined,
            title: 'โหลดสินค้าไม่สำเร็จ',
            subtitle: 'กรุณาตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: orange)),
          );
        }

        final allProducts = snapshot.data ?? [];
        final products = _filterProducts(allProducts);

        if (products.isEmpty) {
          return _messageCard(
            icon: Icons.search_off_rounded,
            title: allProducts.isEmpty
                ? 'ยังไม่มีสินค้าในร้าน'
                : 'ไม่พบสินค้าที่ตรงกับเงื่อนไข',
            subtitle: allProducts.isEmpty
                ? 'สินค้าใหม่จะแสดงที่นี่เมื่อร้านค้าเพิ่มสินค้า'
                : 'ลองเปลี่ยนคำค้นหาหรือตัวกรองดูนะ',
            action: allProducts.isEmpty
                ? null
                : TextButton(
                    onPressed: _resetFilters,
                    child: const Text('ล้างตัวกรอง'),
                  ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'พบสินค้า ${products.length} รายการ',
              style: const TextStyle(color: grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _buildProductGrid(products),
          ],
        );
      },
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: line),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0E5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: orange),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: black,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: grey, fontSize: 12, height: 1.5),
          ),
          if (action != null) ...[const SizedBox(height: 8), action],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: orange,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.memory_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'I HAVE COM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: black,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  'TECHNOLOGY STORE',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: grey,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'แชทของฉัน',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFFF0E5),
              foregroundColor: orange,
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: _openChats,
          ),
          const SizedBox(width: 5),
          _sellerManagementButton(),
          const LogoutButton(),
          const SizedBox(width: 5),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _userGreeting(),
              const SizedBox(height: 5),
              const Text(
                'วันนี้กำลังมองหาอะไรอยู่?',
                style: TextStyle(color: grey, fontSize: 13),
              ),
              const SizedBox(height: 20),

              _buildStoreBanner(),
              const SizedBox(height: 24),

              _buildSearchField(),
              const SizedBox(height: 24),

              _sectionTitle(
                'เลือกตามหมวดหมู่',
                subtitle: 'ค้นหาสิ่งที่ต้องการได้ง่ายขึ้น',
              ),
              const SizedBox(height: 12),
              _buildCategories(),
              const SizedBox(height: 16),

              _buildPriceFilter(),
              const SizedBox(height: 26),

              _sectionTitle(
                'สินค้าแนะนำ',
                subtitle: 'เลือกอุปกรณ์ที่เหมาะกับคุณ',
                trailing: TextButton(
                  onPressed: _resetFilters,
                  child: const Text(
                    'ล้างตัวกรอง',
                    style: TextStyle(
                      color: orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _buildProductResults(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 12,
        selectedItemColor: orange,
        unselectedItemColor: const Color(0xFF999999),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        showUnselectedLabels: true,
        onTap: (index) {
          if (index == 1) {
            _openCart();
          } else if (index == 2) {
            _openOrderHistory();
          } else if (index == 3) {
            _openProfile();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'ตะกร้า',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'คำสั่งซื้อ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'บัญชี',
          ),
        ],
      ),
    );
  }

  Widget _productCard(BuildContext context, Product product) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: const BorderSide(color: line),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ProductDetailPage(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _productImage(product.imageUrl, iconSize: 54),
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: grey,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${product.price.toStringAsFixed(2)} บาท',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: orange,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton(
                        onPressed: () {
                          CartModel.instance.addProduct(product);

                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  'เพิ่ม ${product.name} ลงตะกร้าแล้ว',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_shopping_cart_rounded, size: 15),
                              SizedBox(width: 5),
                              Text(
                                'เพิ่มลงตะกร้า',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
