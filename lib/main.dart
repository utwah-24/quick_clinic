import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/hospitals_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/user_type_screen.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';

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
    } catch (e) {
      print('LocationService initialization failed: $e');
    }
    
    try {
      await NotificationService.initialize();
    } catch (e) {
      print('NotificationService initialization failed: $e');
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
        useMaterial3: false,
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1976D2),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1976D2),
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
            backgroundColor: const Color(0xFF1976D2),
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
        '/profile': (context) => ProfileScreen(),
        '/emergency': (context) => EmergencyScreen(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
