import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../services/local_database.dart';

class ProductService {
  final CollectionReference<Map<String, dynamic>> products = FirebaseFirestore
      .instance
      .collection('products');

  final LocalDatabase localDatabase = LocalDatabase.instance;

  // บันทึกสำเนาลง SQLite เฉพาะแพลตฟอร์มที่รองรับ
  Future<void> _cacheProduct(Product product) async {
    if (kIsWeb) return;

    try {
      await localDatabase.saveProduct({'id': product.id, ...product.toMap()});
    } catch (e, stackTrace) {
      debugPrint('บันทึกสินค้าใน SQLite ไม่สำเร็จ: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // อ่านสินค้าจาก Firestore และเก็บสำเนาในเครื่องเมื่อรองรับ
  Stream<List<Product>> getProducts() {
    return products.snapshots().map((snapshot) {
      final productList = snapshot.docs.map((doc) {
        return Product.fromMap(doc.data(), doc.id);
      }).toList();

      if (!kIsWeb) {
        _cacheProductsInBackground(productList);
      }

      return productList;
    });
  }

  Future<void> _cacheProductsInBackground(List<Product> productList) async {
    for (final product in productList) {
      await _cacheProduct(product);
    }
  }

  // เพิ่มสินค้า
  Future<void> addProduct(Product product) async {
    final docRef = await products.add(product.toMap());

    final savedProduct = Product(
      id: docRef.id,
      name: product.name,
      price: product.price,
      category: product.category,
      description: product.description,
      imageUrl: product.imageUrl,
      stock: product.stock,
    );

    await _cacheProduct(savedProduct);
  }

  // แก้ไขสินค้า
  Future<void> updateProduct(Product product) async {
    await products.doc(product.id).update(product.toMap());
    await _cacheProduct(product);
  }

  // ลบสินค้า
  Future<void> deleteProduct(String productId) async {
    await products.doc(productId).delete();

    if (kIsWeb) return;

    try {
      await localDatabase.deleteProduct(productId);
    } catch (e, stackTrace) {
      debugPrint('ลบสินค้าออกจาก SQLite ไม่สำเร็จ: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // อ่านสินค้าจาก SQLite เฉพาะแพลตฟอร์มที่รองรับ
  Future<List<Product>> getLocalProducts() async {
    if (kIsWeb) return [];

    try {
      final rows = await localDatabase.getProducts();

      return rows.map((row) {
        return Product.fromMap(row, row['id'] as String);
      }).toList();
    } catch (e, stackTrace) {
      debugPrint('อ่านสินค้าจาก SQLite ไม่สำเร็จ: $e');
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }
}
