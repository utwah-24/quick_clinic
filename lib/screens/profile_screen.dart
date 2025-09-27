import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/data_service.dart';
import '../services/localization_service.dart';
import '../widgets/drawer.dart';
import '../widgets/dynamic_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    setState(() {
      _currentUser = DataService.getCurrentUser();
      if (_currentUser == null) {
        // Create a mock user for demo
        _currentUser = User(
          id: 'user1',
          name: 'John Doe',
          email: 'john.doe@example.com',
          phone: '+254700123456',
          dateOfBirth: DateTime(1990, 5, 15),
          gender: 'Male',
          address: 'Dar es Salaam, Tanzania',
          emergencyContact: 'Jane Doe',
          emergencyContactPhone: '+255700654321',
          medicalHistory: ['Hypertension', 'Diabetes'],
          allergies: ['Penicillin'],
          bloodGroup: 'O+',
          profileImageUrl: '/placeholder.svg?height=150&width=150',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        );
        DataService.setCurrentUser(_currentUser!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(
        currentRoute: '/profile',
        userName: 'John Doe',
        userEmail: 'john@example.com',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DynamicAppBar(title: 'Profile'),
            // Content area
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _currentUser == null
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildProfileHeader(),
                            const SizedBox(height: 24),
                            _buildPersonalInfo(),
                            const SizedBox(height: 24),
                            _buildMedicalInfo(),
                            const SizedBox(height: 24),
                            _buildAccountActions(),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[800]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.network(
              _currentUser!.profileImageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 100,
                  height: 100,
                  color: Colors.white,
                  child:  Icon(Icons.person, size: 50, color: Colors.blue[800]),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentUser!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            _currentUser!.email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Member since ${_currentUser!.createdAt.day}/${_currentUser!.createdAt.month}/${_currentUser!.createdAt.year}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editProfile,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Phone', _currentUser!.phone),
            _buildInfoRow('Date of Birth', '${_currentUser!.dateOfBirth.day}/${_currentUser!.dateOfBirth.month}/${_currentUser!.dateOfBirth.year}'),
            _buildInfoRow('Gender', _currentUser!.gender),
            _buildInfoRow('Address', _currentUser!.address),
            _buildInfoRow('Emergency Contact', _currentUser!.emergencyContact),
            _buildInfoRow('Emergency Phone', _currentUser!.emergencyContactPhone),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                const Text(
                  'Medical Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editMedicalInfo,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Blood Group', _currentUser!.bloodGroup),
            const SizedBox(height: 8),
            const Text(
              'Medical History:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: _currentUser!.medicalHistory.map((condition) {
                return Chip(
                  label: Text(condition),
                  backgroundColor: Colors.blue[100],
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            const Text(
              'Allergies:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: _currentUser!.allergies.map((allergy) {
                return Chip(
                  label: Text(allergy),
                  backgroundColor: Colors.red[100],
                );
              }).toList(),
            ),
          ],
        ),
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

  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('Profile editing functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editMedicalInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Medical Information'),
        content: const Text('Medical information editing would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
