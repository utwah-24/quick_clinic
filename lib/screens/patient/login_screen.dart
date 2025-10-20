import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../models/user.dart';
import '../../services/data_service.dart';
import 'package:flutter/material.dart' show Navigator;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  final ApiClient _apiClient = ApiClient();
  
  // Animation controllers for scroll-based image animation
  late ScrollController _scrollController;
  late AnimationController _imageAnimationController;
  late Animation<double> _imageSizeAnimation;
  double _imageSize = 100.0; // Original size

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _imageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _imageSizeAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _imageAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Add scroll listener
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    _imageAnimationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final loginData = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      };

      final response = await _apiClient.postJson('/api/auth/login', loginData);
      
      // Debug: Print full API response
      print('🔍 DEBUG: Full API Response:');
      print('Response: $response');
      
      // Handle successful login
      if (response['success'] == true && response['data'] != null) {
        final userData = response['data'] as Map<String, dynamic>;
        final token = response['token'] as String;
        
        // Debug: Print extracted data
        print('🔍 DEBUG: Extracted Data:');
        print('Success: ${response['success']}');
        print('Message: ${response['message']}');
        print('Token: $token');
        print('User Data: $userData');
        print('User ID: ${userData['id']}');
        print('User Name: ${userData['name']}');
        print('User Email: ${userData['email']}');
        print('User Phone: ${userData['phone']}');
        
        // Debug: Print ALL fields in userData to see what's available
        print('🔍 DEBUG: All available fields in userData:');
        userData.forEach((key, value) {
          print('  $key: $value (${value.runtimeType})');
        });
        
        // Store the auth token
        print('🔍 DEBUG: Storing auth token...');
        DataService.setAuthToken(token);
        print('🔍 DEBUG: Token stored successfully');
        
        // Fetch complete user profile from /api/user/profile
        User? user;
        try {
          print('🔍 DEBUG: Fetching complete profile from /api/user/profile...');
          final profileResponse = await _apiClient.getJsonWithAuth('/api/user/profile', token);
          print('🔍 DEBUG: Profile API Response: $profileResponse');
          
          if (profileResponse['success'] == true && profileResponse['data'] != null) {
            final profileData = profileResponse['data'] as Map<String, dynamic>;
            print('🔍 DEBUG: Complete profile data: $profileData');
            
            // Create user object from complete profile data
            user = User(
              id: profileData['id']?.toString() ?? userData['id']?.toString() ?? '',
              name: profileData['name']?.toString() ?? userData['name']?.toString() ?? '',
              email: profileData['email']?.toString() ?? userData['email']?.toString() ?? '',
              phone: profileData['phone']?.toString() ?? userData['phone']?.toString() ?? '',
              dateOfBirth: DateTime.tryParse(profileData['dateOfBirth']?.toString() ?? '') ?? DateTime.now(),
              gender: profileData['gender']?.toString() ?? '',
              address: profileData['address']?.toString() ?? '',
              emergencyContact: profileData['emergencyContact']?.toString() ?? '',
              emergencyContactPhone: profileData['emergencyContactPhone']?.toString() ?? '',
              medicalHistory: (profileData['medicalHistory'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
              allergies: (profileData['allergies'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
              bloodGroup: profileData['bloodGroup']?.toString() ?? '',
              profileImageUrl: profileData['profileImageUrl']?.toString() ?? '',
              createdAt: DateTime.tryParse(profileData['createdAt']?.toString() ?? '') ?? DateTime.now(),
            );
            print('🔍 DEBUG: Successfully created user from complete profile data');
          } else {
            throw Exception('Profile API returned unsuccessful response');
          }
        } catch (e) {
          print('🔍 DEBUG: Failed to fetch complete profile, using login data: $e');
          
          // Fallback: Create user object from login response data only
          user = User(
            id: userData['id']?.toString() ?? '',
            name: userData['name']?.toString() ?? '',
            email: userData['email']?.toString() ?? '',
            phone: userData['phone']?.toString() ?? '',
            dateOfBirth: DateTime.tryParse(userData['dateOfBirth']?.toString() ?? '') ?? DateTime.now(),
            gender: userData['gender']?.toString() ?? '',
            address: userData['address']?.toString() ?? '',
            emergencyContact: userData['emergencyContact']?.toString() ?? '',
            emergencyContactPhone: userData['emergencyContactPhone']?.toString() ?? '',
            medicalHistory: (userData['medicalHistory'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
            allergies: (userData['allergies'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
            bloodGroup: userData['bloodGroup']?.toString() ?? '',
            profileImageUrl: userData['profileImageUrl']?.toString() ?? '',
            createdAt: DateTime.tryParse(userData['createdAt']?.toString() ?? '') ?? DateTime.now(),
          );
        }
        
        // Debug: Print complete user object with default values
        print('🔍 DEBUG: Complete User Object:');
        print('User ID: ${user.id}');
        print('User Name: ${user.name}');
        print('User Email: ${user.email}');
        print('User Phone: ${user.phone}');
        print('User Date of Birth: ${user.dateOfBirth}');
        print('User Gender: ${user.gender}');
        print('User Address: ${user.address}');
        print('User Emergency Contact: ${user.emergencyContact}');
        print('User Emergency Contact Phone: ${user.emergencyContactPhone}');
        print('User Medical History: ${user.medicalHistory}');
        print('User Allergies: ${user.allergies}');
        print('User Blood Group: ${user.bloodGroup}');
        print('User Profile Image URL: ${user.profileImageUrl}');
        print('User Created At: ${user.createdAt}');
        
        // Store user data
        print('🔍 DEBUG: Storing user data...');
        DataService.setCurrentUser(user);
        print('🔍 DEBUG: User data stored successfully');
        
        // Debug: Verify stored data
        print('🔍 DEBUG: Verifying stored data...');
        final storedUser = DataService.getCurrentUser();
        final storedToken = DataService.getAuthToken();
        print('Stored User: $storedUser');
        print('Stored User Name: ${storedUser?.name}');
        print('Stored Token: $storedToken');
        print('Stored Token Length: ${storedToken?.length}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, ${user.name}!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Set patient role and navigate to patient home
          await DataService.setUserRole('patient');
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onScroll() {
    final scrollOffset = _scrollController.offset;
    const maxScrollOffset = 200.0; // Adjust this value to control when animation completes
    
    // Calculate animation progress (0.0 to 1.0)
    final animationProgress = (scrollOffset / maxScrollOffset).clamp(0.0, 1.0);
    
    // Update image size based on scroll position
    setState(() {
      _imageSize = 100.0 - (100.0 * animationProgress);
    });
    
    // Update animation controller
    _imageAnimationController.value = animationProgress;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 70),
                              AnimatedBuilder(
                                animation: _imageSizeAnimation,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _imageSize > 0 ? 1.0 : 0.0,
                                    child: Transform.scale(
                                      scale: _imageSize / 100.0,
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Image.asset('assets/login-img.png'),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign in to your account to continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Login Form
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'Enter your email address',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Forgot password functionality would be implemented here'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xFF1976D2),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[300])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[300])),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Social Login Buttons
                        _buildSocialLoginButton(
                          icon: Icons.g_mobiledata,
                          label: 'Continue with Google',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Google login would be implemented here'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        _buildSocialLoginButton(
                          icon: Icons.facebook,
                          label: 'Continue with Facebook',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Facebook login would be implemented here'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        // Register Link
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(color: Colors.grey[600]),
                                children: [
                                  const TextSpan(text: "Don't have an account? "),
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: TextStyle(
                                      color: Colors.blue[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey[700],
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
