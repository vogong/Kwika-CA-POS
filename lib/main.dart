import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserState()),
        ChangeNotifierProvider(create: (_) => CartState()),
        ChangeNotifierProvider(create: (_) => OpenOrdersState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kwika POS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: Consumer<UserState>(
        builder: (context, userState, child) {
          if (!userState.isLoggedIn) {
            return const LoginScreen();
          }
          return const MainScreen();
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/images/splash.jpg'),
      ),
    );
  }
}

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
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    this.quantity = 1,
  });
}

class CartState extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get total => _items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  void addItem(String name, double price, {int quantity = 1}) {
    // Check if item already exists
    final existingIndex = _items.indexWhere((item) => item.name == name);
    if (existingIndex != -1) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(name: name, price: price, quantity: quantity));
    }
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void decreaseQuantity(int index) {
    if (_items[index].quantity > 1) {
      _items[index].quantity--;
      notifyListeners();
    } else {
      removeItem(index);
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

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);
    final usernameController = TextEditingController(text: 'testuser');
    final passwordController = TextEditingController(text: 'password123');

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Kwika POS',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    final username = usernameController.text;
                    final password = passwordController.text;
                    if (username == 'testuser' && password == 'password123') {
                      userState.login();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid credentials'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class POSSaleScreen extends StatefulWidget {
  final OpenOrder? existingOrder;
  final int? orderIndex;

  const POSSaleScreen({
    super.key, 
    this.existingOrder,
    this.orderIndex,
  });

  @override
  State<POSSaleScreen> createState() => _POSSaleScreenState();
}

class _POSSaleScreenState extends State<POSSaleScreen> {
  final ScrollController _categoryScrollController = ScrollController();
  Timer? _timer;
  String _currentTime = '';
  String? _selectedCategory;

  // Mock product data with categories
  final List<Map<String, dynamic>> products = [
    {'name': 'Coffee', 'price': 3.50, 'category': 'Beverages'},
    {'name': 'Tea', 'price': 2.50, 'category': 'Beverages'},
    {'name': 'Soda', 'price': 2.00, 'category': 'Beverages'},
    {'name': 'Water', 'price': 1.50, 'category': 'Beverages'},
    {'name': 'Burger', 'price': 8.99, 'category': 'Food'},
    {'name': 'Pizza', 'price': 12.99, 'category': 'Food'},
    {'name': 'Salad', 'price': 7.99, 'category': 'Food'},
    {'name': 'Fries', 'price': 3.99, 'category': 'Sides'},
    {'name': 'Onion Rings', 'price': 4.99, 'category': 'Sides'},
    {'name': 'Coleslaw', 'price': 2.99, 'category': 'Sides'},
    {'name': 'Ice Cream', 'price': 4.50, 'category': 'Desserts'},
    {'name': 'Cake', 'price': 5.99, 'category': 'Desserts'},
    {'name': 'Brownie', 'price': 3.99, 'category': 'Desserts'},
  ];

  // Get unique categories
  List<String> get categories => products
      .map((p) => p['category'] as String)
      .toSet()
      .toList();

  // Get filtered products
  List<Map<String, dynamic>> get filteredProducts => _selectedCategory == null
      ? products
      : products.where((p) => p['category'] == _selectedCategory).toList();

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
    
    // Populate cart if editing existing order
    if (widget.existingOrder != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cartState = Provider.of<CartState>(context, listen: false);
        cartState.clearCart(); // Clear existing items first
        for (var item in widget.existingOrder!.items) {
          cartState.addItem(item.name, item.price, quantity: item.quantity);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
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
                onChanged: (value) {
                  // Implement search functionality
                },
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Implement search functionality
              },
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
                              backgroundColor: _selectedCategory == null ? Colors.deepOrange : Colors.white,
                              foregroundColor: _selectedCategory == null ? Colors.white : Colors.deepOrange,
                              minimumSize: const Size(100, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedCategory = null;
                              });
                            },
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
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final isSelected = category == _selectedCategory;
                              
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
                                  onPressed: () {
                                    setState(() {
                                      _selectedCategory = isSelected ? null : category;
                                    });
                                  },
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
                    child: LayoutBuilder(
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
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final productName = product['name'] as String;
                            final productPrice = product['price'] as double;
                            
                            return Card(
                              elevation: 2,
                              child: InkWell(
                                onTap: () {
                                  cartState.addItem(productName, productPrice);
                                },
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
                                              'https://picsum.photos/seed/${productName.hashCode}/200',
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
                                              productName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '\$${productPrice.toStringAsFixed(2)}',
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
            // Collapsible control box
            Container(
              width: 300,
              color: Colors.grey[300],
              child: Column(
                children: [
                  // Cart Items List
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Consumer<CartState>(
                        builder: (context, cart, child) {
                          return ListView.builder(
                            itemCount: cart.items.length,
                            itemBuilder: (context, index) {
                              final item = cart.items[index];
                              return ListTile(
                                dense: true,
                                title: Text(item.name),
                                subtitle: Text('\$${item.price.toStringAsFixed(2)} x ${item.quantity}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('\$${(item.price * item.quantity).toStringAsFixed(2)}'),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                                      onPressed: () => cart.decreaseQuantity(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () => cart.removeItem(index),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  // Cart total and Place Order section
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Show keypad only if we have enough vertical space (500px)
                        final bool showKeypad = MediaQuery.of(context).size.height > 500;
                        
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Total amount
                            Text(
                              'Total: \$${cartState.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Only show keypad if we have enough space
                            if (showKeypad) ...[
                              Container(
                                width: min(300, constraints.maxWidth * 0.25),
                                padding: const EdgeInsets.all(8.0),
                                margin: const EdgeInsets.only(bottom: 16.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, keypadConstraints) {
                                    final buttonSize = min(80.0, keypadConstraints.maxWidth / 3 - 8);
                                    final fontSize = min(24.0, buttonSize * 0.4);
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildKeypadButton('7', buttonSize, fontSize),
                                            _buildKeypadButton('8', buttonSize, fontSize),
                                            _buildKeypadButton('9', buttonSize, fontSize),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildKeypadButton('4', buttonSize, fontSize),
                                            _buildKeypadButton('5', buttonSize, fontSize),
                                            _buildKeypadButton('6', buttonSize, fontSize),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildKeypadButton('1', buttonSize, fontSize),
                                            _buildKeypadButton('2', buttonSize, fontSize),
                                            _buildKeypadButton('3', buttonSize, fontSize),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildKeypadButton('C', buttonSize, fontSize),
                                            _buildKeypadButton('0', buttonSize, fontSize),
                                            _buildKeypadButton('.', buttonSize, fontSize),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                            
                            // Place order button - always visible
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: cartState.items.isEmpty
                                    ? null
                                    : () {
                                        // Place order logic
                                      },
                                child: const Text(
                                  'Place Order',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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

  Widget _buildKeypadButton(String text, double size, double fontSize) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          // Existing keypad logic
          if (text == 'C') {
            // Clear logic
          } else {
            // Number input logic
          }
        },
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class MainPOSPage extends StatelessWidget {
  const MainPOSPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);
    final openOrdersState = Provider.of<OpenOrdersState>(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: const Text('POS System'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Logic to look up an open order
              },
              child: const Text('Look Up an Open Order'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const POSSaleScreen(),
                  ),
                );
              },
              child: const Text('Open a New Order'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Time: ${DateTime.now().toLocal().toString().split(' ')[1].substring(0, 5)}'),
              Text('User: ${userState.isLoggedIn ? 'testuser' : 'Guest'}'),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);
    final openOrdersState = Provider.of<OpenOrdersState>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kwika POS'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => userState.logout(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Open Orders List
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                right: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.deepOrange[100],
                  child: const Row(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.deepOrange),
                      SizedBox(width: 8),
                      Text(
                        'Open Orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: openOrdersState.orders.length,
                    itemBuilder: (context, index) {
                      final order = openOrdersState.orders[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(
                            order.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${order.items.length} items - \$${order.total.toStringAsFixed(2)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => POSSaleScreen(
                                        existingOrder: order,
                                        orderIndex: index,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Delete Order'),
                                        content: Text(
                                          'Are you sure you want to delete the order "${order.name}"?'
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              openOrdersState.removeOrder(index);
                                              Navigator.of(context).pop();
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart, size: 32),
                label: const Text(
                  'New Sale',
                  style: TextStyle(fontSize: 24),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 24,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const POSSaleScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
