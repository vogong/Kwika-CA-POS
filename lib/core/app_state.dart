import 'package:flutter/foundation.dart';
import 'models/product.dart';
import '../services/product_service.dart';

class UserState extends ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });
}

class CartState extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get subtotal => _items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  
  double get hst => _items.fold(0, (sum, item) => sum + (item.product.hstAmount * item.quantity));
  
  double get total => subtotal + hst;

  void addItem(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void decreaseQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

class OpenOrder {
  final String name;
  final List<CartItem> items;
  final double total;

  OpenOrder({
    required this.name,
    required this.items,
    required this.total,
  });
}

class OpenOrdersState extends ChangeNotifier {
  final List<OpenOrder> _orders = [];

  List<OpenOrder> get orders => _orders;

  void addOrder(OpenOrder order) {
    _orders.add(order);
    notifyListeners();
  }

  void removeOrder(int index) {
    _orders.removeAt(index);
    notifyListeners();
  }

  void updateOrder(int index, OpenOrder newOrder) {
    _orders[index] = newOrder;
    notifyListeners();
  }
}

class ProductState extends ChangeNotifier {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Product> get products => _products;
  List<Product> get filteredProducts => _filteredProducts;
  String? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get categories => _products
      .map((p) => p.category)
      .toSet()
      .toList();

  // Initialize products
  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _productService.getProducts();
      _updateFilteredProducts();
    } catch (e) {
      _error = 'Failed to load products: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter products by category
  void setCategory(String? category) {
    _selectedCategory = category;
    _updateFilteredProducts();
    notifyListeners();
  }

  // Search products
  Future<void> searchProducts(String query) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (query.isEmpty) {
        _updateFilteredProducts();
      } else {
        _filteredProducts = await _productService.searchProducts(query);
      }
    } catch (e) {
      _error = 'Failed to search products: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update filtered products based on selected category
  void _updateFilteredProducts() {
    if (_selectedCategory == null) {
      _filteredProducts = List.from(_products);
    } else {
      _filteredProducts = _products
          .where((product) => product.category == _selectedCategory)
          .toList();
    }
  }
}
