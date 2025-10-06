import 'package:flutter/material.dart';
import '../../widgets/drawer.dart';
import 'hospitals_screen.dart';
import 'emergency_screen.dart';
import 'schedule_screen.dart';
import '../location_permission_screen.dart';
import '../doctor/doctor_screen.dart';
import 'home_visit_screen.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  bool _hasLocationPermission = false;
  int _currentIndex = 0;
  List<Doctor> _popularDoctors = [];
  bool _loadingDoctors = true;
  String? _doctorError;
  String _userName = 'User'; // Default fallback name

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadUserData();
  }

  void _loadUserData() {
    final user = DataService.getCurrentUser();
    if (user != null) {
      setState(() {
        _userName = user.name;
      });
    }
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
            blurRadius: 10,
            offset: const Offset(0, 2),
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
              'How you feeling 😊',
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
      setState(() {
        _popularDoctors = doctors;
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
        return const HospitalsScreen();
      case 2:
        return const ScheduleScreen();
      case 3:
        return const HomeVisitScreen();
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
            ? const AppDrawer(
                currentRoute: '/home',
                userName: 'John Doe',
                userEmail: 'john@example.com',
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
                  NavBarItem(icon: Icons.home, label: 'Home'),
                  NavBarItem(icon: Icons.local_hospital_outlined, label: 'Hospitals'),
                  NavBarItem(icon: Icons.assignment, label: 'Schedule'),
                  NavBarItem(icon: Icons.location_pin, label: 'Home Visit'),
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
          const SizedBox(
            width: 280,
            child: AppDrawer(
              currentRoute: '/home',
              userName: 'John Doe',
              userEmail: 'john@example.com',
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
                        _userName,
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
    return 
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 120,
              width:120,
              child: _buildModernQuickActionCard(
                icon: Icons.local_hospital_rounded,
                title: LocalizationService.translate('find_hospitals'),
                // subtitle: 'Browse nearby hospitals',
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
            const SizedBox(width: 20),
            Container(
              height: 120,
              width:120,
              child: _buildModernQuickActionCard(
                icon: Icons.emergency_rounded,
                title: LocalizationService.translate('emergency'),
                // subtitle: 'Emergency services',
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
    required IconData icon,
    required String title,
    // required String subtitle,
    required Color color,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
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
                    color: Colors.white.withValues(alpha: 0.2),
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
                    // letterSpacing: ,
                  ),
                  textAlign: TextAlign.center,
                ),
                // const SizedBox(height: 1),
               
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
      // decoration: BoxDecoration(
      //   color: const Color(0xFFF2F6FB),
      //   borderRadius: BorderRadius.circular(16),
      //   border: Border.all(color: Colors.grey[200]!),
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.black.withValues(alpha: 0.04),
      //       blurRadius: 8,
      //       offset: const Offset(0, 4),
      //     ),
      //   ],
      // ),
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
            color: const Color(0xFF1976D2).withValues(alpha: 0.15),
            blurRadius: 8,
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
              final d = _popularDoctors[index];
              return _buildDoctorCard(
                name: d.name,
                specialty: d.specialty,
                rating: d.rating,
                imageUrl: d.imageUrl,
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
                builder: (context) => DoctorScreen(
                  doctorName: name,
                  specialty: specialty,
                  rating: rating,
                  imageUrl: imageUrl,
                  reviewCount: 124,
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


  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                icon: Icons.home,
                label: 'Home',
                isActive: _currentIndex == 0,
                onTap: () => _onBottomNavTap(0),
              ),
              _buildBottomNavItem(
                icon: Icons.local_hospital_outlined,
                label: 'Hospitals',
                isActive: _currentIndex == 1,
                onTap: () => _onBottomNavTap(1),
              ),
              _buildBottomNavItem(
                icon: Icons.assignment,
                label: 'Schedule',
                isActive: _currentIndex == 2,
                onTap: () => _onBottomNavTap(2),
              ),
              _buildBottomNavItem(
                icon: Icons.location_pin,
                label: 'Home Visit',
                isActive: _currentIndex == 3,
                onTap: () => _onBottomNavTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: isActive ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2196F3) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? Colors.white : Colors.grey[600],
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
