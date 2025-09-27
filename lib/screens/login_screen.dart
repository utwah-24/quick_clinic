import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../models/user.dart';
import '../services/data_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  final ApiClient _apiClient = ApiClient();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
        
        // Store the auth token
        print('🔍 DEBUG: Storing auth token...');
        DataService.setAuthToken(token);
        print('🔍 DEBUG: Token stored successfully');
        
        // Create user object from response data
        final user = User(
          id: userData['id']?.toString() ?? '',
          name: userData['name']?.toString() ?? '',
          email: userData['email']?.toString() ?? '',
          phone: userData['phone']?.toString() ?? '',
          dateOfBirth: DateTime.now(), // Default since not provided in login response
          gender: 'Unknown', // Default since not provided in login response
          address: 'Unknown', // Default since not provided in login response
          emergencyContact: 'Unknown', // Default since not provided in login response
          emergencyContactPhone: 'Unknown', // Default since not provided in login response
          medicalHistory: [], // Default since not provided in login response
          allergies: [], // Default since not provided in login response
          bloodGroup: 'Unknown', // Default since not provided in login response
          profileImageUrl: '', // Default since not provided in login response
          createdAt: DateTime.now(),
        );
        
        // Debug: Print created user object
        print('🔍 DEBUG: Created User Object:');
        print('User ID: ${user.id}');
        print('User Name: ${user.name}');
        print('User Email: ${user.email}');
        print('User Phone: ${user.phone}');
        print('User Date of Birth: ${user.dateOfBirth}');
        print('User Gender: ${user.gender}');
        print('User Address: ${user.address}');
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
          
          // Navigate to home screen
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
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
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset('assets/login-img.png'),
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
