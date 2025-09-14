import '../models/hospital.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import 'location_service.dart';

class DataService {
  // Mock data - replace with real API calls later
  static final List<Hospital> _hospitals = [
    Hospital(
      id: 'h1',
      name: 'Muhimbili National Hospital',
      address: 'United Nations Rd, Dar es Salaam',
      latitude: -6.8000,
      longitude: 39.2847,
      distance: 0.0,
      specialties: ['General', 'Cardiology', 'Ophthalmology', 'Emergency'],
      rating: 4.5,
      phoneNumber: '+255-22-2151591',
      hasEmergency: true,
      imageUrl: 'https://picsum.photos/300/200',
      doctors: [
        Doctor(
          id: 'd1',
          name: 'Dr. John Mwakalinga',
          specialty: 'General Medicine',
          qualification: 'MBBS, MD',
          experience: 10,
          rating: 4.7,
          imageUrl: 'https://picsum.photos/150',
          availableDays: ['Monday', 'Tuesday', 'Wednesday', 'Friday'],
          availableTime: '9:00 AM - 5:00 PM',
          consultationFee: 30000.0, // TZS
          bio: 'Experienced general practitioner with 10 years of practice.',
          languages: ['English', 'Kiswahili'],
        ),
        Doctor(
          id: 'd2',
          name: 'Dr. Sarah Mushi',
          specialty: 'Ophthalmology',
          qualification: 'MBBS, MS (Ophthalmology)',
          experience: 8,
          rating: 4.8,
          imageUrl: 'https://picsum.photos/151',
          availableDays: ['Tuesday', 'Thursday', 'Saturday'],
          availableTime: '10:00 AM - 4:00 PM',
          consultationFee: 45000.0, // TZS
          bio: 'Specialist in eye care and vision correction.',
          languages: ['English', 'Kiswahili'],
        ),
        Doctor(
          id: 'd3',
          name: 'Dr. Michael Mbwana',
          specialty: 'Cardiology',
          qualification: 'MBBS, MD (Cardiology)',
          experience: 15,
          rating: 4.9,
          imageUrl: 'https://picsum.photos/152',
          availableDays: ['Monday', 'Wednesday', 'Friday'],
          availableTime: '8:00 AM - 3:00 PM',
          consultationFee: 70000.0, // TZS
          bio: 'Leading cardiologist with expertise in heart diseases.',
          languages: ['English', 'Kiswahili'],
        ),
      ],
    ),
    Hospital(
      id: 'h2',
      name: 'Aga Khan Hospital Dar es Salaam',
      address: 'Ocean Rd, Dar es Salaam',
      latitude: -6.7890,
      longitude: 39.2740,
      distance: 0.0,
      specialties: ['General', 'Emergency', 'Surgery', 'Pediatrics'],
      rating: 4.3,
      phoneNumber: '+255-22-2115151',
      hasEmergency: true,
      imageUrl: 'https://picsum.photos/301/200',
      doctors: [
        Doctor(
          id: 'd4',
          name: 'Dr. Grace Nyerere',
          specialty: 'General Medicine',
          qualification: 'MBBS',
          experience: 6,
          rating: 4.4,
          imageUrl: 'https://picsum.photos/153',
          availableDays: ['Monday', 'Tuesday', 'Thursday', 'Friday'],
          availableTime: '8:00 AM - 4:00 PM',
          consultationFee: 25000.0, // TZS
          bio: 'Dedicated general practitioner serving the community.',
          languages: ['English', 'Kiswahili'],
        ),
      ],
    ),
    Hospital(
      id: 'h3',
      name: 'Bugando Medical Centre',
      address: 'Mwanza',
      latitude: -2.5164,
      longitude: 32.9175,
      distance: 0.0,
      specialties: ['General', 'Cardiology', 'Ophthalmology', 'Oncology'],
      rating: 4.6,
      phoneNumber: '+255-28-2500881',
      hasEmergency: true,
      imageUrl: 'https://picsum.photos/302/200',
      doctors: [
        Doctor(
          id: 'd5',
          name: 'Dr. Ahmed Salim',
          specialty: 'Cardiology',
          qualification: 'MBBS, MD (Cardiology)',
          experience: 12,
          rating: 4.8,
          imageUrl: 'https://picsum.photos/154',
          availableDays: ['Tuesday', 'Wednesday', 'Thursday'],
          availableTime: '9:00 AM - 2:00 PM',
          consultationFee: 65000.0, // TZS
          bio: 'Expert in cardiovascular diseases and interventions.',
          languages: ['English', 'Kiswahili'],
        ),
      ],
    ),
  ];

  static final List<Appointment> _appointments = [];
  static User? _currentUser;

  static Future<List<Hospital>> getNearbyHospitals() async {
    // Calculate distances if location is available
    if (LocationService.hasLocation) {
      final userLat = LocationService.currentLatitude!;
      final userLon = LocationService.currentLongitude!;
      
      for (var hospital in _hospitals) {
        hospital = Hospital(
          id: hospital.id,
          name: hospital.name,
          address: hospital.address,
          latitude: hospital.latitude,
          longitude: hospital.longitude,
          distance: LocationService.calculateDistance(
            userLat, userLon, hospital.latitude, hospital.longitude,
          ),
          specialties: hospital.specialties,
          rating: hospital.rating,
          phoneNumber: hospital.phoneNumber,
          doctors: hospital.doctors,
          hasEmergency: hospital.hasEmergency,
          imageUrl: hospital.imageUrl,
        );
      }
      
      // Sort by distance
      _hospitals.sort((a, b) => a.distance.compareTo(b.distance));
    }
    
    return _hospitals;
  }

  static Hospital? getHospitalById(String id) {
    try {
      return _hospitals.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }

  static Doctor? getDoctorById(String hospitalId, String doctorId) {
    final hospital = getHospitalById(hospitalId);
    if (hospital != null) {
      try {
        return hospital.doctors.firstWhere((d) => d.id == doctorId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<String> bookAppointment(Appointment appointment) async {
    // Simulate booking process
    await Future.delayed(const Duration(seconds: 2));
    
    _appointments.add(appointment);
    return appointment.id;
  }

  static List<Appointment> getUserAppointments() {
    return _appointments;
  }

  static Future<List<String>> getAvailableTimeSlots(String doctorId, DateTime date) async {
    // Mock available time slots
    return [
      '9:00 AM',
      '10:00 AM',
      '11:00 AM',
      '2:00 PM',
      '3:00 PM',
      '4:00 PM',
    ];
  }

  static Future<bool> isDoctorAvailable(String doctorId, DateTime date) async {
    // Mock availability check
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate 80% availability
    return DateTime.now().millisecond % 10 < 8;
  }

  static Future<List<DateTime>> getAlternativeDates(String doctorId) async {
    // Mock alternative dates
    final now = DateTime.now();
    return [
      now.add(const Duration(days: 1)),
      now.add(const Duration(days: 3)),
      now.add(const Duration(days: 7)),
    ];
  }

  static void setCurrentUser(User user) {
    _currentUser = user;
  }

  static User? getCurrentUser() {
    return _currentUser;
  }
}
