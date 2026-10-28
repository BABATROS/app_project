import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/logout_button.dart';
import 'seller_orders.dart';
import 'home.dart';
import 'chat_list_screen.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการร้านค้า I HAVE COM'),
        actions: [
          IconButton(
            tooltip: 'แชทของฉัน',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const ChatListScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'กลับหน้า Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const HomePage()),
                (route) => false,
              );
            },
          ),
          IconButton(
            tooltip: 'คำสั่งซื้อ',
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SellerOrdersPage()),
              );
            },
          ),
          const LogoutButton(),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('ownerId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('โหลดสินค้าไม่สำเร็จ'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data?.docs ?? [];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showProductDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่มสินค้า'),
                  ),
                ),
              ),
              Expanded(
                child: products.isEmpty
                    ? const Center(child: Text('ยังไม่มีสินค้าในร้าน'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final doc = products[index];
                          final data = doc.data();

                          final name =
                              data['name']?.toString() ?? 'ไม่มีชื่อสินค้า';
                          final price =
                              (data['price'] as num?)?.toDouble() ?? 0;
                          final stock = (data['stock'] as num?)?.toInt() ?? 0;
                          final category = data['category']?.toString() ?? '-';
                          final imageUrl = data['imageUrl']?.toString() ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: _productImage(imageUrl, size: 64),
                              title: Text(name),
                              subtitle: Text(
                                'หมวดหมู่: $category\n'
                                'ราคา: ${price.toStringAsFixed(2)} บาท\n'
                                'คงเหลือ: $stock ชิ้น',
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'แก้ไขสินค้า',
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _showEditProductDialog(
                                      context,
                                      doc.id,
                                      data,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'ลบสินค้า',
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _deleteProduct(context, doc.id, name),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(context),
        tooltip: 'เพิ่มสินค้า',
        child: const Icon(Icons.add),
      ),
    );
  }

  // เลือกรูปภาพ รองรับ Flutter Web
  Future<Uint8List?> _pickProductImage(BuildContext context) async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 50,
    );

    if (file == null) return null;

    final bytes = await file.readAsBytes();

    // จำกัดขนาดเพื่อไม่ให้เอกสาร Firestore ใหญ่เกินไป
    if (bytes.length > 500 * 1024) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('รูปมีขนาดใหญ่เกินไป กรุณาเลือกรูปอื่น'),
          ),
        );
      }
      return null;
    }

    return bytes;
  }

  // แสดงรูปที่เลือกหรือรูปเดิมจาก Firestore
  Widget _productImage(String? imageUrl, {double size = 120}) {
    Widget placeholder() => Container(
      width: size,
      height: size,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.devices, size: 32, color: Colors.grey),
    );

    if (imageUrl == null || imageUrl.isEmpty || imageUrl == 'no-image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: placeholder(),
      );
    }

    if (imageUrl.startsWith('base64:')) {
      try {
        final bytes = base64Decode(imageUrl.substring(7));

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => placeholder(),
          ),
        );
      } catch (_) {
        return placeholder();
      }
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => placeholder(),
        ),
      );
    }

    return placeholder();
  }

  Widget _imagePreview(Uint8List? imageBytes, {String? existingImageUrl}) {
    if (imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          imageBytes,
          height: 120,
          width: 120,
          fit: BoxFit.cover,
        ),
      );
    }

    if (existingImageUrl != null &&
        existingImageUrl != 'no-image' &&
        existingImageUrl.isNotEmpty) {
      return _productImage(existingImageUrl, size: 120);
    }

    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.add_photo_alternate_outlined, size: 36),
    );
  }

  // เพิ่มสินค้าใหม่
  Future<void> _showProductDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    final stockController = TextEditingController();

    Uint8List? selectedImageBytes;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          bool saving = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('เพิ่มสินค้าใหม่'),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _imagePreview(selectedImageBytes),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: saving
                                ? null
                                : () async {
                                    try {
                                      final image = await _pickProductImage(
                                        context,
                                      );

                                      if (image != null) {
                                        setDialogState(() {
                                          selectedImageBytes = image;
                                        });
                                      }
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'เลือกรูปไม่สำเร็จ: $e',
                                              ),
                                            ),
                                          );
                                    }
                                  },
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('เลือกรูปสินค้า'),
                          ),
                        ),
                        _buildField(
                          nameController,
                          'ชื่อสินค้า',
                          required: true,
                        ),
                        _buildField(
                          priceController,
                          'ราคา (บาท)',
                          required: true,
                          number: true,
                        ),
                        _buildField(
                          categoryController,
                          'หมวดหมู่',
                          required: true,
                        ),
                        _buildField(descriptionController, 'รายละเอียดสินค้า'),
                        _buildField(
                          stockController,
                          'จำนวนสินค้า',
                          required: true,
                          number: true,
                          integer: true,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('ยกเลิก'),
                  ),
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            final price = double.tryParse(
                              priceController.text.trim(),
                            );
                            final stock = int.tryParse(
                              stockController.text.trim(),
                            );

                            if (price == null ||
                                !price.isFinite ||
                                price < 0 ||
                                stock == null ||
                                stock < 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'กรุณากรอกราคาและจำนวนสินค้าให้ถูกต้อง',
                                  ),
                                ),
                              );
                              return;
                            }

                            setDialogState(() => saving = true);

                            try {
                              final user = FirebaseAuth.instance.currentUser;

                              if (user == null) {
                                throw Exception(
                                  'ไม่พบผู้ใช้ที่กำลังเข้าสู่ระบบ',
                                );
                              }

                              final shopQuery = await FirebaseFirestore.instance
                                  .collection('shops')
                                  .where('ownerId', isEqualTo: user.uid)
                                  .limit(1)
                                  .get();

                              if (shopQuery.docs.isEmpty) {
                                throw Exception('ไม่พบร้านของผู้ขาย');
                              }

                              final shopId = shopQuery.docs.first.id;

                              final imageUrl = selectedImageBytes == null
                                  ? 'no-image'
                                  : 'base64:${base64Encode(selectedImageBytes!)}';

                              await FirebaseFirestore.instance
                                  .collection('products')
                                  .add({
                                    'name': nameController.text.trim(),
                                    'price': price,
                                    'category': categoryController.text.trim(),
                                    'description': descriptionController.text
                                        .trim(),
                                    'imageUrl': imageUrl,
                                    'stock': stock,
                                    'ownerId': user.uid,
                                    'shopId': shopId,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });

                              if (!dialogContext.mounted) return;

                              Navigator.pop(dialogContext);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('เพิ่มสินค้าสำเร็จ'),
                                ),
                              );
                            } catch (e) {
                              if (!dialogContext.mounted) return;

                              setDialogState(() => saving = false);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('เพิ่มสินค้าไม่สำเร็จ: $e'),
                                ),
                              );
                            }
                          },
                    child: Text(saving ? 'กำลังบันทึก...' : 'บันทึกสินค้า'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      priceController.dispose();
      categoryController.dispose();
      descriptionController.dispose();
      stockController.dispose();
    }
  }

  // แก้ไขสินค้า
  Future<void> _showEditProductDialog(
    BuildContext context,
    String productId,
    Map<String, dynamic> data,
  ) async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: data['name']?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: data['price']?.toString() ?? '',
    );
    final categoryController = TextEditingController(
      text: data['category']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: data['description']?.toString() ?? '',
    );
    final stockController = TextEditingController(
      text: data['stock']?.toString() ?? '',
    );

    Uint8List? selectedImageBytes;
    final existingImageUrl = data['imageUrl']?.toString() ?? 'no-image';

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          bool saving = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('แก้ไขสินค้า'),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _imagePreview(
                          selectedImageBytes,
                          existingImageUrl: existingImageUrl,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: saving
                                ? null
                                : () async {
                                    try {
                                      final image = await _pickProductImage(
                                        context,
                                      );

                                      if (image != null) {
                                        setDialogState(() {
                                          selectedImageBytes = image;
                                        });
                                      }
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'เลือกรูปไม่สำเร็จ: $e',
                                              ),
                                            ),
                                          );
                                    }
                                  },
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('เลือกรูปใหม่'),
                          ),
                        ),
                        _buildField(
                          nameController,
                          'ชื่อสินค้า',
                          required: true,
                        ),
                        _buildField(
                          priceController,
                          'ราคา (บาท)',
                          required: true,
                          number: true,
                        ),
                        _buildField(
                          categoryController,
                          'หมวดหมู่',
                          required: true,
                        ),
                        _buildField(descriptionController, 'รายละเอียดสินค้า'),
                        _buildField(
                          stockController,
                          'จำนวนสินค้า',
                          required: true,
                          number: true,
                          integer: true,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('ยกเลิก'),
                  ),
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            final price = double.tryParse(
                              priceController.text.trim(),
                            );
                            final stock = int.tryParse(
                              stockController.text.trim(),
                            );

                            if (price == null ||
                                !price.isFinite ||
                                price < 0 ||
                                stock == null ||
                                stock < 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'กรุณากรอกราคาและจำนวนสินค้าให้ถูกต้อง',
                                  ),
                                ),
                              );
                              return;
                            }

                            setDialogState(() => saving = true);

                            try {
                              final updates = <String, dynamic>{
                                'name': nameController.text.trim(),
                                'price': price,
                                'category': categoryController.text.trim(),
                                'description': descriptionController.text
                                    .trim(),
                                'stock': stock,
                              };

                              // เปลี่ยน imageUrl เฉพาะเมื่อเลือกรูปใหม่
                              if (selectedImageBytes != null) {
                                updates['imageUrl'] =
                                    'base64:${base64Encode(selectedImageBytes!)}';
                              }

                              await FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(productId)
                                  .update(updates);

                              if (!dialogContext.mounted) return;

                              Navigator.pop(dialogContext);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('แก้ไขสินค้าสำเร็จ'),
                                ),
                              );
                            } catch (e) {
                              if (!dialogContext.mounted) return;

                              setDialogState(() => saving = false);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('แก้ไขสินค้าไม่สำเร็จ: $e'),
                                ),
                              );
                            }
                          },
                    child: Text(saving ? 'กำลังบันทึก...' : 'บันทึกการแก้ไข'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      priceController.dispose();
      categoryController.dispose();
      descriptionController.dispose();
      stockController.dispose();
    }
  }

  // ช่องกรอกข้อมูล
  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
    bool integer = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';

          if (required && text.isEmpty) {
            return 'กรุณากรอก$label';
          }

          if (number && text.isNotEmpty) {
            final parsed = integer ? int.tryParse(text) : double.tryParse(text);

            if (parsed == null) {
              return 'กรุณากรอกตัวเลขให้ถูกต้อง';
            }
          }

          return null;
        },
      ),
    );
  }

  // ลบสินค้า
  Future<void> _deleteProduct(
    BuildContext context,
    String productId,
    String productName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการลบสินค้า'),
        content: Text('ต้องการลบ "$productName" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ลบสินค้า'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ลบสินค้าสำเร็จ')));
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('ลบสินค้าไม่สำเร็จ: $e')));
    }
  }
}
