import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/data_service.dart';
import '../../services/api_client.dart';
import 'edit_profile_screen.dart';
import 'add_payment_method_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  _PatientProfileScreenState createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  User? _currentUser;
  static const Color _brand = Color(0xFF0B2D5B);
  late final PageController _detailsPageController;
  int _detailsPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _detailsPageController = PageController();
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
        final token = await DataService.getAuthToken();
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
  void dispose() {
    _detailsPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 8),
                  // Top bar
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        'Profile',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      const SizedBox(width: 36),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Avatar with edit
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // existing resolver avatar
                        _buildProfilePicture(),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: InkWell(
                            onTap: _editProfile,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: _brand,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _currentUser?.name.isNotEmpty == true ? _currentUser!.name : 'User',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Profile details with swipe for more info
                  _profileDetailsPager(),
                  const SizedBox(height: 12),
                  _menuItem(
                    icon: Icons.credit_card,
                    label: 'Add Card',
                    onTap: _openAddPayment,
                  ),
                  _divider(),
                  _menuItem(icon: Icons.favorite_border, label: 'Favourite', onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Favourites coming soon')),
                    );
                  }),
                  _divider(),
                  _menuItem(icon: Icons.settings, label: 'Settings', onTap: _showNotificationSettings),
                  _divider(),
                  _menuItem(icon: Icons.info_outline, label: 'Help Center', onTap: _showHelpSupport),
                  _divider(),
                  _menuItem(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy Policy placeholder')),
                    );
                  }),
                  _divider(),
                  _menuItem(icon: Icons.logout, label: 'Log out', onTap: _logout, danger: true),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _divider() => Divider(height: 1, thickness: 0.8, color: Colors.grey[200]);

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final Color color = danger ? Colors.red : _brand;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.arrow_forward, color: color),
      onTap: onTap,
    );
  }

  Widget _profileDetailsCard() {
    final user = _currentUser!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
        child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
            ListTile(
              leading: const Icon(Icons.email_outlined, color: _brand),
              title: const Text('Email'),
              subtitle: Text(user.email.isNotEmpty ? user.email : 'Not provided'),
            ),
            _divider(),
            ListTile(
              leading: const Icon(Icons.phone_outlined, color: _brand),
              title: const Text('Phone'),
              subtitle: Text(user.phone.isNotEmpty ? user.phone : 'Not provided'),
            ),
            _divider(),
            ListTile(
              leading: const Icon(Icons.cake_outlined, color: _brand),
              title: const Text('Date of Birth'),
              subtitle: Text(
                (user.dateOfBirth.year > 0)
                    ? '${user.dateOfBirth.day}/${user.dateOfBirth.month}/${user.dateOfBirth.year}'
                    : 'Not provided',
              ),
            ),
            _divider(),
            ListTile(
              leading: const Icon(Icons.person_outline, color: _brand),
              title: const Text('Gender'),
              subtitle: Text(user.gender.isNotEmpty ? user.gender : 'Not specified'),
            ),
            _divider(),
            ListTile(
              leading: const Icon(Icons.location_on_outlined, color: _brand),
              title: const Text('Address'),
              subtitle: Text(user.address.isNotEmpty ? user.address : 'Not provided'),
            ),
          ],
        ),
      ),
    );
  }

  // Legacy helpers removed (new simplified UI implemented)
  // Widget _buildProfileHeader() => const SizedBox.shrink();

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
                headers: null, // Token will be handled by API if needed
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

  // Widget _buildProfileContent() => const SizedBox.shrink();

  // Widget _buildUserInfo() { return const SizedBox.shrink(); }

  // Widget _buildStatItem(String value, String label) { return const SizedBox.shrink(); }

  // Widget _buildStatsCards() { return const SizedBox.shrink(); }

  // Widget _buildStatCard({required IconData icon, required Color iconColor, required String value, required String label,}) { return const SizedBox.shrink(); }

  // Widget _buildPersonalInfoCard() { return const SizedBox.shrink(); }

  // Widget _buildMedicalInfoCard() { return const SizedBox.shrink(); }

  // Widget _buildAccountActions() { return const SizedBox.shrink(); }

  // Widget _buildInfoRow(String label, String value) { return const SizedBox.shrink(); }

  Widget _profileDetailsPager() {
    final user = _currentUser!;
    final double screenHeight = MediaQuery.of(context).size.height;
    double pagerHeight = screenHeight * 0.55; // responsive height target
    if (pagerHeight < 340) pagerHeight = 340; // keep it tall enough for small phones
    if (pagerHeight > 520) pagerHeight = 520; // avoid overly tall on tablets
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: pagerHeight,
          child: PageView(
            controller: _detailsPageController,
            onPageChanged: (i) => setState(() => _detailsPageIndex = i),
            children: [
              _profileDetailsCard(),
              _profileMoreDetailsCard(user),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (i) {
            final bool active = _detailsPageIndex == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: active ? 18 : 6,
              decoration: BoxDecoration(
                color: active ? _brand : Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _profileMoreDetailsCard(User user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
            ListTile(
              leading: const Icon(Icons.contact_emergency_outlined, color: _brand),
              title: const Text('Emergency Contact'),
              subtitle: Text(user.emergencyContact.isNotEmpty ? user.emergencyContact : 'Not provided'),
            ),
            _divider(),
            ListTile(
              leading: const Icon(Icons.phone_in_talk_outlined, color: _brand),
              title: const Text('Emergency Phone'),
              subtitle: Text(user.emergencyContactPhone.isNotEmpty ? user.emergencyContactPhone : 'Not provided'),
            ),
            _divider(),
            ListTile(
              leading: const Icon(Icons.bloodtype_outlined, color: _brand),
              title: const Text('Blood Group'),
              subtitle: Text(user.bloodGroup.isNotEmpty ? user.bloodGroup : 'Not provided'),
            ),
            _divider(),
            ListTile(
              leading: const Icon(Icons.local_hospital_outlined, color: _brand),
              title: const Text('Medical History'),
              subtitle: Text(user.medicalHistory.isNotEmpty ? user.medicalHistory.join(', ') : 'Not provided'),
            ),
            _divider(),
            ListTile(
              leading: const Icon(Icons.warning_amber_outlined, color: _brand),
              title: const Text('Allergies'),
              subtitle: Text(user.allergies.isNotEmpty ? user.allergies.join(', ') : 'None'),
            ),
            _divider(),
            ListTile(
              leading: const Icon(Icons.event_available_outlined, color: _brand),
              title: const Text('Member Since'),
              subtitle: Text(
                user.createdAt.year > 0
                    ? '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'
                    : 'Not available',
              ),
            ),
            ],
          ),
        ),
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

  // void _editMedicalInfo() async {}

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

  Future<void> _openAddPayment() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const AddPaymentMethodScreen()),
    );
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected payment method: ' + result)),
      );
    }
  }

  // void _showLanguageSelector() {}

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
