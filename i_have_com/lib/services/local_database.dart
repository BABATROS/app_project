// ฐานข้อมูล SQLite ในอุปกรณ์สำหรับแคชสินค้า เพื่อให้บริการสินค้าใช้งานข้อมูลในเครื่องได้
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'i_have_com.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            price REAL NOT NULL,
            stock INTEGER NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            imageUrl TEXT NOT NULL DEFAULT ''
          )
        ''');
      },
    );

    return _database!;
  }

  Future<void> saveProduct(Map<String, dynamic> product) async {
    final db = await database;

    await db.insert('products', {
      'id': product['id'],
      'name': product['name'],
      'category': product['category'],
      'price': (product['price'] as num).toDouble(),
      'stock': (product['stock'] as num).toInt(),
      'description': product['description'] ?? '',
      'imageUrl': product['imageUrl'] ?? '',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;

    return db.query('products', orderBy: 'name ASC');
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;

    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
