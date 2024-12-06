import 'package:flutter/foundation.dart';
import 'models/product.dart';
import 'models/coupon.dart';
import 'models/voucher.dart';
import 'models/settings.dart';
import '../services/product_service.dart';
import '../services/voucher_service.dart';

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
  double _tipPercentage = 0;
  final Set<Coupon> _coupons = {};
  final Set<Voucher> _vouchers = {};
  final SettingsState _settings = SettingsState();

  List<CartItem> get items => _items;
  Set<Coupon> get coupons => _coupons;
  Set<Voucher> get vouchers => _vouchers;
  double get tipPercentage => _tipPercentage;

  double get subtotal {
    if (_settings.settings.taxInclusive) {
      // If tax inclusive, subtotal is price with tax removed for taxable items
      return _items.fold(0, (sum, item) {
        final taxRate = _settings.settings.taxRate / 100;
        if (!item.product.taxExempt) {
          // Remove tax from price for taxable items
          return sum + ((item.product.price / (1 + taxRate)) * item.quantity);
        }
        return sum + (item.product.price * item.quantity);
      });
    }
    // If tax exclusive, subtotal is just sum of prices
    return _items.fold(
        0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  double get hst {
    final taxRate = _settings.settings.taxRate / 100;
    return _items.fold(0, (sum, item) {
      if (item.product.taxExempt) {
        // No tax for tax-exempt items
        return sum;
      }
      
      if (_settings.settings.taxInclusive) {
        // For tax-inclusive items, extract tax from price
        return sum +
            (item.product.price - (item.product.price / (1 + taxRate))) *
                item.quantity;
      } else {
        // For tax-exclusive items, calculate tax on price
        return sum + (item.product.price * taxRate * item.quantity);
      }
    });
  }

  double get couponDiscount {
    return _coupons.fold(
        0, (sum, coupon) => sum + coupon.calculateDiscount(subtotal));
  }

  double get voucherDiscount {
    return _vouchers.fold(0, (sum, voucher) {
      if (voucher.isPercentage) {
        return sum + (subtotal * (voucher.value / 100));
      }
      return sum + voucher.value;
    });
  }

  double get totalDiscount => couponDiscount + voucherDiscount;

  double get tipAmount => (subtotal - totalDiscount) * (_tipPercentage / 100);

  double get total {
    final subtotalAmount = subtotal;
    final discountAmount = totalDiscount;
    final tipAmount =
        (subtotalAmount - discountAmount) * (_tipPercentage / 100);
    return subtotalAmount - discountAmount + tipAmount + hst;
  }

  void addItem(Product product, {int quantity = 1}) {
    final existingIndex =
        _items.indexWhere((item) => item.product.id == product.id);
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

  void updateQuantity(int index, int quantity) {
    if (index >= 0 && index < _items.length && quantity > 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void setTipPercentage(double percentage) {
    _tipPercentage = percentage;
    notifyListeners();
  }

  // Calculate the total after applying a new coupon
  double _calculateTotalWithNewCoupon(Coupon newCoupon) {
    final newCouponDiscount = newCoupon.calculateDiscount(subtotal);
    final currentDiscountWithoutCoupons = voucherDiscount;
    final tipAmount =
        (subtotal - (currentDiscountWithoutCoupons + newCouponDiscount)) *
            (_tipPercentage / 100);
    return subtotal -
        (currentDiscountWithoutCoupons + newCouponDiscount) +
        tipAmount +
        hst;
  }

  // Calculate the total after applying a new voucher
  double _calculateTotalWithNewVoucher(Voucher newVoucher) {
    final newVoucherDiscount = newVoucher.isPercentage
        ? subtotal * (newVoucher.value / 100)
        : newVoucher.value;
    final currentDiscountWithoutVouchers = couponDiscount;
    final tipAmount =
        (subtotal - (currentDiscountWithoutVouchers + newVoucherDiscount)) *
            (_tipPercentage / 100);
    return subtotal -
        (currentDiscountWithoutVouchers + newVoucherDiscount) +
        tipAmount +
        hst;
  }

  // Add coupon only if it won't result in negative total
  bool addCoupon(Coupon coupon) {
    final newTotal = _calculateTotalWithNewCoupon(coupon);
    if (newTotal <= 0) {
      return false;
    }
    _coupons.add(coupon);
    notifyListeners();
    return true;
  }

  // Add voucher only if it won't result in negative total
  bool addVoucher(Voucher voucher) {
    final newTotal = _calculateTotalWithNewVoucher(voucher);
    if (newTotal <= 0) {
      return false;
    }
    _vouchers.add(voucher);
    notifyListeners();
    return true;
  }

  void removeCoupon(Coupon coupon) {
    _coupons.remove(coupon);
    notifyListeners();
  }

  void clearCoupons() {
    _coupons.clear();
    notifyListeners();
  }

  void removeVoucher(Voucher voucher) {
    _vouchers.remove(voucher);
    notifyListeners();
  }

  void clearVouchers() {
    _vouchers.clear();
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
  List<String> get categories =>
      _products.map((p) => p.category).toSet().toList();

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

class SettingsState extends ChangeNotifier {
  Settings _settings = Settings();

  Settings get settings => _settings;

  void updateSettings({
    String? currencySymbol,
    String? currencyCode,
    double? taxRate,
    bool? taxInclusive,
    String? taxName,
  }) {
    _settings = _settings.copyWith(
      currencySymbol: currencySymbol,
      currencyCode: currencyCode,
      taxRate: taxRate,
      taxInclusive: taxInclusive,
      taxName: taxName,
    );
    notifyListeners();
  }

  String formatCurrency(double amount) {
    return '${_settings.currencySymbol}${amount.toStringAsFixed(2)}';
  }
}
