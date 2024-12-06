class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String? imageUrl;
  final String? description;
  final bool isAvailable;
  final int stockQuantity;
  final bool includesHst;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.imageUrl,
    this.description,
    this.isAvailable = true,
    this.stockQuantity = 0,
    this.includesHst = false,
  });

  static const double hstRate = 0.13;

  double get hstAmount => price * hstRate;
  double get totalWithHst => price + hstAmount;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: ((json['price'] ?? 0) as num).toDouble(),
      category: json['category'] ?? '',
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      stockQuantity: json['stockQuantity'] as int? ?? 0,
      includesHst: json['includesHst'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'description': description,
      'isAvailable': isAvailable,
      'stockQuantity': stockQuantity,
      'includesHst': includesHst,
    };
  }
}
