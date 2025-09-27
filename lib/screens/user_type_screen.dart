import 'package:flutter/material.dart';

class UserTypeScreen extends StatefulWidget {
  const UserTypeScreen({super.key});

  @override
  _UserTypeScreenState createState() => _UserTypeScreenState();
}

class _UserTypeScreenState extends State<UserTypeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.pushNamed(context, '/login');
  }

  void _showComingSoon(String userType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$userType login coming soon!'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          
                          // Logo and Title Section
                          Image.asset(
                            'assets/logo.jpg',
                            width: 225,
                            height: 100,
                            fit: BoxFit.fill,
                          ),
                          
                          const SizedBox(height: 30),
                          
                         
                          
                          const SizedBox(height: 60),
                          
                          // User Type Buttons
                          _buildUserTypeButton(
                            icon: Icons.person,
                            title: 'Log in as Patient',
                            subtitle: 'Access medical services and book appointments',
                            onTap: _navigateToLogin,
                            isAvailable: true,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          _buildUserTypeButton(
                            icon: Icons.medical_services,
                            title: 'Log in as Doctor',
                            subtitle: 'Manage appointments and patient care',
                            onTap: () => _showComingSoon('Doctor'),
                            isAvailable: false,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          _buildUserTypeButton(
                            icon: Icons.health_and_safety,
                            title: 'Log in as Pharmacist',
                            subtitle: 'Manage the medicines for the patients',
                            onTap: () => _showComingSoon('Pharmacist'),
                            isAvailable: false,
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Additional Info
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.grey[600],
                                  size: 24,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'New to Quick Clinic?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You can create a new account from the login screen',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isAvailable,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAvailable ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isAvailable 
                        ? const Color(0xFF1976D2).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isAvailable 
                        ? const Color(0xFF1976D2)
                        : Colors.grey,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isAvailable ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isAvailable ? Colors.grey[600] : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isAvailable ? Colors.grey[400] : Colors.grey[300],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
