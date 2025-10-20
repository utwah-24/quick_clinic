import 'package:flutter/material.dart';
import '../../widgets/drawer.dart';
import 'hospitals_screen.dart';
import 'emergency_screen.dart';
import 'schedule_screen.dart';
import '../location_permission_screen.dart';
import '../doctor/doctor_screen.dart';
import 'home_visit_screen.dart';
import 'explore_screen.dart';
import 'category_hospitals_screen.dart';
import 'notification_screen.dart';
import 'doctor_details_screen.dart';
import '../../services/location_service.dart';
import '../../services/localization_service.dart';
import '../../widgets/dynamic_app_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../services/data_service.dart';
import '../../models/hospital.dart';
import '../../models/hospital.dart' show Doctor;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _hasLocationPermission = false;
  int _currentIndex = 0;
  List<Doctor> _popularDoctors = [];
  List<Map<String, dynamic>> _popularDoctorsWithHospital = [];
  bool _loadingDoctors = true;
  String? _doctorError;
  String _userName = 'User'; // Default fallback name
  String _userEmail = 'user@example.com'; // Default fallback email
  String? _userAvatar; // User profile image URL
  
  // Animation controllers for scroll-based header animation
  late ScrollController _scrollController;
  late AnimationController _headerAnimationController;
  double _headerScale = 1.0; // Original scale
  DateTime _lastScrollUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Add scroll listener
    _scrollController.addListener(_onScroll);
    
    _checkLocationPermission();
    _initializeUserData();
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

  @override
  void dispose() {
    _scrollController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final now = DateTime.now();
    
    // Throttle updates to max 60fps (16ms intervals)
    if (now.difference(_lastScrollUpdate).inMilliseconds < 16) {
      return;
    }
    _lastScrollUpdate = now;
    
    final scrollOffset = _scrollController.offset;
    const maxScrollOffset = 200.0; // Adjust this value to control when animation completes
    
    // Calculate animation progress (0.0 to 1.0)
    final animationProgress = (scrollOffset / maxScrollOffset).clamp(0.0, 1.0);
    
    // Update header scale based on scroll position
    final newScale = 1.0 - (0.4 * animationProgress); // Scale from 1.0 to 0.6 for more dramatic effect
    
    // Only update if the scale has changed significantly to reduce rebuilds
    if ((_headerScale - newScale).abs() > 0.01) {
      _headerScale = newScale;
      _headerAnimationController.value = animationProgress;
    }
  }

  Widget _buildUpcomingSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with count badge and See All
       
        // const SizedBox(height: 16),
        
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
               Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Upcoming Schedule',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '8',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScheduleScreen()),
                );
              },
              child: const Text(
                'See All',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black ,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
              // Doctor Info Section
              Row(
                children: [
                  // Doctor Profile Picture
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icons/doctor.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 30,
                              color: Color(0xFF1976D2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Doctor Details
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. Alana Rueter',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black ,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Dentist Consultation',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Call Icon
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
            ]
                    ),
                    child: const Icon(
                      Icons.phone,
                      color: Color.fromARGB(255, 0, 0, 0),
                      size: 20,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              
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
                 const  Expanded(
                    child: Row(
                      children: [
                         Icon(
                          Icons.calendar_today,
                          color: Colors.black,
                          size: 16,
                        ),
                         SizedBox(width: 8),
                         Text(
                          'Monday, 26 July',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Vertical Divider
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Time
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.black,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '09:00 - 10:00',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
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
        _popularDoctors = doctors;
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
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
         case 1:
        return const ExploreScreen();
      case 2:
        return const HospitalsScreen();
      case 3:
        return const ScheduleScreen();
      // case 4:
      //   return const HomeVisitScreen();
      default:
        return _buildHomeTab();
    }
  }

 

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;
    if (!isWide) {
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
                  NavBarItem(icon: 'assets/icons/explore.png', label: 'Explore'),
                  NavBarItem(icon: 'assets/icons/hospitals.png', label: 'Hospitals'),
                  NavBarItem(icon: 'assets/icons/schedule.png', label: 'Schedule'),
                  // NavBarItem(icon: Icons.location_pin, label: 'Home Visit'),
                ],
              )
            : null,
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
              key: ValueKey('$_userName-$_userEmail'), // Force rebuild when user data changes
              currentRoute: '/home',
              userName: _userName,
              userEmail: _userEmail,
              userAvatar: _userAvatar,
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(

                constraints: const BoxConstraints(maxWidth: 1200),
                child: Container(child: _buildHomeTab()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[800]!, Colors.blue[400]!],
          ),
        ),
        // color: Colors.blue[600],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: _headerAnimationController,
              builder: (context, animationValue, child) {
                // Calculate the vanishing point effect
                final scale = _headerScale;
                // Make content disappear completely when scale reaches 0.6
                final opacity = scale > 0.6 ? 1.0 : (scale - 0.2) / 0.4; // Scale from 0.2 to 0.6 maps to 0.0 to 1.0
                final clampedOpacity = opacity.clamp(0.0, 1.0);
                
                // Calculate translate offset to create vanishing point effect
                // As content shrinks, it moves towards the center of the screen
                final screenHeight = MediaQuery.of(context).size.height;
                final translateY = (1.0 - scale) * screenHeight * 0.1; // Move towards center
                
                return Transform.translate(
                  offset: Offset(0, translateY),
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.center, // Scale from center for vanishing effect
                    child: Opacity(
                      opacity: clampedOpacity,
                      child: Column(
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const NotificationScreen(),
                                    ),
                                  );
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
                                    _userName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildUpcomingSchedule(),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Content with padding
         
              ClipRRect(
                borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40), 
                topRight: Radius.circular(40)
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white ,
                  
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
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
            
          ],
        ),
      ),
    );
  }



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
            color: Colors.blue[600]!,
            gradient: [Colors.blue[400]!, Colors.blue[600]!],
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
            color: Colors.red[600]!,
            gradient: [Colors.red[400]!, Colors.red[600]!],
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
        const 
            Text(
              'Categories',
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
    final isWide = MediaQuery.of(context).size.width >= 1000;
    final isSmallPhone = MediaQuery.of(context).size.width < 400;

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
        Text(
          'Meet our top-rated healthcare professionals',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),
        if (_popularDoctors.isEmpty)
          Text('No popular doctors found', style: TextStyle(color: Colors.grey[600]))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: isSmallPhone ? 12 : 16,
              mainAxisSpacing: isSmallPhone ? 12 : 16,
              childAspectRatio: isWide ? 0.65 : (isSmallPhone ? 0.7 : 0.75),
            ),
            itemCount: _popularDoctors.length,
            itemBuilder: (context, index) {
              final doctorData = _popularDoctorsWithHospital[index];
              final d = doctorData['doctor'] as Doctor;
              return _buildDoctorCard(
                name: d.name,
                specialty: d.specialty,
                rating: d.rating,
                imageUrl: d.imageUrl,
                hospitalId: doctorData['hospitalId'] as String?,
                isSmallPhone: isSmallPhone,
              );
            },
          ),
      ],
    );
  }

  Widget _buildDoctorCard({
    required String name,
    required String specialty,
    required double rating,
    required String imageUrl,
    required String? hospitalId,
    required bool isSmallPhone,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
            padding: EdgeInsets.all(isSmallPhone ? 8 : 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Doctor Image
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      imageUrl,
                      height: isSmallPhone ? 50 : 60,
                      width: isSmallPhone ? 50 : 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: isSmallPhone ? 50 : 60,
                          width: isSmallPhone ? 50 : 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            size: isSmallPhone ? 25 : 30,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: isSmallPhone ? 6 : 8),
                
                // Doctor Name
                Text(
                  name,
                  style: TextStyle(
                    fontSize: isSmallPhone ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: isSmallPhone ? 1 : 2),
                
                // Specialty
                Text(
                  specialty,
                  style: TextStyle(
                    fontSize: isSmallPhone ? 14 : 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: isSmallPhone ? 4 : 6),
                
                // Rating
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallPhone ? 6 : 8, 
                    vertical: isSmallPhone ? 3 : 4
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(isSmallPhone ? 10 : 12),
                    border: Border.all(
                      color: Colors.orange[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: isSmallPhone ? 14 : 16,
                        color: Colors.orange[600],
                      ),
                      SizedBox(width: isSmallPhone ? 2 : 3),
                                              Text(
                          rating.toString(),
                          style: TextStyle(
                            fontSize: isSmallPhone ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                    ],
                  ),
                ),
                
                SizedBox(height: isSmallPhone ? 4 : 6),
                
                // Book Appointment Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to booking
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallPhone ? 2 : 4
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isSmallPhone ? 8 : 10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isSmallPhone ? 'Book' : 'Book',
                      style: TextStyle(
                        fontSize: isSmallPhone ? 12 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



}

