// แหล่งข้อมูลสินค้าให้หน้าร้านและหน้าผู้ขาย โดยซิงก์ Firestore กับ SQLite
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import 'local_database.dart';

class ProductService {
  final CollectionReference<Map<String, dynamic>> products = FirebaseFirestore
      .instance
      .collection('products');

  final LocalDatabase localDatabase = LocalDatabase.instance;

  // บันทึกลง SQLite เฉพาะแพลตฟอร์มที่รองรับ
  Future<void> _cacheProduct(Product product) async {
    if (kIsWeb) return;

    try {
      await localDatabase.saveProduct({'id': product.id, ...product.toMap()});
    } catch (e, stackTrace) {
      debugPrint('บันทึกสินค้าใน SQLite ไม่สำเร็จ: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // สตรีมสินค้าจาก Firestore และอัปเดตแคชในเครื่องเมื่อมีข้อมูลใหม่
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

  // เพิ่มสินค้าใน Firestore แล้วเก็บสำเนาในแคช
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

  // แก้ไขสินค้าใน Firestore แล้วปรับข้อมูลในแคช
  Future<void> updateProduct(Product product) async {
    await products.doc(product.id).update(product.toMap());
    await _cacheProduct(product);
  }

  // ลบสินค้าจาก Firestore และนำรายการนั้นออกจากแคชในเครื่อง
  Future<void> deleteProduct(String productId) async {
    await products.doc(productId).delete();

    if (kIsWeb) return;

    try {
      await localDatabase.deleteProduct(productId);
    } catch (e, stackTrace) {
      debugPrint('ลบสินค้าใน SQLite ไม่สำเร็จ: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // อ่านสินค้าใน SQLite เฉพาะแพลตฟอร์มที่รองรับ
  Future<List<Product>> getLocalProducts() async {
    if (kIsWeb) return [];

    try {
      final rows = await localDatabase.getProducts();

      return rows.map((row) {
        return Product.fromMap(row, row['id'] as String);
      }).toList();
    } catch (e, stackTrace) {
      debugPrint('อ่านสินค้าใน SQLite ไม่สำเร็จ: $e');
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }
}
