import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import 'login_page.dart';
import '../main.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _isLoading = true;
  String? _errorMessage;
  late Timer _navigationTimer;

  Future<void> _initializeApp() async {
    try {
      // Simulate initialization tasks
      await Future.wait([
        _loadAppSettings(),
        _preloadAssets(),
        Future.delayed(const Duration(seconds: 2)), // Minimum splash duration
      ]);

      _navigateToNextScreen();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize app: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAppSettings() async {
    // Simulate loading app settings
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _preloadAssets() async {
    // Simulate preloading assets
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _navigateToNextScreen() {
    final userState = Provider.of<UserState>(context, listen: false);
    
    // Navigate to the appropriate screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => userState.isLoggedIn 
          ? const MainScreen() 
          : const LoginPage(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();

    // Fallback timer in case initialization takes too long
    _navigationTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        setState(() {
          _errorMessage = 'Initialization is taking longer than expected';
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepOrange.shade300,
              Colors.deepOrange.shade700,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/splash.jpg',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 24),
              if (_isLoading) ...[
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Initializing...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _initializeApp();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepOrange,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
