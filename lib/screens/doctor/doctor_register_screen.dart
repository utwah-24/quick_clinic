import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/data_service.dart';
import 'doctor_home_screen.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _licenseNumber = TextEditingController();
  final _specialty = TextEditingController();
  final _yearsOfExperience = TextEditingController();
  final _clinicName = TextEditingController();
  final _clinicAddress = TextEditingController();
  final _bio = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  final ApiClient _api = ApiClient();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _licenseNumber.dispose();
    _specialty.dispose();
    _yearsOfExperience.dispose();
    _clinicName.dispose();
    _clinicAddress.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    print('🔵 [DEBUG] Create Doctor Account button pressed');
    print('🔵 [DEBUG] Form validation started');
    
    if (!_formKey.currentState!.validate()) {
      print('🔴 [DEBUG] Form validation failed - returning early');
      return;
    }
    
    print('✅ [DEBUG] Form validation passed');
    print('🔵 [DEBUG] Setting loading state to true');
    setState(() => _isLoading = true);
    
    try {
      final payload = {
        'role': 'doctor',
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'password': _password.text,
        'licenseNumber': _licenseNumber.text.trim(),
        'specialty': _specialty.text.trim(),
        'yearsOfExperience': int.tryParse(_yearsOfExperience.text.trim()) ?? 0,
        'clinicName': _clinicName.text.trim(),
        'clinicAddress': _clinicAddress.text.trim(),
        'bio': _bio.text.trim(),
      };

      print('🔵 [DEBUG] Payload prepared:');
      print('🔵 [DEBUG] - Role: ${payload['role']}');
      print('🔵 [DEBUG] - Name: ${payload['name']}');
      print('🔵 [DEBUG] - Email: ${payload['email']}');
      print('🔵 [DEBUG] - Phone: ${payload['phone']}');
      print('🔵 [DEBUG] - License: ${payload['licenseNumber']}');
      print('🔵 [DEBUG] - Specialty: ${payload['specialty']}');
      print('🔵 [DEBUG] - Experience: ${payload['yearsOfExperience']}');
      print('🔵 [DEBUG] - Clinic: ${payload['clinicName']}');
      print('🔵 [DEBUG] - Address: ${payload['clinicAddress']}');
      print('🔵 [DEBUG] - Bio: ${payload['bio']}');
      print('🔵 [DEBUG] - Password length: ${(payload['password'] as String?)?.length ?? 0}');

      print('🔵 [DEBUG] Making API call to /api/auth/register');
      final res = await _api.postJson('/api/auth/register', payload);
      
      print('🔵 [DEBUG] API response received:');
      print('🔵 [DEBUG] - Response: $res');
      print('🔵 [DEBUG] - Success status: ${res['success']}');
      
      if (res['success'] == true) {
        print('✅ [DEBUG] Registration successful!');
        print('🔵 [DEBUG] Setting user role to doctor');
        await DataService.setUserRole('doctor');
        
        if (mounted) {
          print('🔵 [DEBUG] Showing success snackbar');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful!'), backgroundColor: Colors.green),
          );
          
          print('🔵 [DEBUG] Navigating to DoctorHomeScreen');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DoctorHomeScreen()),
            (route) => false,
          );
          print('✅ [DEBUG] Navigation completed');
        }
      } else {
        print('🔴 [DEBUG] Registration failed - success is false');
        print('🔴 [DEBUG] Error message: ${res['message']}');
        throw Exception(res['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('🔴 [DEBUG] Exception caught in registration:');
      print('🔴 [DEBUG] - Exception type: ${e.runtimeType}');
      print('🔴 [DEBUG] - Exception message: $e');
      print('🔴 [DEBUG] - Stack trace: ${StackTrace.current}');
      
      if (mounted) {
        print('🔵 [DEBUG] Showing error snackbar');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      print('🔵 [DEBUG] Finally block - setting loading to false');
      if (mounted) setState(() => _isLoading = false);
      print('🔵 [DEBUG] Registration process completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    'Doctor Registration',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                  ),
                  const SizedBox(height: 8),
                  Text('Provide your professional details', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 24),
                  _field(controller: _name, label: 'Full Name', hint: 'Dr. Jane Doe', validator: _req),
                  const SizedBox(height: 12),
                  _field(controller: _email, label: 'Email', hint: 'doctor@example.com', keyboardType: TextInputType.emailAddress, validator: _req),
                  const SizedBox(height: 12),
                  _field(controller: _phone, label: 'Phone', hint: '+255700000000', keyboardType: TextInputType.phone, validator: _req),
                  const SizedBox(height: 12),
                  _field(
                    controller: _password,
                    label: 'Password',
                    hint: 'Create a password',
                    obscureText: _obscure,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 20),
                  _section('Professional Details'),
                  const SizedBox(height: 12),
                  _field(controller: _licenseNumber, label: 'Medical License Number', hint: 'e.g., TMC-123456', validator: _req),
                  const SizedBox(height: 12),
                  _field(controller: _specialty, label: 'Specialty', hint: 'Cardiology, Dermatology, etc.', validator: _req),
                  const SizedBox(height: 12),
                  _field(controller: _yearsOfExperience, label: 'Years of Experience', hint: 'e.g., 8', keyboardType: TextInputType.number, validator: _req),
                  const SizedBox(height: 20),
                  _section('Clinic Information'),
                  const SizedBox(height: 12),
                  _field(controller: _clinicName, label: 'Clinic/Hospital Name', hint: 'Sunrise Clinic', validator: _req),
                  const SizedBox(height: 12),
                  _field(controller: _clinicAddress, label: 'Clinic Address', hint: 'Street, City', validator: _req, maxLines: 2),
                  const SizedBox(height: 12),
                  _field(controller: _bio, label: 'Short Bio', hint: 'Tell patients about your expertise', maxLines: 3),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : const Text('Create Doctor Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Widget _section(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1976D2)),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}



