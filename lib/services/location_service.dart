import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static double? _currentLatitude;
  static double? _currentLongitude;
  static Timer? _locationUpdateTimer;
  static StreamSubscription<Position>? _positionStreamSubscription;
  static bool _isManualOverride = false;
  static const double _tzFallbackLat = -6.7924; // Masaki, Dar es Salaam
  static const double _tzFallbackLon = 39.2083;
  static bool get _validateLocation => kReleaseMode; // Validate only in release builds

  static Future<void> initialize() async {
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
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 30),
          distanceFilter: 0,
        ),
        forceAndroidLocationManager: false,
      );
      
      final double lat = position.latitude;
      final double lon = position.longitude;

      final bool looksLikeEmulator = _looksLikeEmulatorDefault(lat, lon);
      final bool inTanzania = _isWithinTanzania(lat, lon);

      if (!_validateLocation || (!looksLikeEmulator && inTanzania)) {
        _currentLatitude = lat;
        _currentLongitude = lon;
        print('✅ Location obtained: $_currentLatitude, $_currentLongitude');
        print('📍 Location details:');
        print('   - Latitude: $_currentLatitude');
        print('   - Longitude: $_currentLongitude');
        print('   - Accuracy: ${position.accuracy}m');
        print('   - Timestamp: ${position.timestamp}');
        print('   - Speed: ${position.speed}m/s');
        print('   - Altitude: ${position.altitude}m');
        return LocationResult(
          success: true,
          latitude: _currentLatitude!,
          longitude: _currentLongitude!,
          message: 'Location obtained successfully (accuracy: ${position.accuracy}m)',
        );
      }

      // Retry with GPS-only if invalid or emulator default
      if (!_validateLocation) {
        // In debug/emulator, accept whatever the OS returns to unblock the flow
        _currentLatitude = lat;
        _currentLongitude = lon;
        print('ℹ️ Debug mode: accepting OS location $lat,$lon');
        return LocationResult(
          success: true,
          latitude: _currentLatitude!,
          longitude: _currentLongitude!,
          message: 'Debug mode location accepted (accuracy: ${position.accuracy}m)',
        );
      }

      print('⚠️ First fix invalid (looksLikeEmulator=$looksLikeEmulator, inTanzania=$inTanzania). Retrying with GPS only...');
      final gpsPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 45),
          distanceFilter: 0,
        ),
        forceAndroidLocationManager: true,
      );
      final double gpsLat = gpsPosition.latitude;
      final double gpsLon = gpsPosition.longitude;
      final bool gpsOk = !_looksLikeEmulatorDefault(gpsLat, gpsLon) && _isWithinTanzania(gpsLat, gpsLon);
      if (gpsOk || !_validateLocation) {
        _currentLatitude = gpsLat;
        _currentLongitude = gpsLon;
        print('✅ GPS retry accepted: $_currentLatitude, $_currentLongitude (accuracy: ${gpsPosition.accuracy}m)');
        return LocationResult(
          success: true,
          latitude: _currentLatitude!,
          longitude: _currentLongitude!,
          message: 'GPS fix obtained (accuracy: ${gpsPosition.accuracy}m)',
        );
      }

      print('❌ GPS retry still invalid. Not caching invalid coordinates.');
      return LocationResult(
        success: false,
        latitude: _tzFallbackLat,
        longitude: _tzFallbackLon,
        message: 'Device returned invalid location. Ensure precise GPS is ON or use Tanzania override.',
      );
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

  static bool _looksLikeEmulatorDefault(double lat, double lon) {
    return (lat - 37.4219983).abs() < 0.001 && (lon + 122.084).abs() < 0.01;
  }

  static bool _isWithinTanzania(double lat, double lon) {
    return lat >= -12 && lat <= -1 && lon >= 29 && lon <= 41;
  }

  static Future<LocationResult> refreshLocation() async {
    // Clear cached location to force fresh location
    _currentLatitude = null;
    _currentLongitude = null;
    return await getCurrentLocation();
  }

  static Future<LocationResult> forceLocationReset() async {
    print('🔄 Force resetting location cache...');
    
    // Stop any ongoing location updates
    stopLocationUpdates();
    
    // Clear all cached data
    _currentLatitude = null;
    _currentLongitude = null;
    
    // Wait a moment for GPS to reset
    await Future.delayed(const Duration(seconds: 2));
    
    // Force fresh location with high accuracy
    try {
      print('📍 Requesting fresh location after reset...');
      
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
      
      // Use best possible accuracy settings
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 45),
          distanceFilter: 0,
        ),
        forceAndroidLocationManager: true, // Force GPS
      );
      
      final double lat = position.latitude;
      final double lon = position.longitude;

      final bool looksLikeEmulator = _looksLikeEmulatorDefault(lat, lon);
      final bool inTanzania = _isWithinTanzania(lat, lon);

      if (!_validateLocation || (!looksLikeEmulator && inTanzania)) {
        _currentLatitude = lat;
        _currentLongitude = lon;
      }

      print('✅ Fresh location obtained: ' + lat.toString() + ', ' + lon.toString());
      print('📍 Fresh location details:');
      print('   - Latitude: ' + lat.toString());
      print('   - Longitude: ' + lon.toString());
      print('   - Accuracy: ${position.accuracy}m');
      print('   - Timestamp: ${position.timestamp}');
      
      // Validate coordinates are reasonable for Tanzania
      if (_validateLocation && !inTanzania) {
        print('⚠️ WARNING: Fresh coordinates still seem outside Tanzania range!');
        print('   Expected: Lat -12 to -1, Lon 29 to 41');
        print('   Got: Lat ' + lat.toString() + ', Lon ' + lon.toString());
        print('   This might indicate GPS/device issues or incorrect location settings');
      }
      
      if (!_validateLocation || (!looksLikeEmulator && inTanzania)) {
        return LocationResult(
          success: true,
          latitude: _currentLatitude!,
          longitude: _currentLongitude!,
          message: 'Fresh location obtained (accuracy: ${position.accuracy}m)',
        );
      }

      return LocationResult(
        success: false,
        latitude: _tzFallbackLat,
        longitude: _tzFallbackLon,
        message: 'Fresh fix invalid. Ensure GPS is ON or use Tanzania override.',
      );
    } catch (e) {
      print('❌ Fresh location error: $e');
      return LocationResult(
        success: false,
        latitude: 0.0,
        longitude: 0.0,
        message: 'Failed to get fresh location: $e',
      );
    }
  }

  static Future<LocationResult> getLocationWithTimeout({Duration timeout = const Duration(seconds: 15)}) async {
    try {
      print('📍 Requesting location with timeout: ${timeout.inSeconds}s');
      
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
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: timeout,
          distanceFilter: 0,
        ),
        forceAndroidLocationManager: false,
      );
      final double lat = position.latitude;
      final double lon = position.longitude;
      final bool looksLikeEmulator = _looksLikeEmulatorDefault(lat, lon);
      final bool inTanzania = _isWithinTanzania(lat, lon);

      if (!_validateLocation || (!looksLikeEmulator && inTanzania)) {
        _currentLatitude = lat;
        _currentLongitude = lon;
        print('✅ Precise location obtained: $_currentLatitude, $_currentLongitude (accuracy: ${position.accuracy}m)');
        return LocationResult(
          success: true,
          latitude: _currentLatitude!,
          longitude: _currentLongitude!,
          message: 'Location obtained successfully (accuracy: ${position.accuracy}m)',
        );
      }

      if (!_validateLocation) {
        _currentLatitude = lat;
        _currentLongitude = lon;
        print('ℹ️ Debug mode: accepting OS location $lat,$lon');
        return LocationResult(
          success: true,
          latitude: _currentLatitude!,
          longitude: _currentLongitude!,
          message: 'Debug mode location accepted (accuracy: ${position.accuracy}m)',
        );
      }

      print('⚠️ Invalid fix (looksLikeEmulator=$looksLikeEmulator, inTanzania=$inTanzania). Retrying with GPS-only...');
      final gpsPosition = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: timeout + const Duration(seconds: 15),
          distanceFilter: 0,
        ),
        forceAndroidLocationManager: true,
      );
      final double gpsLat = gpsPosition.latitude;
      final double gpsLon = gpsPosition.longitude;
      final bool gpsOk = !_looksLikeEmulatorDefault(gpsLat, gpsLon) && _isWithinTanzania(gpsLat, gpsLon);
      if (gpsOk || !_validateLocation) {
        _currentLatitude = gpsLat;
        _currentLongitude = gpsLon;
        print('✅ GPS-only precise location: $_currentLatitude, $_currentLongitude (accuracy: ${gpsPosition.accuracy}m)');
        return LocationResult(
          success: true,
          latitude: _currentLatitude!,
          longitude: _currentLongitude!,
          message: 'GPS fix obtained (accuracy: ${gpsPosition.accuracy}m)',
        );
      }

      return LocationResult(
        success: false,
        latitude: _tzFallbackLat,
        longitude: _tzFallbackLon,
        message: 'Invalid device location. Turn on precise GPS or use Tanzania override.',
      );
    } catch (e) {
      print('❌ Location error: $e');
      return LocationResult(
        success: false,
        latitude: 0.0,
        longitude: 0.0,
        message: 'Location access denied or unavailable: $e',
      );
    }
  }

  static Future<void> startLocationUpdates({Duration interval = const Duration(minutes: 2)}) async {
    try {
      // Check permissions first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        print('❌ Location permission denied');
        return;
      }

      // Start listening to position changes
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 10, // Update when moved 10 meters
        ),
      ).listen(
        (Position position) {
          final double lat = position.latitude;
          final double lon = position.longitude;
          if (!_validateLocation || (!_looksLikeEmulatorDefault(lat, lon) && _isWithinTanzania(lat, lon))) {
            _currentLatitude = lat;
            _currentLongitude = lon;
            print('📍 Location updated: $_currentLatitude, $_currentLongitude (accuracy: ${position.accuracy}m)');
          } else {
            print('⚠️ Ignoring invalid stream fix: ' + lat.toString() + ',' + lon.toString());
          }
        },
        onError: (error) {
          print('❌ Location stream error: $error');
        },
      );

      print('✅ Started location updates with ${interval.inMinutes} minute interval');
    } catch (e) {
      print('❌ Failed to start location updates: $e');
    }
  }

  static void stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    print('✅ Stopped location updates');
  }

  static void dispose() {
    stopLocationUpdates();
  }

  // Manual override for Tanzania location when GPS is incorrect
  static Future<LocationResult> setManualTanzaniaLocation() async {
    print('🇹🇿 Setting manual Tanzania location (Masaki, Dar es Salaam)...');
    
    // Masaki, Dar es Salaam coordinates
    _currentLatitude = -6.7924;
    _currentLongitude = 39.2083;
    _isManualOverride = true;
    
    print('✅ Manual Tanzania location set: $_currentLatitude, $_currentLongitude');
    
    return LocationResult(
      success: true,
      latitude: _currentLatitude!,
      longitude: _currentLongitude!,
      message: 'Manual Tanzania location set (Masaki, Dar es Salaam)',
    );
  }

  // Clear manual override and try GPS again
  static Future<LocationResult> clearManualOverride() async {
    print('🔄 Clearing manual override, trying GPS again...');
    _isManualOverride = false;
    _currentLatitude = null;
    _currentLongitude = null;
    
    // Try to get fresh GPS location
    return await forceLocationReset();
  }

  // Get device location diagnostics
  static Future<Map<String, dynamic>> getLocationDiagnostics() async {
    Map<String, dynamic> diagnostics = {};
    
    try {
      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      diagnostics['locationServiceEnabled'] = serviceEnabled;
      
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      diagnostics['permission'] = permission.toString();
      
      // Get last known position
      try {
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          diagnostics['lastKnownPosition'] = {
            'latitude': lastPosition.latitude,
            'longitude': lastPosition.longitude,
            'accuracy': lastPosition.accuracy,
            'timestamp': lastPosition.timestamp.toString(),
          };
        } else {
          diagnostics['lastKnownPosition'] = 'No last known position';
        }
      } catch (e) {
        diagnostics['lastKnownPosition'] = 'Error: $e';
      }
      
      // Check if coordinates are reasonable for Tanzania
      if (_currentLatitude != null && _currentLongitude != null) {
        bool isInTanzania = _currentLatitude! >= -12 && _currentLatitude! <= -1 && 
                           _currentLongitude! >= 29 && _currentLongitude! <= 41;
        diagnostics['isInTanzania'] = isInTanzania;
        diagnostics['currentLocation'] = {
          'latitude': _currentLatitude,
          'longitude': _currentLongitude,
          'isManualOverride': _isManualOverride,
        };
      }
      
      diagnostics['isManualOverride'] = _isManualOverride;
      
    } catch (e) {
      diagnostics['error'] = e.toString();
    }
    
    return diagnostics;
  }

  static bool get hasLocation => _currentLatitude != null && _currentLongitude != null;
  static bool get isManualOverride => _isManualOverride;
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
