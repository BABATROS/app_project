import 'package:flutter_test/flutter_test.dart';
import 'package:i_have_com/main.dart';
import 'package:i_have_com/models/product_model.dart';
import 'package:i_have_com/models/cart_model.dart';

Product createTestProduct({
  String id = 'p1',
  String name = 'Gaming Mouse',
  double price = 500.0,
  String category = 'Accessories',
  int stock = 10,
}) {
  return Product(
    id: id,
    name: name,
    price: price,
    category: category,
    description: 'Test product description',
    imageUrl: 'https://example.com/product.png',
    stock: stock,
  );
}

void main() {
  // 1. Widget Test: ตรวจสอบหน้าเริ่มต้นของแอป
  testWidgets('01 - I HAVE COM app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('I HAVE COM'), findsWidgets);
    expect(find.text('เริ่มใช้งาน'), findsOneWidget);
  });

  group('Product Model Tests', () {
    // 2
    test('02 - Product.fromMap reads product data correctly', () {
      final product = Product.fromMap({
        'name': 'Keyboard',
        'price': 1200.0,
        'category': 'Accessories',
        'description': 'Mechanical keyboard',
        'imageUrl': 'keyboard.png',
        'stock': 5,
      }, 'product001');

      expect(product.id, 'product001');
      expect(product.name, 'Keyboard');
      expect(product.price, 1200.0);
      expect(product.category, 'Accessories');
      expect(product.description, 'Mechanical keyboard');
      expect(product.imageUrl, 'keyboard.png');
      expect(product.stock, 5);
    });

    // 3
    test('03 - Product.fromMap converts integer price to double', () {
      final product = Product.fromMap({
        'name': 'Mouse',
        'price': 500,
        'stock': 3,
      }, 'product002');

      expect(product.price, 500.0);
      expect(product.price, isA<double>());
    });

    // 4
    test('04 - Product.fromMap uses defaults for missing fields', () {
      final product = Product.fromMap({}, 'product003');

      expect(product.id, 'product003');
      expect(product.name, '');
      expect(product.price, 0.0);
      expect(product.category, '');
      expect(product.description, '');
      expect(product.imageUrl, '');
      expect(product.stock, 0);
    });

    // 5
    test('05 - Product.fromMap converts text fields to strings', () {
      final product = Product.fromMap({
        'name': 123,
        'category': 456,
        'description': 789,
        'imageUrl': 111,
      }, 'product004');

      expect(product.name, '123');
      expect(product.category, '456');
      expect(product.description, '789');
      expect(product.imageUrl, '111');
    });

    // 6
    test('06 - Product.toMap returns product fields', () {
      final product = createTestProduct();
      final map = product.toMap();

      expect(map['name'], 'Gaming Mouse');
      expect(map['price'], 500.0);
      expect(map['category'], 'Accessories');
      expect(map['description'], 'Test product description');
      expect(map['imageUrl'], 'https://example.com/product.png');
      expect(map['stock'], 10);
      expect(map.containsKey('id'), isFalse);
    });
  });

  group('Cart Model Tests', () {
    final cart = CartModel.instance;

    setUp(() {
      cart.clearCart();
    });

    // 7
    test('07 - CartItem calculates subtotal correctly', () {
      final product = createTestProduct(price: 200.0);
      final item = CartItem(product: product, quantity: 3);

      expect(item.subtotal, 600.0);
    });

    // 8
    test('08 - Adding a product creates a cart item', () {
      final product = createTestProduct();

      cart.addProduct(product);

      expect(cart.items.length, 1);
      expect(cart.items.first.product.id, 'p1');
      expect(cart.items.first.quantity, 1);
    });

    // 9
    test('09 - Adding the same product increases quantity', () {
      final product = createTestProduct();

      cart.addProduct(product);
      cart.addProduct(product);

      expect(cart.items.length, 1);
      expect(cart.items.first.quantity, 2);
      expect(cart.totalQuantity, 2);
    });

    // 10
    test('10 - Cart totalQuantity sums item quantities', () {
      cart.addProduct(createTestProduct(id: 'p1'));
      cart.addProduct(createTestProduct(id: 'p2'));
      cart.addProduct(createTestProduct(id: 'p1'));

      expect(cart.totalQuantity, 3);
    });

    // 11
    test('11 - Cart totalPrice calculates the total correctly', () {
      cart.addProduct(createTestProduct(id: 'p1', price: 100.0));
      cart.addProduct(createTestProduct(id: 'p2', price: 250.0));
      cart.addProduct(createTestProduct(id: 'p1', price: 100.0));

      expect(cart.totalPrice, 450.0);
    });

    // 12
    test('12 - Increasing quantity updates the cart', () {
      final product = createTestProduct();

      cart.addProduct(product);
      cart.increaseQuantity(product);

      expect(cart.items.first.quantity, 2);
      expect(cart.totalQuantity, 2);
    });

    // 13
    test('13 - Decreasing quantity reduces quantity when above one', () {
      final product = createTestProduct();

      cart.addProduct(product);
      cart.addProduct(product);
      cart.decreaseQuantity(product);

      expect(cart.items.length, 1);
      expect(cart.items.first.quantity, 1);
    });

    // 14
    test('14 - Decreasing quantity from one removes the item', () {
      final product = createTestProduct();

      cart.addProduct(product);
      cart.decreaseQuantity(product);

      expect(cart.items, isEmpty);
      expect(cart.totalQuantity, 0);
    });

    // 15
    test('15 - Removing a product removes only the matching item', () {
      final first = createTestProduct(id: 'p1');
      final second = createTestProduct(id: 'p2');

      cart.addProduct(first);
      cart.addProduct(second);
      cart.removeProduct(first);

      expect(cart.items.length, 1);
      expect(cart.items.first.product.id, 'p2');
    });

    // 16
    test('16 - Clearing cart removes all items and totals', () {
      cart.addProduct(createTestProduct(id: 'p1'));
      cart.addProduct(createTestProduct(id: 'p2'));

      cart.clearCart();

      expect(cart.items, isEmpty);
      expect(cart.totalQuantity, 0);
      expect(cart.totalPrice, 0.0);
    });

    // 17
    test('17 - Increasing quantity of a product not in cart does nothing', () {
      cart.increaseQuantity(createTestProduct(id: 'missing'));

      expect(cart.items, isEmpty);
      expect(cart.totalQuantity, 0);
    });
  });
}
