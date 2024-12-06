import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/models/product.dart';

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
  Timer? _timer;
  String _currentTime = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebouncer;
  String _quantityInput = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
    
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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchDebouncer?.cancel();
    _categoryScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
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

  Future<bool> _onWillPop(BuildContext context, CartState cartState, OpenOrdersState openOrdersState) async {
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
          title: Text(widget.existingOrder != null ? 'Update Order' : 'Save Order'),
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
            if (widget.existingOrder == null) // Only show discard for new orders
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

  @override
  Widget build(BuildContext context) {
    final cartState = Provider.of<CartState>(context);
    final openOrdersState = Provider.of<OpenOrdersState>(context);
    final productState = Provider.of<ProductState>(context);
    
    return WillPopScope(
      onWillPop: () => _onWillPop(context, cartState, openOrdersState),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop(context, cartState, openOrdersState);
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
                              backgroundColor: productState.selectedCategory == null ? Colors.deepOrange : Colors.white,
                              foregroundColor: productState.selectedCategory == null ? Colors.white : Colors.deepOrange,
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
                              final isSelected = category == productState.selectedCategory;
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected ? Colors.deepOrange : Colors.white,
                                    foregroundColor: isSelected ? Colors.white : Colors.deepOrange,
                                    minimumSize: const Size(120, 40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onPressed: () => productState.setCategory(isSelected ? null : category),
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
                    child: productState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                        ),
                      )
                    : productState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              productState.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => productState.loadProducts(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                      builder: (context, constraints) {
                        final bool showImages = constraints.maxWidth > 800 && constraints.maxHeight > 600;
                        
                        // Calculate number of columns based on minimum width
                        final double minProductWidth = 240.0; // Minimum width for each product box
                        final int crossAxisCount = (constraints.maxWidth / minProductWidth).floor();
                        
                        return GridView.builder(
                          padding: const EdgeInsets.all(8.0),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: max(1, crossAxisCount), // Ensure at least 1 column
                            childAspectRatio: 2.0,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: productState.filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = productState.filteredProducts[index];
                            
                            return Card(
                              elevation: 2,
                              child: InkWell(
                                onTap: product.isAvailable
                                  ? () {
                                      cartState.addItem(product, quantity: selectedQuantity);
                                      // Reset quantity after adding to cart
                                      setState(() {
                                        _quantityInput = '';
                                      });
                                    }
                                  : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      if (showImages)
                                        Container(
                                          width: 60,
                                          height: 60,
                                          margin: const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              product.imageUrl ?? 'https://picsum.photos/seed/${product.name.hashCode}/200',
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded / 
                                                            loadingProgress.expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Center(
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey,
                                                    size: 24,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              product.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (product.description != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                product.description!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            const SizedBox(height: 4),
                                            Text(
                                              '\$${product.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Cart section (right side)
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
                              Text('${item.quantity} × \$${item.product.price.toStringAsFixed(2)}'),
                              if (item.product.includesHst)
                                const Text(' (HST included)', 
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => cartState.decreaseQuantity(index),
                                iconSize: 20,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => cartState.removeItem(index),
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
                            Text('\$${cartState.subtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('HST (13%):'),
                            Text('\$${cartState.hst.toStringAsFixed(2)}'),
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
                              '\$${cartState.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Quantity input display
                        Container(
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
                        const SizedBox(height: 16),
                        // Numeric keypad
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
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onPressed: cartState.items.isEmpty ? null : cartState.clearCart,
                                child: const Text('Clear Cart'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onPressed: cartState.items.isEmpty
                                    ? null
                                    : () {
                                        // Place order logic
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
