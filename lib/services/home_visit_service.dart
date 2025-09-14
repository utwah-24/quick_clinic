import 'dart:math';
import '../models/home_visit.dart';
import '../models/home_visit_booking.dart';

class HomeVisitService {
  // Mock data for demonstration - in real app, this would come from API
  static final List<HomeVisit> _mockHomeVisits = [
    HomeVisit(
      id: '1',
      providerId: 'doc1',
      providerName: 'Dr. Sarah Mwangi',
      providerType: 'doctor',
      specialty: 'General Medicine',
      providerImageUrl: 'assets/doctor1.jpg',
      rating: 4.8,
      reviewCount: 127,
      price: 2500.0,
      currency: 'TZS',
      location: 'Mikocheni, Dar es Salaam',
      latitude: -6.8235,
      longitude: 39.2695,
      estimatedTravelTime: 25,
      availableDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
      availableTimeSlots: ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'],
      isAvailable: true,
      description: 'Experienced general practitioner available for home visits. Specializes in elderly care and basic diagnosis.',
      services: ['diagnosis', 'prescription', 'basic care', 'elderly care'],
      acceptsInsurance: true,
      createdAt: DateTime.now(),
    ),
    HomeVisit(
      id: '2',
      providerId: 'nurse1',
      providerName: 'Nurse Grace Wanjiku',
      providerType: 'nurse',
      specialty: 'Home Care Nursing',
      providerImageUrl: 'assets/nurse1.jpg',
      rating: 4.9,
      reviewCount: 89,
      price: 1500.0,
      currency: 'TZS',
      location: 'Masaki, Dar es Salaam',
      latitude: -6.7924,
      longitude: 39.2083,
      estimatedTravelTime: 20,
      availableDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'],
      availableTimeSlots: ['08:00', '09:00', '10:00', '11:00', '14:00', '15:00', '16:00'],
      isAvailable: true,
      description: 'Registered nurse with 8 years experience in home care. Available for wound care, medication administration, and basic health checks.',
      services: ['wound care', 'medication administration', 'health checks', 'elderly care'],
      acceptsInsurance: false,
      createdAt: DateTime.now(),
    ),
    HomeVisit(
      id: '3',
      providerId: 'doc2',
      providerName: 'Dr. James Kamau',
      providerType: 'doctor',
      specialty: 'Pediatrics',
      providerImageUrl: 'assets/doctor2.jpg',
      rating: 4.7,
      reviewCount: 156,
      price: 3000.0,
      currency: 'TZS',
      location: 'Oyster Bay, Dar es Salaam',
      latitude: -6.7735,
      longitude: 39.2695,
      estimatedTravelTime: 30,
      availableDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
      availableTimeSlots: ['10:00', '11:00', '14:00', '15:00', '16:00'],
      isAvailable: true,
      description: 'Pediatrician available for home visits. Specializes in child health and development.',
      services: ['child diagnosis', 'vaccination', 'growth monitoring', 'health education'],
      acceptsInsurance: true,
      createdAt: DateTime.now(),
    ),
    HomeVisit(
      id: '4',
      providerId: 'nurse2',
      providerName: 'Nurse Mary Njeri',
      providerType: 'nurse',
      specialty: 'Elderly Care',
      providerImageUrl: 'assets/nurse2.jpg',
      rating: 4.6,
      reviewCount: 67,
      price: 1200.0,
      currency: 'TZS',
      location: 'Mbezi Beach, Dar es Salaam',
      latitude: -6.7200,
      longitude: 39.2200,
      estimatedTravelTime: 35,
      availableDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
      availableTimeSlots: ['08:00', '09:00', '10:00', '11:00', '14:00', '15:00', '16:00', '17:00'],
      isAvailable: true,
      description: 'Specialized in elderly care and chronic disease management. Available 7 days a week.',
      services: ['elderly care', 'chronic disease management', 'medication management', 'health monitoring'],
      acceptsInsurance: false,
      createdAt: DateTime.now(),
    ),
  ];

  // Get all available home visits
  static Future<List<HomeVisit>> getAvailableHomeVisits() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockHomeVisits.where((visit) => visit.isAvailable).toList();
  }

  // Get home visits filtered by location and criteria
  static Future<List<HomeVisit>> searchHomeVisits({
    String? providerType,
    String? specialty,
    double? maxPrice,
    String? availableDay,
    String? availableTime,
    double? userLatitude,
    double? userLongitude,
    double? maxDistance, // in kilometers
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    List<HomeVisit> filteredVisits = _mockHomeVisits.where((visit) {
      // Filter by provider type
      if (providerType != null && visit.providerType != providerType) {
        return false;
      }
      
      // Filter by specialty
      if (specialty != null && !visit.specialty.toLowerCase().contains(specialty.toLowerCase())) {
        return false;
      }
      
      // Filter by max price
      if (maxPrice != null && visit.price > maxPrice) {
        return false;
      }
      
      // Filter by available day
      if (availableDay != null && !visit.availableDays.contains(availableDay.toLowerCase())) {
        return false;
      }
      
      // Filter by available time
      if (availableTime != null && !visit.availableTimeSlots.contains(availableTime)) {
        return false;
      }
      
      // Filter by distance if coordinates provided
      if (userLatitude != null && userLongitude != null && maxDistance != null) {
        double distance = _calculateDistance(
          userLatitude, 
          userLongitude, 
          visit.latitude, 
          visit.longitude
        );
        if (distance > maxDistance) {
          return false;
        }
      }
      
      return visit.isAvailable;
    }).toList();
    
    // Sort by rating (highest first)
    filteredVisits.sort((a, b) => b.rating.compareTo(a.rating));
    
    return filteredVisits;
  }

  // Calculate distance between two points using Haversine formula
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        sin(lat1 * pi / 180) * sin(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Book a home visit
  static Future<HomeVisitBooking> bookHomeVisit({
    required String homeVisitId,
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String patientAddress,
    required double patientLatitude,
    required double patientLongitude,
    required DateTime scheduledDate,
    required String timeSlot,
    required String visitReason,
    required String symptoms,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Find the home visit
    final homeVisit = _mockHomeVisits.firstWhere((visit) => visit.id == homeVisitId);
    
    // Create booking
    final booking = HomeVisitBooking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      homeVisitId: homeVisitId,
      providerId: homeVisit.providerId,
      providerName: homeVisit.providerName,
      providerType: homeVisit.providerType,
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      patientAddress: patientAddress,
      patientLatitude: patientLatitude,
      patientLongitude: patientLongitude,
      scheduledDate: scheduledDate,
      timeSlot: timeSlot,
      visitReason: visitReason,
      symptoms: symptoms,
      amount: homeVisit.price,
      currency: homeVisit.currency,
      status: BookingStatus.pending,
      paymentStatus: PaymentStatus.pending,
      createdAt: DateTime.now(),
    );
    
    return booking;
  }

  // Get user's home visit bookings
  static Future<List<HomeVisitBooking>> getUserBookings(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Mock user bookings - in real app, this would come from API
    return [
      HomeVisitBooking(
        id: '1',
        homeVisitId: '1',
        providerId: 'doc1',
        providerName: 'Dr. Sarah Mwangi',
        providerType: 'doctor',
        patientId: userId,
        patientName: 'John Doe',
        patientPhone: '+255700000000',
        patientAddress: 'Mikocheni, Dar es Salaam',
        patientLatitude: -6.8235,
        patientLongitude: 39.2695,
        scheduledDate: DateTime.now().add(const Duration(days: 2)),
        timeSlot: '10:00',
        visitReason: 'Regular checkup',
        symptoms: 'None',
        amount: 2500.0,
        currency: 'KES',
        status: BookingStatus.confirmed,
        paymentStatus: PaymentStatus.paid,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
