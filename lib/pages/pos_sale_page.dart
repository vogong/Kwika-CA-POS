import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/models/product.dart';
import '../core/models/voucher.dart';
import '../services/voucher_service.dart';
import 'order_finalize_page.dart';

class POSSalePage extends StatefulWidget {
  final OpenOrder? existingOrder;
  final int? orderIndex;

  const POSSalePage({
    super.key,
    this.existingOrder,
    this.orderIndex,
  });

  @override
  State<POSSalePage> createState() => _POSSalePageState();
}

class _POSSalePageState extends State<POSSalePage> {
  final ScrollController _categoryScrollController = ScrollController();
  final ScrollController _voucherScrollController = ScrollController();
  Timer? _timer;
  String _currentTime = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebouncer;
  String _quantityInput = '';
  final VoucherService _voucherService = VoucherService();
  List<Voucher> _vouchers = [];
  bool _isQuantityFocused = false;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());

    // Load products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productState = Provider.of<ProductState>(context, listen: false);
      productState.loadProducts();
    });

    // Populate cart if editing existing order
    if (widget.existingOrder != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cartState = Provider.of<CartState>(context, listen: false);
        cartState.clearCart(); // Clear existing items first
        for (var item in widget.existingOrder!.items) {
          cartState.addItem(item.product, quantity: item.quantity);
        }
      });
    }

    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    try {
      final vouchers = await _voucherService.getVouchers();
      setState(() {
        _vouchers = vouchers;
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchDebouncer?.cancel();
    _categoryScrollController.dispose();
    _voucherScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  void _handleSearch(String query, ProductState productState) {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
      productState.searchProducts(query);
    });
  }

  void _handleKeypadInput(String key) {
    setState(() {
      if (key == 'C') {
        _quantityInput = '';
        _isQuantityFocused = false;
      } else if (key == '.') {
        // Ignore decimal point for quantity
        return;
      } else {
        _quantityInput += key;
      }
    });
  }

  int get selectedQuantity {
    if (_quantityInput.isEmpty) return 1;
    return int.tryParse(_quantityInput) ?? 1;
  }

  Widget _buildKeypadButton(String text, {bool isWide = false}) {
    return SizedBox(
      width: isWide ? 130 : 60,
      height: 60,
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => _handleKeypadInput(text),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: text == 'C' ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop(BuildContext context, CartState cartState,
      OpenOrdersState openOrdersState) async {
    if (cartState.items.isEmpty) {
      return true;
    }

    final TextEditingController nameController = TextEditingController(
      text: widget.existingOrder?.name ?? '',
    );

    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              widget.existingOrder != null ? 'Update Order' : 'Save Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter a name for this order:'),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Order name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a name for the order'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final newOrder = OpenOrder(
                  name: nameController.text.trim(),
                  items: List.from(cartState.items),
                  total: cartState.total,
                );

                if (widget.existingOrder != null && widget.orderIndex != null) {
                  // Update existing order
                  openOrdersState.updateOrder(widget.orderIndex!, newOrder);
                } else {
                  // Add new order
                  openOrdersState.addOrder(newOrder);
                }

                cartState.clearCart();
                Navigator.of(context).pop(true);
              },
              child: Text(widget.existingOrder != null ? 'Update' : 'Save'),
            ),
            if (widget.existingOrder ==
                null) // Only show discard for new orders
              TextButton(
                onPressed: () {
                  cartState.clearCart();
                  Navigator.of(context).pop(true);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Discard'),
              ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Widget _buildVoucherCard(Voucher voucher, CartState cartState) {
    final isSelected = cartState.vouchers.contains(voucher);

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue[50] : null,
      child: InkWell(
        onTap: () {
          if (isSelected) {
            cartState.removeVoucher(voucher);
          } else {
            final added = cartState.addVoucher(voucher);
            if (!added) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Cannot apply voucher: Total would be negative'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.card_giftcard,
                      color: isSelected ? Colors.blue : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      voucher.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                voucher.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityInput() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isQuantityFocused = true;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Quantity',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selectedQuantity.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = Provider.of<CartState>(context);
    final openOrdersState = Provider.of<OpenOrdersState>(context);
    final productState = Provider.of<ProductState>(context);
    final settingsState = Provider.of<SettingsState>(context);

    return WillPopScope(
      onWillPop: () => _onWillPop(context, cartState, openOrdersState),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop =
                  await _onWillPop(context, cartState, openOrdersState);
              if (shouldPop) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Row(
            children: [
              const Text('POS Sale'),
              const SizedBox(width: 20),
              Text(
                _currentTime,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.deepOrange,
          actions: [
            // Search Box
            Container(
              width: 300,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  filled: true,
                  fillColor: Colors.deepOrange[400],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                onChanged: (value) => _handleSearch(value, productState),
              ),
            ),
          ],
        ),
        body: Row(
          children: [
            // Product selection area with horizontal category bar
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  // Horizontal category bar with arrows
                  Container(
                    height: 60,
                    color: Colors.orange[100],
                    child: Row(
                      children: [
                        // Static "All" category button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  productState.selectedCategory == null
                                      ? Colors.deepOrange
                                      : Colors.white,
                              foregroundColor:
                                  productState.selectedCategory == null
                                      ? Colors.white
                                      : Colors.deepOrange,
                              minimumSize: const Size(100, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () => productState.setCategory(null),
                            child: const Text(
                              'All',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        // Divider
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.deepOrange.withOpacity(0.2),
                        ),
                        // Left arrow
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: () {
                            _categoryScrollController.animateTo(
                              _categoryScrollController.offset - 200,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                        // Scrollable categories
                        Expanded(
                          child: ListView.builder(
                            controller: _categoryScrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: productState.categories.length,
                            itemBuilder: (context, index) {
                              final category = productState.categories[index];
                              final isSelected =
                                  category == productState.selectedCategory;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0, vertical: 8.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected
                                        ? Colors.deepOrange
                                        : Colors.white,
                                    foregroundColor: isSelected
                                        ? Colors.white
                                        : Colors.deepOrange,
                                    minimumSize: const Size(120, 40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onPressed: () => productState.setCategory(
                                      isSelected ? null : category),
                                  child: Text(
                                    category,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Right arrow
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          onPressed: () {
                            _categoryScrollController.animateTo(
                              _categoryScrollController.offset + 200,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Product boxes
                  Expanded(
                    child: Column(
                      children: [
                        // Products grid
                        Expanded(
                          child: productState.isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    return GridView.builder(
                                      padding: const EdgeInsets.all(8.0),
                                      gridDelegate:
                                          const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 300,
                                        childAspectRatio: 2.5,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),
                                      itemCount:
                                          productState.filteredProducts.length,
                                      itemBuilder: (context, index) {
                                        final product = productState
                                            .filteredProducts[index];

                                        return Opacity(
                                          opacity: product.isActive ? 1.0 : 0.5,
                                          child: Card(
                                            child: InkWell(
                                              onTap: product.isActive
                                                  ? () {
                                                      cartState.addItem(product,
                                                          quantity:
                                                              selectedQuantity);
                                                      setState(() {
                                                        _quantityInput = '';
                                                        _isQuantityFocused =
                                                            false;
                                                      });
                                                    }
                                                  : null,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(12.0),
                                                child: Stack(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: 60,
                                                          height: 60,
                                                          margin:
                                                              const EdgeInsets.only(
                                                                  right: 12),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey[200],
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(8),
                                                          ),
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(8),
                                                            child: Image.network(
                                                              product.imageUrl ??
                                                                  'https://picsum.photos/seed/${product.name.hashCode}/200',
                                                              fit: BoxFit.cover,
                                                              loadingBuilder: (context,
                                                                  child,
                                                                  loadingProgress) {
                                                                if (loadingProgress ==
                                                                    null)
                                                                  return child;
                                                                return Center(
                                                                  child: SizedBox(
                                                                    width: 20,
                                                                    height: 20,
                                                                    child:
                                                                        CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2,
                                                                      value: loadingProgress
                                                                              .expectedTotalBytes !=
                                                                          null
                                                                      ? loadingProgress
                                                                              .cumulativeBytesLoaded /
                                                                          loadingProgress
                                                                              .expectedTotalBytes!
                                                                      : null,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                              errorBuilder:
                                                                  (context, error,
                                                                      stackTrace) {
                                                                return const Center(
                                                                  child: Icon(
                                                                    Icons
                                                                        .image_not_supported,
                                                                    color:
                                                                        Colors.grey,
                                                                    size: 24,
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                product.name,
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              if (product
                                                                      .description !=
                                                                  null) ...[
                                                                const SizedBox(
                                                                    height: 4),
                                                                Text(
                                                                  product
                                                                      .description!,
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    color: Colors
                                                                        .grey[600],
                                                                  ),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ],
                                                              const SizedBox(
                                                                  height: 4),
                                                              Text(
                                                                settingsState
                                                                    .formatCurrency(
                                                                        product
                                                                            .price),
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 14,
                                                                  color:
                                                                      Colors.green,
                                                                ),
                                                              ),
                                                              if (!product.isActive)
                                                                Positioned(
                                                                  top: 4,
                                                                  right: 4,
                                                                  child: Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .symmetric(
                                                                      horizontal: 8,
                                                                      vertical: 4,
                                                                    ),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Colors
                                                                          .red,
                                                                      borderRadius:
                                                                          BorderRadius
                                                                              .circular(
                                                                                  12),
                                                                    ),
                                                                    child:
                                                                        const Text(
                                                                      'Unavailable',
                                                                      style:
                                                                          TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (product.taxExempt)
                                                      Positioned(
                                                        top: 0,
                                                        right: 0,
                                                        child: Container(
                                                          padding: const EdgeInsets.all(4),
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            color: Colors.red,
                                                          ),
                                                          child: const Text(
                                                            'TAX',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                        // Vouchers bar at bottom of products
                        if (cartState.items.isNotEmpty)
                          Container(
                            height: 120,
                            margin: const EdgeInsets.only(bottom: 16.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              border: Border(
                                top: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Background label
                                Center(
                                  child: Text(
                                    'Available Vouchers',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[200],
                                    ),
                                  ),
                                ),
                                // Voucher list with scroll buttons
                                Row(
                                  children: [
                                    // Left scroll button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          final currentPos =
                                              _voucherScrollController.offset;
                                          _voucherScrollController.animateTo(
                                            currentPos - 160,
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        child: SizedBox(
                                          width: 40,
                                          child: Center(
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                  Icons.chevron_left,
                                                  size: 24),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Voucher list
                                    Expanded(
                                      child: ListView.builder(
                                        controller: _voucherScrollController,
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        itemCount: _vouchers.length,
                                        itemBuilder: (context, index) {
                                          final voucher = _vouchers[index];
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4.0, vertical: 4.0),
                                            child: SizedBox(
                                              width: 160,
                                              child: _buildVoucherCard(
                                                  voucher, cartState),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    // Right scroll button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          final currentPos =
                                              _voucherScrollController.offset;
                                          _voucherScrollController.animateTo(
                                            currentPos + 160,
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        child: SizedBox(
                                          width: 40,
                                          child: Center(
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                  Icons.chevron_right,
                                                  size: 24),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Cart section
            Container(
              width: 300,
              color: Colors.grey[300],
              child: Column(
                children: [
                  // Cart items list
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartState.items.length,
                      itemBuilder: (context, index) {
                        final item = cartState.items[index];
                        return ListTile(
                          dense: true,
                          title: Text(item.product.name),
                          subtitle: Row(
                            children: [
                              Text(
                                  '${item.quantity} × ${settingsState.formatCurrency(item.product.price)}'),
                              if (settingsState.settings.taxInclusive)
                                Text(
                                  ' (${settingsState.settings.taxName} included)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                settingsState.formatCurrency(
                                    item.product.price * item.quantity),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  cartState.decreaseQuantity(index);
                                  setState(() {
                                    _isQuantityFocused = false;
                                  });
                                },
                                iconSize: 20,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () {
                                  cartState.removeItem(index);
                                  setState(() {
                                    _isQuantityFocused = false;
                                  });
                                },
                                iconSize: 20,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Total and Place Order section
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:'),
                            Text(settingsState
                                .formatCurrency(cartState.subtotal)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '${settingsState.settings.taxName} (${settingsState.settings.taxRate}%):'),
                            Text(settingsState.formatCurrency(cartState.hst)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              settingsState.formatCurrency(cartState.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Quantity input display
                        _buildQuantityInput(),
                        const SizedBox(height: 16),
                        // Numeric keypad
                        if (_isQuantityFocused)
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildKeypadButton('7'),
                                  const SizedBox(width: 8),
                                  _buildKeypadButton('8'),
                                  const SizedBox(width: 8),
                                  _buildKeypadButton('9'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildKeypadButton('4'),
                                  const SizedBox(width: 8),
                                  _buildKeypadButton('5'),
                                  const SizedBox(width: 8),
                                  _buildKeypadButton('6'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildKeypadButton('1'),
                                  const SizedBox(width: 8),
                                  _buildKeypadButton('2'),
                                  const SizedBox(width: 8),
                                  _buildKeypadButton('3'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildKeypadButton('.'),
                                  const SizedBox(width: 8),
                                  _buildKeypadButton('0'),
                                  const SizedBox(width: 8),
                                  _buildKeypadButton('C'),
                                ],
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onPressed: cartState.items.isEmpty
                                    ? null
                                    : cartState.clearCart,
                                child: const Text('Clear Cart'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onPressed: cartState.items.isEmpty
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const OrderFinalizePage(),
                                          ),
                                        );
                                      },
                                child: const Text('Place Order'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
