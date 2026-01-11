import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/user.dart';
import '../../services/data_service.dart';
import '../../services/api_client.dart';

class EditProfileScreen extends StatefulWidget {
  final User currentUser;
  
  const EditProfileScreen({super.key, required this.currentUser});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _allergiesController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  bool _isLoading = false;
  String? _gender;
  final ApiClient _apiClient = ApiClient();
  
  List<String> _medicalHistoryList = [];
  List<String> _allergiesList = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _nameController.text = widget.currentUser.name;
    _emailController.text = widget.currentUser.email;
    _phoneController.text = widget.currentUser.phone;
    _addressController.text = widget.currentUser.address;
    _emergencyContactController.text = widget.currentUser.emergencyContact;
    _emergencyContactPhoneController.text = widget.currentUser.emergencyContactPhone;
    _bloodGroupController.text = widget.currentUser.bloodGroup;
    _gender = widget.currentUser.gender.isNotEmpty ? widget.currentUser.gender : null;
    _medicalHistoryList = List.from(widget.currentUser.medicalHistory);
    _allergiesList = List.from(widget.currentUser.allergies);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _emergencyContactPhoneController.dispose();
    _bloodGroupController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    super.dispose();
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
                  if (_profileImage != null || widget.currentUser.profileImageUrl.isNotEmpty)
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await DataService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final updateData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'gender': _gender,
        'emergencyContact': _emergencyContactController.text.trim(),
        'emergencyContactPhone': _emergencyContactPhoneController.text.trim(),
        'bloodGroup': _bloodGroupController.text.trim(),
        'medicalHistory': _medicalHistoryList,
        'allergies': _allergiesList,
      };

      print('🔵 [DEBUG] Updating profile with data: $updateData');
      print('🔵 [DEBUG] Profile Image: ${_profileImage != null ? 'Included as file' : 'Not included'}');

      // Try different possible update endpoints
      final possibleEndpoints = [
        '/api/user/profile',
        '/api/profile',
        '/api/user',
        '/api/auth/profile',
      ];

      bool updateSuccess = false;
      for (final endpoint in possibleEndpoints) {
        try {
          print('🔵 [DEBUG] Trying update endpoint: $endpoint with multipart upload');
          final response = await _apiClient.putMultipartWithAuth(
            endpoint, 
            updateData, 
            token, 
            file: _profileImage, 
            fileFieldName: 'profileImage'
          );
          print('🔵 [DEBUG] Update response from $endpoint: $response');
          
          if (response['success'] == true) {
            updateSuccess = true;
            break;
          }
        } catch (e) {
          print('🔵 [DEBUG] Endpoint $endpoint failed: $e');
          continue;
        }
      }

      if (updateSuccess) {
        // Update local user data
        final updatedUser = User(
          id: widget.currentUser.id,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          dateOfBirth: widget.currentUser.dateOfBirth,
          gender: _gender ?? '',
          address: _addressController.text.trim(),
          emergencyContact: _emergencyContactController.text.trim(),
          emergencyContactPhone: _emergencyContactPhoneController.text.trim(),
          medicalHistory: _medicalHistoryList,
          allergies: _allergiesList,
          bloodGroup: _bloodGroupController.text.trim(),
          profileImageUrl: _profileImage != null 
              ? widget.currentUser.profileImageUrl // Keep existing URL, server will update it
              : widget.currentUser.profileImageUrl,
          createdAt: widget.currentUser.createdAt,
        );

        DataService.setCurrentUser(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        throw Exception('Failed to update profile on server');
      }
    } catch (e) {
      print('🔴 [DEBUG] Profile update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addToList(List<String> list, String item) {
    if (item.trim().isNotEmpty && !list.contains(item.trim())) {
      setState(() {
        list.add(item.trim());
      });
    }
  }

  void _removeFromList(List<String> list, String item) {
    setState(() {
      list.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Profile Picture',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _showImageSourceDialog,
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
                            : widget.currentUser.profileImageUrl.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      widget.currentUser.profileImageUrl,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Color(0xFF1976D2),
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
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
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Basic Information
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                validator: (value) => value?.trim().isEmpty == true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.trim().isEmpty == true) return 'Email is required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone',
                keyboardType: TextInputType.phone,
                validator: (value) => value?.trim().isEmpty == true ? 'Phone is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Gender',
                value: _gender,
                items: const ['male', 'female', 'other'],
                onChanged: (value) => setState(() => _gender = value),
              ),
              const SizedBox(height: 32),

              // Emergency Contact
              _buildSectionHeader('Emergency Contact'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emergencyContactController,
                label: 'Emergency Contact Name',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emergencyContactPhoneController,
                label: 'Emergency Contact Phone',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),

              // Medical Information
              _buildSectionHeader('Medical Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bloodGroupController,
                label: 'Blood Group',
              ),
              const SizedBox(height: 24),

              // Medical History
              _buildListSection(
                title: 'Medical History',
                items: _medicalHistoryList,
                controller: _medicalHistoryController,
                onAdd: (item) => _addToList(_medicalHistoryList, item),
                onRemove: (item) => _removeFromList(_medicalHistoryList, item),
              ),
              const SizedBox(height: 24),

              // Allergies
              _buildListSection(
                title: 'Allergies',
                items: _allergiesList,
                controller: _allergiesController,
                onAdd: (item) => _addToList(_allergiesList, item),
                onRemove: (item) => _removeFromList(_allergiesList, item),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1976D2),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChanged,
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

  Widget _buildListSection({
    required String title,
    required List<String> items,
    required TextEditingController controller,
    required Function(String) onAdd,
    required Function(String) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return Chip(
                label: Text(item),
                onDeleted: () => onRemove(item),
                deleteIcon: const Icon(Icons.close, size: 16),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: controller,
                label: 'Add $title',
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  onAdd(value);
                  controller.clear();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ],
    );
  }
}

