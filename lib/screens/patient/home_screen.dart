import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../widgets/drawer.dart';
import 'hospitals_screen.dart';
import 'emergency_screen.dart';
import 'schedule_screen.dart';
import '../location_permission_screen.dart';
// Removed unused imports for cleaner build
// import 'explore_screen.dart';
import 'category_hospitals_screen.dart';
import 'notification_screen.dart';
import 'doctor_details_screen.dart';
import 'popular_doctors_screen.dart';
import '../../services/location_service.dart';
import '../../services/localization_service.dart';
import '../../widgets/dynamic_app_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../services/data_service.dart';
import '../../services/notification_service.dart';
import '../../models/hospital.dart';
import '../../models/hospital.dart' show Doctor;
import '../../models/appointment.dart';
import '../../utils/responsive.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _hasLocationPermission = false;
  int _currentIndex = 0;
  List<Map<String, dynamic>> _popularDoctorsWithHospital = [];
  bool _loadingDoctors = true;
  String? _doctorError;
  String _userName = 'User'; // Default fallback name
  String _userEmail = 'user@example.com'; // Default fallback email
  String? _userAvatar; // User profile image URL
  List<Appointment> _appointments = [];
  bool _loadingAppointments = true;
  int _unreadNotificationCount = 0;
  
  // Removed legacy manual scroll animation in favor of Slivers

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _initializeUserData();
    _loadAppointments();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    final count = await NotificationService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadNotificationCount = count;
      });
    }
  }

  Future<void> _initializeUserData() async {
    // First try to load user data from storage
    await DataService.loadUserFromStorage();
    _loadUserData();
  }

  void _loadUserData() {
    final user = DataService.getCurrentUser();
    print('🔍 DEBUG: Loading user data in home screen');
    print('🔍 DEBUG: User: $user');
    print('🔍 DEBUG: User name: ${user?.name}');
    print('🔍 DEBUG: User email: ${user?.email}');
    print('🔍 DEBUG: User profileImageUrl: ${user?.profileImageUrl}');
    
    if (user != null) {
      setState(() {
        _userName = user.name.isNotEmpty ? user.name : 'User';
        _userEmail = user.email.isNotEmpty ? user.email : 'user@example.com';
        _userAvatar = user.profileImageUrl.isNotEmpty ? user.profileImageUrl : null;
      });
      print('🔍 DEBUG: Updated state - _userName: $_userName, _userEmail: $_userEmail');
      print('🔍 DEBUG: Raw user data - name: "${user.name}", email: "${user.email}"');
    } else {
      print('🔍 DEBUG: No user data found');
    }
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loadingAppointments = true;
    });

    try {
      // First load from cache for immediate display
      final cachedAppointments = DataService.getUserAppointments();
      if (cachedAppointments.isNotEmpty && mounted) {
        setState(() {
          _appointments = List<Appointment>.from(cachedAppointments);
          _loadingAppointments = false;
        });
      }

      // Then fetch from API to get latest data
      try {
        final appointments = await DataService.fetchUserAppointments();
        if (mounted) {
          setState(() {
            _appointments = List<Appointment>.from(appointments);
            _loadingAppointments = false;
          });
        }
      } catch (apiError) {
        print('⚠️ API fetch failed, using cached: $apiError');
        if (mounted && _appointments.isEmpty) {
          final cachedAppointments = DataService.getUserAppointments();
          setState(() {
            _appointments = List<Appointment>.from(cachedAppointments);
            _loadingAppointments = false;
          });
        } else if (mounted) {
          setState(() {
            _loadingAppointments = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading appointments: $e');
      if (mounted) {
        setState(() {
          _loadingAppointments = false;
        });
      }
    }
  }

  Appointment? get _nextUpcomingAppointment {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final upcoming = _appointments.where((appointment) {
      final appointmentDate = DateTime(
        appointment.appointmentDate.year,
        appointment.appointmentDate.month,
        appointment.appointmentDate.day,
      );
      // Exclude cancelled and completed appointments
      if (appointment.status == AppointmentStatus.cancelled) {
        return false;
      }
      if (appointment.status == AppointmentStatus.completed) {
        return false;
      }
      // Only include future appointments or today's appointments
      return !appointmentDate.isBefore(today);
    }).toList();

    if (upcoming.isEmpty) return null;

    // Sort by date and return the closest one
    upcoming.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    return upcoming.first;
  }

  int get _upcomingAppointmentsCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _appointments.where((appointment) {
      final appointmentDate = DateTime(
        appointment.appointmentDate.year,
        appointment.appointmentDate.month,
        appointment.appointmentDate.day,
      );
      if (appointment.status == AppointmentStatus.cancelled) {
        return false;
      }
      if (appointment.status == AppointmentStatus.completed) {
        return false;
      }
      return !appointmentDate.isBefore(today);
    }).length;
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Sliver-based scroll behavior handles scaling/fading

  Widget _buildUpcomingSchedule() {
    final nextAppointment = _nextUpcomingAppointment;
    final appointmentCount = _upcomingAppointmentsCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Appointment Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 253, 253, 253),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with count badge and See All
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Upcoming Schedule',
                        style: TextStyle(
                          fontSize: Responsive.sp(context, 16),
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (appointmentCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            appointmentCount.toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScheduleScreen()),
                      ).then((_) {
                        // Reload appointments when returning from schedule screen
                        _loadAppointments();
                      });
                    },
                    child: Text(
                      'See All',
                      style: TextStyle(
                        fontSize: Responsive.sp(context, 16),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Show appointment or empty state
              if (_loadingAppointments)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (nextAppointment == null)
                _buildEmptyState()
              else
                _buildAppointmentContent(nextAppointment),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(
            Icons.calendar_month,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No upcoming appointments',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Book an appointment to see it here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentContent(Appointment appointment) {
    final doctorName = appointment.doctorName.isNotEmpty 
        ? appointment.doctorName 
        : 'Unknown Doctor';
    final doctorSpecialty = appointment.doctorSpecialty.isNotEmpty 
        ? appointment.doctorSpecialty 
        : 'General';
    final initials = _getInitials(doctorName);

    return Column(
      children: [
        // Doctor Info Section
        Row(
          children: [
            // Doctor Profile Picture/Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8F0FE),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Doctor Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctorName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctorSpecialty,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Call Icon (optional - can be removed if not needed)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.phone,
                color: Color.fromARGB(255, 0, 0, 0),
                size: 20,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Divider
        Divider(
          color: Colors.black.withOpacity(0.3),
          height: 1,
        ),
        const SizedBox(height: 16),
        
        // Appointment Details
        Row(
          children: [
            // Date
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.black,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _formatDate(appointment.appointmentDate),
                      style: TextStyle(
                        fontSize: Responsive.sp(context, 14),
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Vertical Divider
            Container(
              width: 1,
              height: 20,
              color: Colors.black.withOpacity(0.2),
            ),
            
            const SizedBox(width: 16),
            
            // Time
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.black,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      appointment.timeSlot.isNotEmpty 
                          ? appointment.timeSlot 
                          : 'Time TBD',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '??';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return first + last;
  }

  void _checkLocationPermission() {
    setState(() {
      _hasLocationPermission = LocationService.hasLocation;
    });
    _loadPopularDoctors();
  }

  Future<void> _loadPopularDoctors() async {
    setState(() {
      _loadingDoctors = true;
      _doctorError = null;
    });
    try {
      final doctors = await DataService.getPopularDoctors(limit: 8);
      
      // Also load hospitals to get context for doctors
      final hospitals = await DataService.getNearbyHospitals();
      final doctorsWithHospital = <Map<String, dynamic>>[];
      
      for (final doctor in doctors) {
        // Find the hospital that contains this doctor
        Hospital? doctorHospital;
        for (final hospital in hospitals) {
          if (hospital.doctors.any((d) => d.id == doctor.id)) {
            doctorHospital = hospital;
            break;
          }
        }
        
        doctorsWithHospital.add({
          'doctor': doctor,
          'hospitalId': doctorHospital?.id,
          'hospitalName': doctorHospital?.name,
        });
      }
      
      setState(() {
        _popularDoctorsWithHospital = doctorsWithHospital;
        _loadingDoctors = false;
      });
    } catch (e) {
      print('Error loading doctors: $e');
      setState(() {
        _doctorError = e.toString();
        _loadingDoctors = false;
      });
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Refresh appointments when navigating to home tab (index 0)
    if (index == 0) {
      _loadAppointments();
    }
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const HospitalsScreen();
      case 2:
        return const ScheduleScreen();
      // case 3:
      //   return const ;
      // case 4:
      //   return const HomeVisitScreen();
      default:
        return _buildHomeTab();
    }
  }

 

  @override
  Widget build(BuildContext context) {
    final isPhone = Responsive.isPhone(context);
    if (isPhone) {
      // Mobile layout with bottom navigation
      return Scaffold(
        drawer: _hasLocationPermission 
            ? AppDrawer(
                key: ValueKey('$_userName-$_userEmail'), // Force rebuild when user data changes
                currentRoute: '/home',
                userName: _userName,
                userEmail: _userEmail,
                userAvatar: _userAvatar,
              )
            : null,
        body: _hasLocationPermission
            ? AnimatedSwitcher(
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
              )
            : LocationPermissionScreen(
                onPermissionGranted: () {
                  setState(() {
                    _hasLocationPermission = true;
                  });
                },
              ),
        bottomNavigationBar: _hasLocationPermission
            ? CustomBottomNavBar(
                currentIndex: _currentIndex,
                onTap: _onBottomNavTap,
                items: const [
                  NavBarItem(icon: 'assets/icons/home.png', label: 'Home'),
                  NavBarItem(icon: 'assets/icons/hospitals.png', label: 'Hospitals'),
                  NavBarItem(icon: 'assets/icons/schedule.png', label: 'Schedule'),
                  // NavBarItem(icon: Icons.location_pin, label: 'Home Visit'),
                ],
              )
            : null,
      );
    }
    // Fallback to phone layout even on larger screens
    return Scaffold(
      drawer: _hasLocationPermission 
          ? AppDrawer(
              key: ValueKey('$_userName-$_userEmail'), // Force rebuild when user data changes
              currentRoute: '/home',
              userName: _userName,
              userEmail: _userEmail,
              userAvatar: _userAvatar,
            )
          : null,
      body: _hasLocationPermission
          ? AnimatedSwitcher(
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
            )
          : LocationPermissionScreen(
              onPermissionGranted: () {
                setState(() {
                  _hasLocationPermission = true;
                });
              },
            ),
      bottomNavigationBar: _hasLocationPermission
          ? CustomBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onBottomNavTap,
              items: const [
                NavBarItem(icon: 'assets/icons/home.png', label: 'Home'),
              
                NavBarItem(icon: 'assets/icons/hospitals.png', label: 'Hospitals'),
                NavBarItem(icon: 'assets/icons/schedule.png', label: 'Schedule'),
             
              ],
            )
          : null,
    );
  }

  Widget _buildHomeTab() {
    final screenHeight = MediaQuery.of(context).size.height;
    // Responsive header height: ~56% of screen height, clamped to [480, 560]
    final double maxHeaderHeight = math.max(300.0, math.min(screenHeight * 0.56, 500.0));
    final double minHeaderHeight = kToolbarHeight;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2D5B), Color(0xFF0B2D5B)],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: false,
            floating: false,
            delegate: _HeaderDelegate(
              maxHeight: maxHeaderHeight,
              minHeight: minHeaderHeight,
              builder: (context, t) {
                // t = 0 expanded, 1 collapsed
                final scale = 1.0 - (0.4 * t);
                double opacity;
                if (t <= 0.7) {
                  opacity = 1.0;
                } else if (t >= 0.9) {
                  opacity = 0.0;
                } else {
                  final local = (t - 0.7) / 0.2;
                  opacity = 1.0 - Curves.easeIn.transform(local);
                }

                return ClipRect(
                  child: Container(
                    decoration: const BoxDecoration(
                      // keep blue gradient background
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0B2D5B), Color(0xFF0B2D5B)],
                      ),
                    ),
                    child: SafeArea(
                      top: true,
                      // bottom: true,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Opacity(
                          opacity: opacity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                            child: Transform.scale(
                              scale: scale,
                              alignment: Alignment.topCenter,
                              child: OverflowBox(
                                alignment: Alignment.topCenter,
                                minHeight: 0.0,
                                maxHeight: double.infinity,
                                child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  DynamicAppBar(
                                    title: '',
                                    titleColor: Colors.white,
                                    iconColor: Colors.white,
                                      padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 0),
                                    actions: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.notifications),
                                            color: Colors.white,
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const NotificationScreen(),
                                                ),
                                              );
                                              // Refresh notification count when returning
                                              _loadNotificationCount();
                                            },
                                          ),
                                          if (_unreadNotificationCount > 0)
                                            Positioned(
                                              right: 6,
                                              top: 6,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints: const BoxConstraints(
                                                  minWidth: 18,
                                                  minHeight: 18,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6, bottom: 6),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Welcome back,',
                                          style: TextStyle(
                                            fontSize: Responsive.sp(context, 22),
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _userName,
                                          style: TextStyle(
                                            fontSize: Responsive.sp(context, 14),
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        _buildUpcomingSchedule(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Main content starts here
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -8),
              child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24, 
                    28, 
                    24, 
                    MediaQuery.of(context).padding.bottom + 80, // Account for bottom nav bar
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),
                      _buildCategoriesSection(),
                      const SizedBox(height: 24),
                      _buildModernQuickActions(),
                      const SizedBox(height: 24),
                      _buildPopularDoctorsGrid(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }

// moved to top-level below class



  Widget _buildModernQuickActions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48 - 20) / 2; // Account for padding and spacing
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: cardWidth,
          child: _buildModernQuickActionCard(
            icon: Image.asset('assets/icons/near_hosp.png', width: 24, height: 24, color: Colors.white),
            title: LocalizationService.translate('find_hospitals'),
            color: const Color(0xFF0B2D5B),
            gradient: [const Color(0xFF0B2D5B), const Color(0xFF0B2D5B)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HospitalsScreen()),
              );
            },
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: _buildModernQuickActionCard(
            icon: Image.asset('assets/icons/ambulance.png', width: 24, height: 24, color: Colors.white),
            title: LocalizationService.translate('emergency'),
            color: Colors.red.shade600,
            gradient: [Colors.red.shade400, Colors.red.shade600],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EmergencyScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernQuickActionCard({
    required Image icon,
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
            padding: const EdgeInsets.all(16),
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
              mainAxisSize: MainAxisSize.min,
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
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(child: icon),
                ),
                const SizedBox(height: 6),
                // Title with better typography
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                    letterSpacing: 0.2,
                    fontFamily: 'Lato',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Subtle accent line
                Container(
                  width: 20,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
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
      {"label": "Pediatrician", "icon": 'assets/icons/pediatrics.png'},
      {"label": "Neurosurgeon", "icon": 'assets/icons/Neuro.png'},
      {"label": "Cardiologist", "icon": 'assets/icons/cardio.png'},
      {"label": "Psychiatrist", "icon": 'assets/icons/psychiatrist.png'},
      {"label": "Dermatologist", "icon": 'assets/icons/allergy.png'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
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
                icon: item['icon'] ,
                label: item['label'] as String,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({required String icon, required String label}) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryHospitalsScreen(categoryName: label),
              ),
            );
          },
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
                      color: const Color.fromARGB(255, 0, 128, 255).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(icon, width: 28, height: 28),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black ,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularDoctorsGrid() {
    if (_loadingDoctors) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_doctorError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Doctors',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text('Failed to load doctors', style: TextStyle(color: Colors.red[600])),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _loadPopularDoctors, child: const Text('Retry')),
        ],
      );
    }

    // Show only a preview (up to 3 doctors) on the home screen
    final previewDoctorsWithHospital =
        _popularDoctorsWithHospital.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Popular Doctors',
              style: TextStyle(
                fontSize: Responsive.sp(context, 20),
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
                letterSpacing: 0.5,
              ),
            ),
            if (_popularDoctorsWithHospital.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PopularDoctorsScreen(
                        popularDoctorsWithHospital: _popularDoctorsWithHospital,
                      ),
                    ),
                  );
                },
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: Responsive.sp(context, 14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Meet our top-rated healthcare professionals',
          style: TextStyle(
            fontSize: Responsive.sp(context, 14),
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),
        if (previewDoctorsWithHospital.isEmpty)
          Text(
            'No popular doctors found',
            style: TextStyle(color: Colors.grey[600]),
          )
        else
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: previewDoctorsWithHospital.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final doctorData = previewDoctorsWithHospital[index];
                final d = doctorData['doctor'] as Doctor;
                return SizedBox(
                  width: 150,
                  child: _buildCompactDoctorCard(
                    name: d.name,
                    specialty: d.specialty,
                    rating: d.rating,
                    imageUrl: d.imageUrl,
                    hospitalId: doctorData['hospitalId'] as String?,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCompactDoctorCard({
    required String name,
    required String specialty,
    required double rating,
    required String imageUrl,
    required String? hospitalId,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorDetailsScreen(
                  doctorName: name,
                  specialty: specialty,
                  rating: rating,
                  imageUrl: imageUrl,
                  reviewCount: 124,
                  hospitalId: hospitalId,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: Image.network(
                    imageUrl,
                    height: 44,
                    width: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 22,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  specialty,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}


class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final double maxHeight;
  final double minHeight;
  final Widget Function(BuildContext context, double t) builder;

  _HeaderDelegate({
    required this.maxHeight,
    required this.minHeight,
    required this.builder,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    return builder(context, t);
  }

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) {
    return oldDelegate.maxHeight != maxHeight ||
        oldDelegate.minHeight != minHeight;
  }
}