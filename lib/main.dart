import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'core/app_state.dart';
import 'pages/login_page.dart';
import 'pages/splash_page.dart';
import 'pages/pos_sale_page.dart';
import 'pages/settings_page.dart';
import 'services/nfc_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserState()),
        ChangeNotifierProvider(create: (_) => SettingsState()),
        ChangeNotifierProxyProvider<SettingsState, CartState>(
          create: (context) => CartState(context.read<SettingsState>()),
          update: (context, settings, cart) => cart ?? CartState(settings),
        ),
        ChangeNotifierProvider(create: (_) => OpenOrdersState()),
        ChangeNotifierProvider(create: (_) => ProductState()),
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
            return const LoginPage();
          }
          return const MainScreen();
        },
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
                    builder: (context) => const POSSalePage(),
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
              Text(
                  'Time: ${DateTime.now().toLocal().toString().split(' ')[1].substring(0, 5)}'),
              Text('User: ${userState.isLoggedIn ? 'testuser' : 'Guest'}'),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  StreamSubscription<String>? _nfcSubscription;

  @override
  void initState() {
    super.initState();
    _startNFCScanning();
  }

  @override
  void dispose() {
    _nfcSubscription?.cancel();
    NFCService.dispose();
    super.dispose();
  }

  Future<void> _startNFCScanning() async {
    try {
      // Subscribe to NFC tag detections
      _nfcSubscription = NFCService.tagStream.listen((String tagId) {
        if (mounted) {
          // Navigate to POS sale page with the NFC tag ID
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => POSSalePage(),
            ),
          );
        }
      });

      // Start continuous scanning
      await NFCService.startContinuousScanning();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('NFC Error'),
              content: Text(e.toString()),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);
    final openOrdersState = Provider.of<OpenOrdersState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kwika POS'),
        backgroundColor: Colors.deepOrange,
        actions: [
          if (userState.isLoggedIn) ...[
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                userState.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
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
                                      builder: (context) => POSSalePage(
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
                                            'Are you sure you want to delete the order "${order.name}"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              openOrdersState
                                                  .removeOrder(index);
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // NFC Scanning Status Box - Only show on Android
                  if (NFCService.isMobile)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.nfc, color: Colors.white, size: 30),
                          SizedBox(width: 10),
                          Text(
                            'Ready to Scan Card',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ElevatedButton.icon(
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
                          builder: (context) => const POSSalePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
