import 'package:flutter/material.dart';
import 'dart:ui';
import '../patient/schedule_screen.dart';
import '../patient/patient_profile_screen.dart';
import 'doctor_requests_screen.dart';
import 'doctor_profile_screen.dart';
import '../../widgets/drawer.dart';
import '../../widgets/dynamic_app_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../services/data_service.dart';
import '../../services/api_client.dart';
import '../../models/user.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _currentIndex = 0;
  String _doctorName = 'Dr. Smith'; // Default fallback name
  String _doctorEmail = 'dr.smith@example.com'; // Default fallback email
  String? _doctorAvatar; // Doctor profile image URL

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    print('🔍 DEBUG: Loading doctor data...');
    
    // Try to use already loaded user first, otherwise load from storage/API
    User? user = DataService.getCurrentUser();
    print('🔍 DEBUG: Current user from DataService: $user');
    print('🔍 DEBUG: User profileImageUrl: ${user?.profileImageUrl}');
    
    // Let's also check the raw user data to see all fields
    if (user != null) {
      print('🔍 DEBUG: User ID: ${user.id}');
      print('🔍 DEBUG: User Name: ${user.name}');
      print('🔍 DEBUG: User Email: ${user.email}');
      print('🔍 DEBUG: User Phone: ${user.phone}');
      print('🔍 DEBUG: User Address: ${user.address}');
      print('🔍 DEBUG: User Blood Group: ${user.bloodGroup}');
      print('🔍 DEBUG: User Gender: ${user.gender}');
      print('🔍 DEBUG: User Emergency Contact: ${user.emergencyContact}');
      print('🔍 DEBUG: User Medical History: ${user.medicalHistory}');
      print('🔍 DEBUG: User Allergies: ${user.allergies}');
      print('🔍 DEBUG: User Profile Image URL: "${user.profileImageUrl}"');
      print('🔍 DEBUG: User Profile Image URL length: ${user.profileImageUrl.length}');
      print('🔍 DEBUG: User Profile Image URL is empty: ${user.profileImageUrl.isEmpty}');
    }
    
    // If no user data found, try to load from storage or fetch from API
    if (user == null) {
      user = await DataService.loadUserFromStorage();
      print('🔍 DEBUG: User after loadUserFromStorage: $user');
      print('🔍 DEBUG: User profileImageUrl after load: ${user?.profileImageUrl}');
    }
    
    final role = DataService.getUserRole();
    final token = await DataService.getAuthToken();
    print('🔍 DEBUG: User role: $role, Token exists: ${token != null}');

    // Always try to fetch fresh data from API if we have a token (to get updated profile image)
    if (token != null) {
      print('🔵 [DEBUG] Fetching fresh user data from API...');
      try {
        final ApiClient api = ApiClient();
        final response = await api.getJsonWithAuth('/api/user/profile', token);
        
        if (response['success'] == true && response['data'] != null) {
          final userData = response['data'] as Map<String, dynamic>;
          print('🔍 DEBUG: API userData: $userData');
          final String imageUrl = _resolveAbsoluteUrl(userData['profileImageUrl']?.toString());
          print('🔍 DEBUG: resolved profile image from API (absolute): $imageUrl');
          
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
            profileImageUrl: imageUrl,
            createdAt: DateTime.tryParse(userData['createdAt']?.toString() ?? '') ?? DateTime.now(),
          );
          
          print('🔍 DEBUG: Created user object with profileImageUrl: ${user.profileImageUrl}');
          
          // Store the fetched user data
          DataService.setCurrentUser(user);
          print('✅ [DEBUG] Successfully fetched and stored user data from API');
        } else {
          print('🔴 [DEBUG] API response was not successful or no data returned');
        }
      } catch (e) {
        print('🔴 [DEBUG] Failed to fetch user data from API: $e');
      }
    }
    
    // Use the most up-to-date user data
    final currentUser = DataService.getCurrentUser();
    if (currentUser != null) {
      user = currentUser;
      print('🔍 DEBUG: Using most recent user data from DataService');
    }

    String name = (user?.name.trim().isNotEmpty == true) ? user!.name.trim() : 'Dr. Smith';
    // If role is doctor and name doesn't already start with Dr., prefix it
    if (role == 'doctor' && !name.toLowerCase().startsWith('dr.')) {
      name = 'Dr. ' + name;
    }

    final String email = (user?.email.trim().isNotEmpty == true)
        ? user!.email.trim()
        : 'dr.smith@example.com';

    final String? avatar = user?.profileImageUrl.isNotEmpty == true ? user!.profileImageUrl : null;
    
    print('🔍 DEBUG: Final values - name: $name, email: $email, avatar: $avatar');

    if (mounted) {
      setState(() {
        _doctorName = name;
        _doctorEmail = email;
        _doctorAvatar = avatar;
      });
      print('🔍 DEBUG: State updated - _doctorName: $_doctorName, _doctorEmail: $_doctorEmail, _doctorAvatar: $_doctorAvatar');
    }
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

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildDoctorHomeTab();
      case 1:
        return const DoctorRequestsScreen();
      case 2:
        return const ScheduleScreen();
      case 3:
        return DoctorProfileScreen();
      default:
        return _buildDoctorHomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;
    if (!isWide) {
      // Mobile layout with bottom navigation
      return Scaffold(
        drawer: AppDrawer(
          key: ValueKey('$_doctorName-$_doctorEmail'), // Force rebuild when doctor data changes
          currentRoute: '/doctor-home',
          userName: _doctorName,
          userEmail: _doctorEmail,
          userAvatar: _doctorAvatar,
        ),
        body: AnimatedSwitcher(
          key: ValueKey(_currentIndex),
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: Material(
                color: Colors.transparent,
                child: child,
              ),
            );
          },
          child: _getCurrentScreen(),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
          items: const [
            NavBarItem(icon: 'assets/icons/home.png', label: 'Home'),
            NavBarItem(icon: 'assets/icons/request.png', label: 'Requests'),
            NavBarItem(icon: 'assets/icons/event.png', label: 'Schedule'),
            // NavBarItem(icon: 'assets/icons/person.png', label: 'Profile'),
          ],
        ),
      );
    }

    // Desktop layout with permanent drawer
    return Scaffold(
      body: Row(
        children: [
          // Permanent drawer for desktop
          SizedBox(
            width: 280,
            child: AppDrawer(
              key: ValueKey('$_doctorName-$_doctorEmail'), // Force rebuild when doctor data changes
              currentRoute: '/doctor-home',
              userName: _doctorName,
              userEmail: _doctorEmail,
              userAvatar: _doctorAvatar,
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Container(child: _buildDoctorHomeTab()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Search patients, appointments...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorHomeTab() {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[800]!, Colors.blue[400]!],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                DynamicAppBar(
                  title: '',
                  titleColor: Colors.white,
                  iconColor: Colors.white,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      color: Colors.white,
                      onPressed: () {
                        // Handle notification tap
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _doctorName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSearchBar(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ]
            ),
            
            // Content with padding
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40), 
                topRight: Radius.circular(40)
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // const SizedBox(height: 24),
                      // _buildCategoriesSection(),
                      const SizedBox(height: 24),
                      _buildModernQuickActions(),
                      const SizedBox(height: 24),
                      _buildTodayAppointmentsSection(),
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

  Widget _buildModernQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 120,
          width: 120,
          child: _buildModernQuickActionCard(
            icon: Icons.calendar_today,
            title: 'Today\'s Schedule',
            color: Colors.blue[600]!,
            gradient: [Colors.blue[400]!, Colors.blue[600]!],
            onTap: () {
              _onTap(2); // Navigate to schedule
            },
          ),
        ),
        const SizedBox(width: 20),
        Container(
          height: 120,
          width: 120,
          child: _buildModernQuickActionCard(
            icon: Icons.request_page,
            title: 'Requests',
            color: Colors.green[600]!,
            gradient: [Colors.green[400]!, Colors.green[600]!],
            onTap: () {
              _onTap(1); // Navigate to requests
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20.0,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon container with gradient background
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Title with better typography
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Subtle accent line
                Container(
                  width: 30,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildTodayAppointmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Appointments',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your scheduled appointments for today',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),
        _buildAppointmentCard(
          patientName: 'John Doe',
          time: '09:00 AM',
          specialty: 'General Checkup',
          status: 'Confirmed',
        ),
        const SizedBox(height: 12),
        _buildAppointmentCard(
          patientName: 'Jane Smith',
          time: '10:30 AM',
          specialty: 'Follow-up',
          status: 'Confirmed',
        ),
        const SizedBox(height: 12),
        _buildAppointmentCard(
          patientName: 'Mike Johnson',
          time: '02:00 PM',
          specialty: 'Consultation',
          status: 'Pending',
        ),
      ],
    );
  }

  Widget _buildAppointmentCard({
    required String patientName,
    required String time,
    required String specialty,
    required String status,
  }) {
    Color statusColor = status == 'Confirmed' ? Colors.green : Colors.orange;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20.0,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person,
              color: Colors.blue[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  specialty,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

}



