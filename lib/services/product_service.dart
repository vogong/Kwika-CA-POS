import 'dart:async';
import '../core/models/product.dart';

class ProductService {
  // Simulate API delay
  static const _delay = Duration(milliseconds: 800);

  // Mock product data
  static final List<Product> _mockProducts = [
    Product(
      id: 'P001',
      name: 'Coffee',
      description: 'Fresh brewed coffee',
      price: 2.50,
      imageUrl: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400&auto=format&fit=crop&q=80',
      category: 'Beverages',
      includesTax: true,
      isActive: true,
    ),
    Product(
      id: 'P002',
      name: 'Tea',
      description: 'Hot tea',
      price: 2.00,
      imageUrl: 'https://images.unsplash.com/photo-1597481499750-3e6b22637e12?w=400&auto=format&fit=crop&q=80',
      category: 'Beverages',
      includesTax: true,
      isActive: true,
    ),
    Product(
      id: 'P003',
      name: 'Muffin',
      description: 'Freshly baked muffin',
      price: 3.00,
      imageUrl: 'https://images.unsplash.com/photo-1607958996333-41783d86c8fe?w=400&auto=format&fit=crop&q=80',
      category: 'Pastries',
      includesTax: false,
      isActive: true,
    ),
    Product(
      id: 'P004',
      name: 'Sandwich',
      description: 'Fresh sandwich',
      price: 6.50,
      imageUrl: 'https://images.unsplash.com/photo-1553909489-cd47e0907980?w=400&auto=format&fit=crop&q=80',
      category: 'Food',
      includesTax: false,
      isActive: true,
    ),
    Product(
      id: 'P005',
      name: 'Burger',
      description: 'Juicy beef burger',
      price: 8.99,
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&auto=format&fit=crop&q=80',
      category: 'Food',
      includesTax: false,
      isActive: true,
    ),
    Product(
      id: 'P006',
      name: 'Pizza',
      description: 'Fresh baked pizza',
      price: 12.99,
      imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&auto=format&fit=crop&q=80',
      category: 'Food',
      includesTax: false,
      isActive: true,
    ),
    Product(
      id: 'P007',
      name: 'Salad',
      description: 'Fresh garden salad',
      price: 7.99,
      imageUrl: 'https://images.unsplash.com/photo-1567620905732-2c8b371f0364?w=400&auto=format&fit=crop&q=80',
      category: 'Food',
      includesTax: false,
      isActive: true,
    ),
    Product(
      id: 'P008',
      name: 'Ice Cream',
      description: 'Vanilla ice cream',
      price: 4.50,
      imageUrl: 'https://images.unsplash.com/photo-1578985245748-06f0b27b7e72?w=400&auto=format&fit=crop&q=80',
      category: 'Desserts',
      includesTax: false,
      isActive: true,
    ),
  ];

  // Simulate fetching products from API
  Future<List<Product>> getProducts() async {
    await Future.delayed(_delay);
    return _mockProducts.where((product) => product.isActive).toList();
  }

  // Simulate fetching products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    await Future.delayed(_delay);
    return _mockProducts
        .where((product) => product.category == category && product.isActive)
        .toList();
  }

  // Simulate searching products
  Future<List<Product>> searchProducts(String query) async {
    final lowercaseQuery = query.toLowerCase();
    return _mockProducts
        .where((product) =>
            product.isActive &&
            (product.name.toLowerCase().contains(lowercaseQuery) ||
            product.description.toLowerCase().contains(lowercaseQuery)))
        .toList();
  }

  // Simulate getting product by ID
  Future<Product?> getProductById(String id) async {
    await Future.delayed(_delay);
    try {
      return _mockProducts.firstWhere(
        (product) => product.id == id,
      );
    } catch (e) {
      return null;
    }
  }
}
