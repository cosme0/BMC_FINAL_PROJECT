class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int stock;
  final String category;
  final List<String> features;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.stock,
    required this.category,
    this.features = const [],
  });

  factory Product.fromMap(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      price: (data['price'] as num? ?? 0).toDouble(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      stock: (data['stock'] as num? ?? 0).toInt(),
      category: (data['category'] ?? 'General').toString(),
      features:
          (data['features'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'price': price,
    'imageUrl': imageUrl,
    'stock': stock,
    'category': category,
    'features': features,
  };
}
