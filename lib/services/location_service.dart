import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

class LocationService {
  static bool _isInitialized = false;
  static double? _currentLatitude;
  static double? _currentLongitude;

  static Future<void> initialize() async {
    _isInitialized = true;
    print('✅ Location Service initialized');
  }

  static Future<LocationResult> getCurrentLocation() async {
    try {
      print('📍 Requesting location permission...');
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          success: false,
          latitude: 0.0,
          longitude: 0.0,
          message: 'Location services are disabled',
        );
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return LocationResult(
          success: false,
          latitude: 0.0,
          longitude: 0.0,
          message: 'Location permission denied',
        );
      }
      
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;
      
      if (_currentLatitude != null && _currentLongitude != null) {
        print('✅ Location obtained: $_currentLatitude, $_currentLongitude');
        return LocationResult(
          success: true,
          latitude: _currentLatitude!,
          longitude: _currentLongitude!,
          message: 'Location obtained successfully',
        );
      } else {
        throw Exception('Could not get coordinates');
      }
    } catch (e) {
      print('❌ Location error: $e');
      return LocationResult(
        success: false,
        latitude: 0.0,
        longitude: 0.0,
        message: 'Location access denied or unavailable',
      );
    }
  }

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Simple distance calculation (in km)
    const double earthRadius = 6371;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);
    double a = sinDLat * sinDLat +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * sinDLon * sinDLon;
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  static bool get hasLocation => _currentLatitude != null && _currentLongitude != null;
  static double? get currentLatitude => _currentLatitude;
  static double? get currentLongitude => _currentLongitude;
}

class LocationResult {
  final bool success;
  final double latitude;
  final double longitude;
  final String message;

  LocationResult({
    required this.success,
    required this.latitude,
    required this.longitude,
    required this.message,
  });
}
