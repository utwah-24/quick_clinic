import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class DirectionsService {
  /// Get route between two points
  static Future<RouteResult> getRoute({
    required LatLng start,
    required LatLng end,
    RouteProfile profile = RouteProfile.driving,
  }) async {
    try {
      // Calculate distance and create simple polyline
      final distance = _calculateDistance(start, end);
      final duration = _estimateDuration(distance, profile);
      
      return RouteResult(
        success: true,
        distance: distance,
        duration: duration,
        polyline: [
          start,
          end,
        ],
      );
    } catch (e) {
      debugPrint('Error getting route: $e');
      return RouteResult(
        success: false,
        distance: 0,
        duration: const Duration(seconds: 0),
        polyline: [],
      );
    }
  }
  
  /// Calculate distance between two points in kilometers using Haversine formula
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    final double dLat = _toRadians(point2.latitude - point1.latitude);
    final double dLon = _toRadians(point2.longitude - point1.longitude);
    
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(point1.latitude)) * 
        cos(_toRadians(point2.latitude)) * 
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
  
  /// Estimate travel duration based on distance and profile
  static Duration _estimateDuration(double distanceKm, RouteProfile profile) {
    double speedKmh;
    switch (profile) {
      case RouteProfile.walking:
        speedKmh = 5.0; // Average walking speed
        break;
      case RouteProfile.driving:
        speedKmh = 50.0; // Average driving speed in city
        break;
      case RouteProfile.cycling:
        speedKmh = 15.0; // Average cycling speed
        break;
    }
    
    // Convert to seconds (distance / speed * 3600)
    final int seconds = ((distanceKm / speedKmh) * 3600).round();
    return Duration(seconds: seconds);
  }
  
  /// Open directions in external map app (Google Maps, etc.)
  static Future<bool> openExternalDirections({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      final String url = 
          'https://www.google.com/maps/dir/${start.latitude},${start.longitude}/${end.latitude},${end.longitude}';
      
      final Uri uri = Uri.parse(url);
      
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error opening external directions: $e');
      return false;
    }
  }
}

class RouteResult {
  final bool success;
  final double distance; // in kilometers
  final Duration duration;
  final List<LatLng> polyline;
  
  RouteResult({
    required this.success,
    required this.distance,
    required this.duration,
    required this.polyline,
  });
  
  String get distanceFormatted {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }
  
  String get durationFormatted {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }
}

enum RouteProfile {
  walking,
  driving,
  cycling,
}

