import 'dart:async';
import '../core/models/product.dart';

class ProductService {
  // Simulate API delay
  static const _delay = Duration(milliseconds: 800);

  // Mock product data
  static final List<Map<String, dynamic>> _mockProducts = [
    {
      'id': '1',
      'name': 'Coffee',
      'price': 3.50,
      'category': 'Beverages',
      'imageUrl': 'https://picsum.photos/seed/coffee/200',
      'description': 'Fresh brewed coffee',
      'isAvailable': true,
      'stockQuantity': 100
    },
    {
      'id': '2',
      'name': 'Tea',
      'price': 2.50,
      'category': 'Beverages',
      'imageUrl': 'https://picsum.photos/seed/tea/200',
      'description': 'Aromatic tea',
      'isAvailable': true,
      'stockQuantity': 150
    },
    {
      'id': '3',
      'name': 'Burger',
      'price': 8.99,
      'category': 'Food',
      'imageUrl': 'https://picsum.photos/seed/burger/200',
      'description': 'Juicy beef burger',
      'isAvailable': true,
      'stockQuantity': 50
    },
    {
      'id': '4',
      'name': 'Pizza',
      'price': 12.99,
      'category': 'Food',
      'imageUrl': 'https://picsum.photos/seed/pizza/200',
      'description': 'Fresh baked pizza',
      'isAvailable': true,
      'stockQuantity': 30
    },
    {
      'id': '5',
      'name': 'Salad',
      'price': 7.99,
      'category': 'Food',
      'imageUrl': 'https://picsum.photos/seed/salad/200',
      'description': 'Fresh garden salad',
      'isAvailable': true,
      'stockQuantity': 40
    },
    {
      'id': '6',
      'name': 'Ice Cream',
      'price': 4.50,
      'category': 'Desserts',
      'imageUrl': 'https://picsum.photos/seed/icecream/200',
      'description': 'Vanilla ice cream',
      'isAvailable': true,
      'stockQuantity': 80
    },
  ];

  // Simulate fetching products from API
  Future<List<Product>> getProducts() async {
    await Future.delayed(_delay);
    return _mockProducts.map((json) => Product.fromJson(json)).toList();
  }

  // Simulate fetching products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    await Future.delayed(_delay);
    return _mockProducts
        .where((product) => product['category'] == category)
        .map((json) => Product.fromJson(json))
        .toList();
  }

  // Simulate searching products
  Future<List<Product>> searchProducts(String query) async {
    await Future.delayed(_delay);
    final lowercaseQuery = query.toLowerCase();
    return _mockProducts
        .where((product) =>
            product['name'].toString().toLowerCase().contains(lowercaseQuery) ||
            product['description'].toString().toLowerCase().contains(lowercaseQuery))
        .map((json) => Product.fromJson(json))
        .toList();
  }

  // Simulate getting product by ID
  Future<Product?> getProductById(String id) async {
    await Future.delayed(_delay);
    final productJson = _mockProducts.firstWhere(
      (product) => product['id'] == id,
      orElse: () => {},
    );
    return productJson.isEmpty ? null : Product.fromJson(productJson);
  }
}
