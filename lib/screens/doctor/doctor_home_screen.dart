import 'package:flutter/material.dart';
import 'dart:ui';
import '../patient/schedule_screen.dart';
import '../patient/profile_screen.dart';
import 'doctor_requests_screen.dart';
import '../../widgets/drawer.dart';
import '../../widgets/dynamic_app_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../services/data_service.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _currentIndex = 0;
  String _doctorName = 'Dr. Smith'; // Default fallback name

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  void _loadDoctorData() {
    // You can load actual doctor data here
    // For now, using a default name
    setState(() {
      _doctorName = 'Dr. Smith';
    });
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
        return ProfileScreen();
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
        drawer: const AppDrawer(
          currentRoute: '/doctor-home',
          userName: 'Dr. Smith',
          userEmail: 'dr.smith@example.com',
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
            NavBarItem(icon: Icons.home, label: 'Home'),
            NavBarItem(icon: Icons.request_page, label: 'Requests'),
            NavBarItem(icon: Icons.schedule, label: 'Schedule'),
            NavBarItem(icon: Icons.person, label: 'Profile'),
          ],
        ),
      );
    }

    // Desktop layout with permanent drawer
    return Scaffold(
      body: Row(
        children: [
          // Permanent drawer for desktop
          const SizedBox(
            width: 280,
            child: AppDrawer(
              currentRoute: '/doctor-home',
              userName: 'Dr. Smith',
              userEmail: 'dr.smith@example.com',
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15.0,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final List<Map<String, dynamic>> categories = [
      {"label": "Cardiology", "icon": Icons.monitor_heart},
      {"label": "Neurology", "icon": Icons.psychology_alt},
      {"label": "Pediatrics", "icon": Icons.vaccines},
      {"label": "Dermatology", "icon": Icons.health_and_safety},
      {"label": "Orthopedics", "icon": Icons.healing},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specialties',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 1),
            itemBuilder: (context, index) {
              final item = categories[index];
              return _buildCategoryCard(
                icon: item['icon'] as IconData,
                label: item['label'] as String,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({required IconData icon, required String label}) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1976D2).withOpacity(0.15),
                  blurRadius: 8.0,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF1976D2), size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
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



