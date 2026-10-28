class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String description;
  final String imageUrl;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.stock,
  });

  factory Product.fromMap(Map<String, dynamic> data, String documentId) {
    return Product(
      id: documentId,
      name: data['name']?.toString() ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      category: data['category']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      stock: (data['stock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'stock': stock,
    };
  }
}
