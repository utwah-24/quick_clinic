import 'package:flutter/material.dart';
import '../services/data_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
    
    // Check authentication state after animation
    Future.delayed(const Duration(seconds: 3), () {
      _checkAuthenticationAndNavigate();
    });
  }

  void _checkAuthenticationAndNavigate() async {
    try {
      // Load user from storage first
      await DataService.loadUserFromStorage();
      
      // Check if user is logged in by checking if current user exists
      final currentUser = DataService.getCurrentUser();
      
      if (currentUser != null) {
        // Route by role
        final role = DataService.getUserRole();
        if (role == 'doctor') {
          Navigator.pushReplacementNamed(context, '/doctor-home');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // User is not logged in, navigate to intro screen first
        Navigator.pushReplacementNamed(context, '/intro');
      }
    } catch (e) {
      print('Error during authentication check: $e');
      // If there's any error, default to intro screen
      Navigator.pushReplacementNamed(context, '/intro');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          width: 225,
                          height: 100,
                          child: Image.asset('assets/illustrations/logo.jpg',
                          fit: BoxFit.fill,
                          )),
                      const SizedBox(height: 30),
                     
                      
                      // Text(
                      //   LocalizationService.translate('welcome'),
                      //   style: TextStyle(
                      //     fontSize: 16,
                      //     color: Colors.white.withOpacity(0.9),
                      //   ),
                      // ),
                      const SizedBox(height: 50),
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
