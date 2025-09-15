import 'package:flutter/material.dart';
import '../widgets/drawer.dart';
import 'hospitals_screen.dart';
import 'emergency_screen.dart';
import 'schedule_screen.dart';
import 'profile_screen.dart';
import 'location_permission_screen.dart';
import 'doctor_screen.dart';
import 'home_visit_screen.dart';
import '../services/location_service.dart';
import '../services/localization_service.dart';
import '../widgets/dynamic_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasLocationPermission = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  void _checkLocationPermission() {
    setState(() {
      _hasLocationPermission = LocationService.hasLocation;
    });
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
        return HospitalsScreen();
      case 2:
        return const ScheduleScreen();
      case 3:
        return const HomeVisitScreen();
      case 4:
        return ProfileScreen();
      default:
        return _buildHomeTab();
    }
  }

  // String _getCurrentTitle() {
  //   switch (_currentIndex) {
  //     case 0:
  //       return 'Quick Clinic';
  //     case 1:
  //       return 'Hospitals';
  //     case 2:
  //       return 'Appointments';
  //     case 3:
  //       return 'Home Visit';
  //     case 4:
  //       return 'Profile';
  //     default:
  //       return 'Quick Clinic';
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;
    if (!isWide) {
      // Mobile layout with bottom navigation
      return Scaffold(
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
            ? _buildBottomNavigationBar()
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
            child: const AppDrawer(
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
        color: Colors.blue[600],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              // color: Colors.blue[600],
              child: Column(
                children: [
                      DynamicAppBar(
                leading: Container(
                  width: 30,
                  child: Image.asset('assets/logo.png')),
                title: 'Quick Clinic',
                titleColor: Colors.white,
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.language,color: Colors.white,),
                    onSelected: (String languageCode) {
                      setState(() {
                        LocalizationService.setLanguage(languageCode);
                      });
                    },
                    itemBuilder: (BuildContext context) {
                      return LocalizationService.supportedLanguages.map((String code) {
                        return PopupMenuItem<String>(
                          value: code,
                          child: Text(LocalizationService.getLanguageName(code)),
                        );
                      }).toList();
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: _buildCategoriesSection(),
              ),
                ]
              ),
            ),
            
            // Content with padding
         
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
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
                    MaterialPageRoute(builder: (context) => HospitalsScreen()),
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
                    MaterialPageRoute(builder: (context) => EmergencyScreen()),
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
      {"label": "Pediatrician", "icon": Icons.vaccines},
      {"label": "Neurosurgeon", "icon": Icons.psychology_alt},
      {"label": "Cardiologist", "icon": Icons.monitor_heart},
      {"label": "Psychiatrist", "icon": Icons.psychology},
      {"label": "Dermatologist", "icon": Icons.health_and_safety},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const 
            Text(
              'Categories',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
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
            ),
            child: Icon(icon, color: const Color(0xFF1976D2), size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
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
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isWide ? 4 : 2,
          crossAxisSpacing: isSmallPhone ? 12 : 16,
          mainAxisSpacing: isSmallPhone ? 12 : 16,
          childAspectRatio: isWide ? 0.65 : (isSmallPhone ? 0.7 : 0.75),
          children: [
            _buildDoctorCard(
              name: 'Dr. Sarah Johnson',
              specialty: 'Cardiologist',
              rating: 4.9,
              imageUrl: 'https://picsum.photos/200',
              isSmallPhone: isSmallPhone,
            ),
            _buildDoctorCard(
              name: 'Dr. Michael Brown',
              specialty: 'Pediatrician',
              rating: 4.8,
              imageUrl: 'https://picsum.photos/201',
              isSmallPhone: isSmallPhone,
            ),
            _buildDoctorCard(
              name: 'Dr. Emily Davis',
              specialty: 'Dermatologist',
              rating: 4.9,
              imageUrl: 'https://picsum.photos/202',
              isSmallPhone: isSmallPhone,
            ),
            _buildDoctorCard(
              name: 'Dr. David Wilson',
              specialty: 'Neurologist',
              rating: 4.7,
              imageUrl: 'https://picsum.photos/203',
              isSmallPhone: isSmallPhone,
            ),
            if (isWide) ...[
              _buildDoctorCard(
                name: 'Dr. Lisa Chen',
                specialty: 'Orthopedic',
                rating: 4.8,
                imageUrl: 'https://picsum.photos/204',
                isSmallPhone: isSmallPhone,
              ),
              _buildDoctorCard(
                name: 'Dr. Robert Taylor',
                specialty: 'Psychiatrist',
                rating: 4.6,
                imageUrl: 'https://picsum.photos/205',
                isSmallPhone: isSmallPhone,
              ),
              _buildDoctorCard(
                name: 'Dr. Maria Garcia',
                specialty: 'Gynecologist',
                rating: 4.9,
                imageUrl: 'https://picsum.photos/206',
                isSmallPhone: isSmallPhone,
              ),
              _buildDoctorCard(
                name: 'Dr. James Anderson',
                specialty: 'Urologist',
                rating: 4.7,
                imageUrl: 'https://picsum.photos/207',
                isSmallPhone: isSmallPhone,
              ),
            ],
          ],
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
              _buildBottomNavItem(
                icon: Icons.person,
                label: 'Profile',
                isActive: _currentIndex == 4,
                onTap: () => _onBottomNavTap(4),
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
