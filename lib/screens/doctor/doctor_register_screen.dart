import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../services/api_client.dart';
import '../../services/data_service.dart';
import '../../models/user.dart';
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
  // Additional profile fields
  final _dateOfBirth = TextEditingController();
  String? _gender;
  final _address = TextEditingController();
  final _emergencyContact = TextEditingController();
  final _emergencyContactPhone = TextEditingController();
  String? _bloodGroup;
  String? _hospitalId;
  final _hospitalIdController = TextEditingController();
  // Dynamic list fields
  final List<String> _allergies = [];
  final List<String> _medicalHistory = [];
  final _allergyInput = TextEditingController();
  final _medicalHistoryInput = TextEditingController();
  final _licenseNumber = TextEditingController();
  String? _specialty;
  final _yearsOfExperience = TextEditingController();
  final _clinicName = TextEditingController();
  final _clinicAddress = TextEditingController();
  final _bio = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  final ApiClient _api = ApiClient();
  List<HospitalOption> _hospitalOptions = [];
  int _stepIndex = 0; // 0..4
  bool _isHospitalsLoading = false;
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _dateOfBirth.dispose();
    _address.dispose();
    _emergencyContact.dispose();
    _emergencyContactPhone.dispose();
    _allergyInput.dispose();
    _medicalHistoryInput.dispose();
    _hospitalIdController.dispose();
    _licenseNumber.dispose();
    _yearsOfExperience.dispose();
    _clinicName.dispose();
    _clinicAddress.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    try {
      setState(() => _isHospitalsLoading = true);
      final list = await DataService.getNearbyHospitals();
      if (!mounted) return;
      setState(() {
        _hospitalOptions = list.map((h) => HospitalOption(id: h.id, name: h.name)).toList();
      });
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _isHospitalsLoading = false);
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
        try {
          final size = await _profileImage!.length();
          print('🔵 [DEBUG] Picked image from gallery: path=${_profileImage!.path}, size=${size} bytes');
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takeProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
        try {
          final size = await _profileImage!.length();
          print('🔵 [DEBUG] Captured image from camera: path=${_profileImage!.path}, size=${size} bytes');
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickProfileImage();
                    },
                  ),
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _takeProfileImage();
                    },
                  ),
                  if (_profileImage != null)
                    _buildImageSourceOption(
                      icon: Icons.delete,
                      label: 'Remove',
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _profileImage = null;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 30,
              color: const Color(0xFF1976D2),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed post-registration profile image upload as backend lacks a PUT/POST profile endpoint.

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
        'dateOfBirth': _dateOfBirth.text.trim(),
        'gender': _gender,
        'address': _address.text.trim(),
        'emergencyContact': _emergencyContact.text.trim(),
        'emergencyContactPhone': _emergencyContactPhone.text.trim(),
        'medicalHistory': _medicalHistory,
        'allergies': _allergies,
        'bloodGroup': _bloodGroup,
        'hospitalId': _hospitalId,
        'licenseNumber': _licenseNumber.text.trim(),
        'specialty': _specialty,
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
      print('🔵 [DEBUG] - DOB: ${payload['dateOfBirth']}');
      print('🔵 [DEBUG] - Gender: ${payload['gender']}');
      print('🔵 [DEBUG] - Address: ${payload['address']}');
      print('🔵 [DEBUG] - Emergency: ${payload['emergencyContact']} / ${payload['emergencyContactPhone']}');
      print('🔵 [DEBUG] - BloodGroup: ${payload['bloodGroup']}');
      print('🔵 [DEBUG] - HospitalId: ${payload['hospitalId']}');
      print('🔵 [DEBUG] - License: ${payload['licenseNumber']}');
      print('🔵 [DEBUG] - Specialty: ${payload['specialty']}');
      print('🔵 [DEBUG] - Experience: ${payload['yearsOfExperience']}');
      print('🔵 [DEBUG] - Clinic: ${payload['clinicName']}');
      print('🔵 [DEBUG] - Address: ${payload['clinicAddress']}');
      print('🔵 [DEBUG] - Bio: ${payload['bio']}');
      print('🔵 [DEBUG] - Password length: ${(payload['password'] as String?)?.length ?? 0}');
      print('🔵 [DEBUG] - Profile Image: ${_profileImage != null ? 'Included as file' : 'Not included'}');

      // Try different field names for profile image
      Map<String, dynamic> res = {};
      bool registrationSuccess = false;
      
      // Try with different field names (snake_case first for typical backends)
      final fieldNames = ['profile_image', 'profileImage', 'image', 'avatar', 'photo'];
      
      for (final fieldName in fieldNames) {
        try {
          print('🔵 [DEBUG] Trying multipart upload with field name: $fieldName (with aliases)');
          res = await _api.postMultipart(
            '/api/auth/register', 
            payload, 
            file: _profileImage, 
            fileFieldName: fieldName,
            fileFieldAliases: fieldNames,
          );
          registrationSuccess = true;
          break;
        } catch (e) {
          print('🔴 [DEBUG] Multipart upload with field name $fieldName failed: $e');
          continue;
        }
      }
      
      // If all multipart attempts failed:
      if (!registrationSuccess) {
        if (_profileImage != null) {
          // Do NOT fallback when image is required; surface the error so user can fix
          print('🔴 [DEBUG] All multipart attempts failed and a profile image was provided. Aborting to avoid losing the image.');
          throw Exception('Registration failed: could not upload profile image.');
        } else {
          print('🔴 [DEBUG] All multipart attempts failed, trying JSON fallback (no profile image selected)');
          final jsonPayload = Map<String, dynamic>.from(payload);
          print('🔵 [DEBUG] Making API call to /api/auth/register with JSON (no profile image)');
          res = await _api.postJson('/api/auth/register', jsonPayload);
        }
      }
      
      print('🔵 [DEBUG] API response received:');
      print('🔵 [DEBUG] - Response: $res');
      print('🔵 [DEBUG] - Success status: ${res['success']}');
      
      if (res['success'] == true) {
        print('✅ [DEBUG] Registration successful!');
        
        // Extract user data and token from response (similar to login flow)
        final userData = res['data'] as Map<String, dynamic>?;
        final token = res['token'] as String?;
        
        print('🔵 [DEBUG] Extracted data from registration response:');
        print('🔵 [DEBUG] - User Data: $userData');
        print('🔵 [DEBUG] - Token: $token');
        
        if (userData != null && token != null) {
          print('🔵 [DEBUG] Storing auth token...');
          DataService.setAuthToken(token);
          print('🔵 [DEBUG] Token stored successfully');
          
          print('🔍 DEBUG: Registration response userData: $userData');
          print('🔍 DEBUG: profileImageUrl in registration response: ${userData['profileImageUrl']}');
          
          // Resolve absolute image URL if present
          final String regImageUrl = _resolveAbsoluteUrl(userData['profileImageUrl']?.toString());

          // Create User object from registration data
          final user = User(
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
            profileImageUrl: regImageUrl,
            createdAt: DateTime.tryParse(userData['createdAt']?.toString() ?? '') ?? DateTime.now(),
          );
          
          print('🔍 DEBUG: Created user object with profileImageUrl: ${user.profileImageUrl}');
          
          // If profile image wasn't uploaded during registration, try to upload it now
          // Skip post-registration upload: server does not support update endpoint (405/404 seen)
          
          print('🔵 [DEBUG] Storing user data...');
          DataService.setCurrentUser(user);
          print('🔵 [DEBUG] User data stored successfully');
        } else {
          print('🔴 [DEBUG] Warning: No user data or token in registration response');
        }
        
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
        final readable = _formatReadableError(res);
        throw Exception(readable);
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
                  // Header and progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _stepIndex > 0 ? _back : null,
                        child: const Icon(Icons.arrow_back),
                      ),
                      Text('STEP ${_stepIndex + 1}/5', style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: (_stepIndex + 1) / 5),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_stepIcon(), color: const Color(0xFF1976D2)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _stepTitle(),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1976D2)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildStepContent(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (_stepIndex > 0)
                        OutlinedButton(onPressed: _isLoading ? null : _back, child: const Text('Back')),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_stepIndex < 4) {
                                  _next();
                                } else {
                                  _submitWithAllValidation();
                                }
                              },
                        child: _isLoading
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                            : Text(_stepIndex < 4 ? 'Next' : 'Create Doctor Account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _stepTitle() {
    switch (_stepIndex) {
      case 0:
        return 'Main details';
      case 1:
        return 'Extra details';
      case 2:
        return 'Medical info';
      case 3:
        return 'Professional details';
      case 4:
        return 'Clinic info';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_stepIndex) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            Center(
              child: Column(
                children: [
                  const Text(
                    'Profile Picture',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showImageSourceDialog(),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1976D2),
                          width: 3,
                        ),
                        color: Colors.grey[100],
                      ),
                      child: _profileImage != null
                          ? ClipOval(
                              child: Image.file(
                                _profileImage!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              ),
                            )
                          : const Icon(
                              Icons.person_add,
                              size: 50,
                              color: Color(0xFF1976D2),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _profileImage != null ? 'Tap to change' : 'Tap to add photo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _pickProfileImage,
                        icon: const Icon(Icons.photo_library, size: 16),
                        label: const Text('Gallery'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: _takeProfileImage,
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: const Text('Camera'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(now.year - 25, now.month, now.day),
                  firstDate: DateTime(1930, 1, 1),
                  lastDate: DateTime(now.year - 18, now.month, now.day),
                );
                if (picked != null) {
                  _dateOfBirth.text = picked.toIso8601String().split('T').first;
                  setState(() {});
                }
              },
              child: AbsorbPointer(
                child: _field(controller: _dateOfBirth, label: 'Date of Birth', hint: 'YYYY-MM-DD', validator: _req),
              ),
            ),
            const SizedBox(height: 12),
            _dropdown<String>(
              label: 'Gender',
              value: _gender,
              items: const ['female', 'male', 'other'],
              onChanged: (v) => setState(() => _gender = v),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            _field(controller: _address, label: 'Address', hint: 'Street, City', validator: _req, maxLines: 2),
            const SizedBox(height: 12),
            _field(controller: _emergencyContact, label: 'Emergency Contact Name', hint: 'John Doe', validator: _req),
            const SizedBox(height: 12),
            _field(controller: _emergencyContactPhone, label: 'Emergency Contact Phone', hint: '+255700000010', keyboardType: TextInputType.phone, validator: _req),
            const SizedBox(height: 12),
            _dropdown<String>(
              label: 'Blood Group',
              value: _bloodGroup,
              items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
              onChanged: (v) => setState(() => _bloodGroup = v),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _chipsEditor(label: 'Allergies', controller: _allergyInput, values: _allergies),
            const SizedBox(height: 12),
            _chipsEditor(label: 'Medical History', controller: _medicalHistoryInput, values: _medicalHistory),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(controller: _licenseNumber, label: 'Medical License Number', hint: 'e.g., TMC-123456', validator: _req),
            const SizedBox(height: 12),
            _dropdown<String>(
              label: 'Specialty',
              value: _specialty,
              items: const ['Cardiology', 'psychiatry', 'Dermatology', 'pediatrics', 'neurosurgery'],
              onChanged: (v) => setState(() => _specialty = v),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            _field(controller: _yearsOfExperience, label: 'Years of Experience', hint: 'e.g., 8', keyboardType: TextInputType.number, validator: _req),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Manual Hospital ID input is ALWAYS available and is the source of truth
            _field(
              controller: _hospitalIdController,
              label: 'Hospital ID',
              hint: 'Enter Hospital ID',
              validator: _req,
            ),
            const SizedBox(height: 8),
            if (_isHospitalsLoading)
              const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: CircularProgressIndicator()))
            else if (_hospitalOptions.isEmpty) ...[
              Row(
                children: [
                  const Expanded(child: Text('No hospitals found nearby.')),
                  OutlinedButton(onPressed: _loadHospitals, child: const Text('Reload')),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              _dropdown<String>(
                label: 'Select Hospital (optional)',
                value: _hospitalId,
                items: _hospitalOptions.map((h) => h.id).toList(),
                itemLabels: {for (final h in _hospitalOptions) h.id: h.name},
                onChanged: (v) => setState(() {
                  _hospitalId = v;
                  _hospitalIdController.text = v ?? '';
                }),
              ),
            ],
            const SizedBox(height: 12),
            _field(controller: _clinicName, label: 'Clinic/Hospital Name', hint: 'Sunrise Clinic', validator: _req),
            const SizedBox(height: 12),
            _field(controller: _clinicAddress, label: 'Clinic Address', hint: 'Street, City', validator: _req, maxLines: 2),
            const SizedBox(height: 12),
            _field(controller: _bio, label: 'Short Bio', hint: 'Tell patients about your expertise', maxLines: 3),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  IconData _stepIcon() {
    switch (_stepIndex) {
      case 0:
        return Icons.person;
      case 1:
        return Icons.badge;
      case 2:
        return Icons.medical_information;
      case 3:
        return Icons.workspace_premium;
      case 4:
        return Icons.local_hospital;
      default:
        return Icons.circle;
    }
  }

  bool _validateCurrentStep() {
    switch (_stepIndex) {
      case 0:
        return _formKey.currentState!.validate();
      case 1:
        if ((_dateOfBirth.text.trim().isEmpty) || (_gender == null || _gender!.isEmpty)) return false;
        if (_address.text.trim().isEmpty) return false;
        if (_emergencyContact.text.trim().isEmpty || _emergencyContactPhone.text.trim().isEmpty) return false;
        if (_bloodGroup == null || _bloodGroup!.isEmpty) return false;
        return true;
      case 2:
        return true; // optional lists
      case 3:
        return _licenseNumber.text.trim().isNotEmpty && _specialty != null && _specialty!.isNotEmpty && _yearsOfExperience.text.trim().isNotEmpty;
      case 4:
        // Use manual controller as source of truth for validation
        final manualId = _hospitalIdController.text.trim();
        if (manualId.isNotEmpty) {
          _hospitalId = manualId;
        }
        return (manualId.isNotEmpty) && _clinicName.text.trim().isNotEmpty && _clinicAddress.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  void _next() {
    if (_validateCurrentStep()) {
      setState(() => _stepIndex++);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete the required fields')));
    }
  }

  void _back() {
    if (_stepIndex > 0) setState(() => _stepIndex--);
  }

  Future<void> _submitWithAllValidation() async {
    // Validate final step first
    if (!_validateCurrentStep()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete the required fields')));
      return;
    }
    // Basic guard for step 0/1/3 as well
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty || _phone.text.trim().isEmpty || _password.text.length < 6) {
      setState(() => _stepIndex = 0);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill in name, email, phone and a valid password')));
      return;
    }
    if (_dateOfBirth.text.trim().isEmpty || _gender == null || _bloodGroup == null) {
      setState(() => _stepIndex = 1);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill in extra details')));
      return;
    }
    if (_licenseNumber.text.trim().isEmpty || _specialty == null || _specialty!.isEmpty || _yearsOfExperience.text.trim().isEmpty) {
      setState(() => _stepIndex = 3);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill in professional details')));
      return;
    }
    // Ensure hospitalId uses manual input if provided
    final manualId = _hospitalIdController.text.trim();
    if (manualId.isNotEmpty) {
      _hospitalId = manualId;
    }
    await _submit();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  // _section was used in the previous single-page layout. No longer required in wizard.

  String _formatReadableError(dynamic resOrMessage) {
    // Accept either a decoded response map or a raw string
    try {
      if (resOrMessage is Map<String, dynamic>) {
        final msg = resOrMessage['message']?.toString();
        final errors = resOrMessage['errors'];
        if (errors is Map) {
          final parts = <String>[];
          errors.forEach((k, v) {
            if (v is List && v.isNotEmpty) {
              parts.add('$k: ${v.first}');
            } else if (v != null) {
              parts.add('$k: $v');
            }
          });
          final details = parts.isNotEmpty ? ' (' + parts.join('; ') + ')' : '';
          return (msg ?? 'Validation error') + details;
        }
        return msg ?? 'Registration failed';
      }
      // Try to parse if string contains JSON
      if (resOrMessage is String) {
        try {
          final parsed = json.decode(resOrMessage);
          return _formatReadableError(parsed);
        } catch (_) {
          return resOrMessage;
        }
      }
    } catch (_) {}
    return 'Registration failed';
  }

  String _resolveAbsoluteUrl(String? raw) {
    if (raw == null) return '';
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
    // Use API base from ApiClient and prepend /public/ for profile images
    final base = ApiClient.baseUrl;
    final path = trimmed.startsWith('/public/') ? trimmed : '/public' + (trimmed.startsWith('/') ? trimmed : '/' + trimmed);
    return base + path;
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    Map<T, String>? itemLabels,
    required void Function(T? value) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(itemLabels != null ? (itemLabels[e] ?? e.toString()) : e.toString()),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
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

  Widget _chipsEditor({
    required String label,
    required TextEditingController controller,
    required List<String> values,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < values.length; i++)
              Chip(
                label: Text(values[i]),
                onDeleted: () => setState(() => values.removeAt(i)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _field(
                controller: controller,
                label: 'Add $label',
                hint: 'Type and press +',
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final v = controller.text.trim();
                  if (v.isEmpty) return;
                  setState(() {
                    values.add(v);
                    controller.clear();
                  });
                },
                child: const Text('+'),
              ),
            ),
          ],
        ),
      ],
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

class HospitalOption {
  final String id;
  final String name;
  HospitalOption({required this.id, required this.name});
}



