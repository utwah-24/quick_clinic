import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';
import 'screens/patient/home_screen.dart';
import 'screens/patient/hospitals_screen.dart';
import 'screens/patient/schedule_screen.dart';
import 'screens/patient/patient_profile_screen.dart';
import 'screens/patient/notification_screen.dart';
import 'screens/patient/emergency_screen.dart';
import 'screens/patient/register_screen.dart';
import 'screens/patient/login_screen.dart';
import 'screens/user_type_screen.dart';
import 'screens/doctor/doctor_home_screen.dart';
import 'screens/doctor/doctor_login_screen.dart';
import 'screens/doctor/doctor_register_screen.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/data_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Try to load environment variables
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      print('Warning: Could not load .env file: $e');
    }
    
    // Initialize services
    try {
      await LocationService.initialize();
      // Start periodic location updates for better accuracy
      await LocationService.startLocationUpdates();
    } catch (e) {
      print('LocationService initialization failed: $e');
    }
    
    try {
      await NotificationService.initialize();
    } catch (e) {
      print('NotificationService initialization failed: $e');
    }
    
    // Initialize user data from storage
    try {
      await DataService.loadUserFromStorage();
    } catch (e) {
      print('DataService initialization failed: $e');
    }
    
    runApp(MedicalBookingApp());
  } catch (e, stackTrace) {
    print('Fatal error during app initialization: $e');
    print('Stack trace: $stackTrace');
    // Still try to run the app even if initialization fails
    runApp(MedicalBookingApp());
  }
}

class MedicalBookingApp extends StatefulWidget {
  const MedicalBookingApp({super.key});

  @override
  _MedicalBookingAppState createState() => _MedicalBookingAppState();
}

class _MedicalBookingAppState extends State<MedicalBookingApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Clinic',
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        fontFamily: 'Lato',
        useMaterial3: false,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B2D5B)),
        primaryColor: const Color(0xFF0B2D5B),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B2D5B),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0B2D5B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/user-type': (context) => const UserTypeScreen(),
        '/home': (context) => HomeScreen(),
        '/hospitals': (context) => HospitalsScreen(),
        '/appointments': (context) => const ScheduleScreen(),
        '/profile': (context) => const PatientProfileScreen(),
        '/emergency': (context) => EmergencyScreen(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/doctor-home': (context) => const DoctorHomeScreen(),
        '/doctor-login': (context) => const DoctorLoginScreen(),
        '/doctor-register': (context) => const DoctorRegisterScreen(),
        '/notifications': (context) => const NotificationScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
