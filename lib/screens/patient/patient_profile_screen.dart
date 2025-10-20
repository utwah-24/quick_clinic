import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/data_service.dart';
import '../../services/api_client.dart';
import '../../services/localization_service.dart';
import '../../widgets/drawer.dart';
import 'edit_profile_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  _PatientProfileScreenState createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    // Force load user data from storage/API
    User? user = DataService.getCurrentUser();
    
    // If no user in memory, try to load from storage/API
    if (user == null) {
      user = await DataService.loadUserFromStorage();
    }
    
    // If still no user, try to fetch from API directly
    if (user == null) {
      try {
        final token = DataService.getAuthToken();
        if (token != null) {
          final apiClient = ApiClient();
          
          // Get user ID from stored user data
          final currentUser = DataService.getCurrentUser();
          final userId = currentUser?.id;
          
          // Try different possible profile endpoints
          final possibleEndpoints = [
            '/api/user/profile',
            '/api/profile',
            '/api/user',
            '/api/auth/user',
            '/api/patient/profile',
            if (userId != null) '/api/users/$userId',
            if (userId != null) '/api/patient/$userId',
            if (userId != null) '/api/user/$userId/profile',
          ];
          
          for (final endpoint in possibleEndpoints) {
            try {
              print('🔍 DEBUG: Trying endpoint: $endpoint');
              final response = await apiClient.getJsonWithAuth(endpoint, token);
              print('🔍 DEBUG: Profile API Response from $endpoint: $response');
              if (response['success'] == true && response['data'] != null) {
                print('🔍 DEBUG: Profile data: ${response['data']}');
                user = User.fromJson(response['data'] as Map<String, dynamic>);
                print('🔍 DEBUG: Parsed user: ${user.toJson()}');
                DataService.setCurrentUser(user);
                break; // Found data, stop trying other endpoints
              }
            } catch (e) {
              print('🔍 DEBUG: Endpoint $endpoint failed: $e');
              continue; // Try next endpoint
            }
          }
        }
      } catch (e) {
        print('Error fetching user profile: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _currentUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        currentRoute: '/profile',
        userName: _currentUser?.name.isNotEmpty == true ? _currentUser!.name : 'Loading...',
        userEmail: _currentUser?.email.isNotEmpty == true ? _currentUser!.email : '',
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  _buildProfileContent(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      height: 220, // Increased height to prevent overflow
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Added to prevent overflow
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
               
                ],
              ),
              const SizedBox(height: 10), // Increased spacing
              _buildProfilePicture(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    // Resolve avatar to network URL (same logic as drawer)
    String? resolvedNetworkUrl;
    final raw = _currentUser?.profileImageUrl.trim();
    if (raw != null && raw.isNotEmpty) {
      try {
        if (raw.startsWith('http://') || raw.startsWith('https://')) {
          resolvedNetworkUrl = raw;
        } else if (raw.startsWith('/')) {
          // Relative path from API - prepend /public/ for profile images
          final base = ApiClient.baseUrl;
          final path = raw.startsWith('/public/') ? raw : '/public' + raw;
          final joined = base + path; // base already trimmed of trailing slash
          resolvedNetworkUrl = joined;
        } else {
          // Unknown format; attempt network by prefixing base URL with /public/
          final base = ApiClient.baseUrl;
          final path = raw.startsWith('/') ? '/public' + raw : '/public/' + raw;
          final joined = base + path;
          resolvedNetworkUrl = joined;
        }
        print('🔍 DEBUG: ProfileScreen - Resolved avatar - networkUrl=$resolvedNetworkUrl');
      } catch (e) {
        print('🔴 DEBUG: ProfileScreen - Failed to resolve avatar "$raw": $e');
      }
    }

    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.white,
      child: resolvedNetworkUrl != null
          ? ClipOval(
              child: Image.network(
                resolvedNetworkUrl,
                width: 62,
                height: 62,
                fit: BoxFit.cover,
                headers: () {
                  final token = DataService.getAuthToken();
                  return token != null && token.isNotEmpty
                      ? {
                          'Authorization': 'Bearer ' + token,
                          'Accept': 'image/*,application/octet-stream'
                        }
                      : null;
                }(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    print('🔍 DEBUG: ProfileScreen - Profile image loaded successfully: $resolvedNetworkUrl');
                    return child;
                  }
                  print('🔍 DEBUG: ProfileScreen - Loading profile image: $resolvedNetworkUrl');
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  print('🔍 DEBUG: ProfileScreen - Error loading profile image: $error');
                  return Icon(Icons.person, size: 41, color: Colors.blue[600]);
                },
              ),
            )
          : Icon(Icons.person, size: 51, color: Colors.blue[600]),
    );
  }

  Widget _buildProfileContent() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildUserInfo(),
            const SizedBox(height: 30),
            _buildStatsCards(),
            const SizedBox(height: 30),
            _buildPersonalInfoCard(),
            const SizedBox(height: 20),
            _buildMedicalInfoCard(),
            const SizedBox(height: 20),
            _buildAccountActions(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        Text(
          _currentUser!.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentUser!.email,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatItem('0', 'Appointments'),
            const SizedBox(width: 40),
            _buildStatItem('0', 'Reviews'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.8, // Increased from 1.5 to give more height
      children: [
        _buildStatCard(
          icon: Icons.phone,
          iconColor: Colors.blue,
          value: _currentUser!.phone.isNotEmpty ? _currentUser!.phone : 'Not provided',
          label: 'Phone',
        ),
        _buildStatCard(
          icon: Icons.cake,
          iconColor: Colors.orange,
          value: '${_currentUser!.dateOfBirth.day}/${_currentUser!.dateOfBirth.month}/${_currentUser!.dateOfBirth.year}',
          label: 'Date of Birth',
        ),
        _buildStatCard(
          icon: Icons.person_outline,
          iconColor: Colors.pink,
          value: _currentUser!.gender.isNotEmpty ? _currentUser!.gender : 'Not specified',
          label: 'Gender',
        ),
        _buildStatCard(
          icon: Icons.location_on,
          iconColor: Colors.green,
          value: _currentUser!.address.isNotEmpty ? _currentUser!.address : 'Not provided',
          label: 'Address',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Added to prevent overflow
        children: [
          Container(
            padding: const EdgeInsets.all(6), // Reduced padding
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18), // Reduced icon size
          ),
          const SizedBox(height: 8), // Reduced spacing
          Flexible( // Added Flexible to prevent overflow
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14, // Reduced font size
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2), // Reduced spacing
          Text(
            label,
            style: TextStyle(
              fontSize: 11, // Reduced font size
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: _editProfile,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Emergency Contact', _currentUser!.emergencyContact.isNotEmpty ? _currentUser!.emergencyContact : 'Not provided'),
          _buildInfoRow('Emergency Phone', _currentUser!.emergencyContactPhone.isNotEmpty ? _currentUser!.emergencyContactPhone : 'Not provided'),
        ],
      ),
    );
  }

  Widget _buildMedicalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.medical_services, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Medical Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: _editMedicalInfo,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Blood Group', _currentUser!.bloodGroup.isNotEmpty ? _currentUser!.bloodGroup : 'Not specified'),
          const SizedBox(height: 12),
          if (_currentUser!.medicalHistory.isNotEmpty) ...[
            const Text(
              'Medical History:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _currentUser!.medicalHistory.map((condition) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    condition,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (_currentUser!.allergies.isNotEmpty) ...[
            const Text(
              'Allergies:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _currentUser!.allergies.map((allergy) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    allergy,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[800],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.history, color: Color(0xFF2E7D32)),
            title: const Text('Appointment History'),
            subtitle: const Text('View all your past appointments'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to appointments screen
              DefaultTabController.of(context).animateTo(3);
            },
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.payment, color: Color(0xFF2E7D32)),
            title: const Text('Payment History'),
            subtitle: const Text('View payment records'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _showPaymentHistory,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.language, color: Color(0xFF2E7D32)),
            title: Text(LocalizationService.translate('language')),
            subtitle: const Text('Change app language'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _showLanguageSelector,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.notifications, color: Color(0xFF2E7D32)),
            title: const Text('Notifications'),
            subtitle: const Text('Manage notification preferences'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _showNotificationSettings,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.help, color: Color(0xFF2E7D32)),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help or contact support'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _showHelpSupport,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            subtitle: const Text('Sign out of your account'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _logout,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _editProfile() async {
    if (_currentUser == null) return;
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(currentUser: _currentUser!),
      ),
    );
    
    // If profile was updated successfully, reload the profile
    if (result == true) {
      _loadUserProfile();
    }
  }

  void _editMedicalInfo() async {
    if (_currentUser == null) return;
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(currentUser: _currentUser!),
      ),
    );
    
    // If profile was updated successfully, reload the profile
    if (result == true) {
      _loadUserProfile();
    }
  }

  void _showPaymentHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment History'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Dr. John Kamau - KSh 3,000'),
              subtitle: Text('15/12/2023 - Paid via M-Pesa'),
              leading: Icon(Icons.check_circle, color: Colors.green),
            ),
            ListTile(
              title: Text('Dr. Sarah Wanjiku - KSh 4,000'),
              subtitle: Text('10/12/2023 - Paid via Card'),
              leading: Icon(Icons.check_circle, color: Colors.green),
            ),
            ListTile(
              title: Text('Emergency Service - KSh 1,500'),
              subtitle: Text('05/12/2023 - Paid Cash'),
              leading: Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocalizationService.supportedLanguages.map((code) {
            return RadioListTile<String>(
              title: Text(LocalizationService.getLanguageName(code)),
              value: code,
              groupValue: LocalizationService.currentLanguage,
              onChanged: (value) {
                setState(() {
                  LocalizationService.setLanguage(value!);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Language changed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: const Text('Notification preferences would be managed here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact Support:'),
            SizedBox(height: 8),
            Text('📞 Phone: +254-700-MEDICAL'),
            Text('📧 Email: support@medicalapp.com'),
            Text('💬 Live Chat: Available 24/7'),
            SizedBox(height: 16),
            Text('FAQ and troubleshooting guides would be available here.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await DataService.clearUserData();
              Navigator.pushNamedAndRemoveUntil(context, '/user-type', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
