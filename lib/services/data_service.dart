import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hospital.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../models/payment_method.dart';
import 'location_service.dart';
import 'api_client.dart';

class DataService {
  static final ApiClient _api = ApiClient();
  static final List<Appointment> _appointments = [];
  static User? _currentUser;
  static String? _authToken;
  static bool _hasInitialized = false;
  static String? _userRole; // 'patient' or 'doctor'

  static Future<List<Hospital>> getNearbyHospitals() async {
    final List<dynamic> list = await _api.getJsonList('/api/hospitals', query: _locationQuery());
    final hospitals = list.map((e) => Hospital.fromJson(e as Map<String, dynamic>)).toList();
    if (LocationService.hasLocation) {
      final userLat = LocationService.currentLatitude!;
      final userLon = LocationService.currentLongitude!;
      for (var i = 0; i < hospitals.length; i++) {
        final h = hospitals[i];
        final dist = LocationService.calculateDistance(userLat, userLon, h.latitude, h.longitude);
        hospitals[i] = Hospital(
          id: h.id,
          name: h.name,
          address: h.address,
          latitude: h.latitude,
          longitude: h.longitude,
          distance: dist,
          specialties: h.specialties,
          rating: h.rating,
          phoneNumber: h.phoneNumber,
          doctors: h.doctors,
          hasEmergency: h.hasEmergency,
          imageUrl: h.imageUrl,
        );
      }
      hospitals.sort((a, b) => a.distance.compareTo(b.distance));
    }
    return hospitals;
  }

  static Future<Hospital?> getHospitalById(String id) async {
    try {
      final data = await _api.getJson('/api/hospitals/$id');
      return Hospital.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  static Future<Doctor?> getDoctorById(String hospitalId, String doctorId) async {
    try {
      final data = await _api.getJson('/api/hospitals/$hospitalId/doctors/$doctorId');
      return Doctor.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Doctor>> getPopularDoctors({int limit = 8}) async {
    try {
      final list = await _api.getJsonList('/api/doctors', query: {
        'popular': 'true',
        'limit': limit.toString(),
      });
      return list.map((e) => Doctor.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('API call failed: $e');
      // Fallback: flatten doctors from hospitals if dedicated endpoint not available
      try {
        final hospitals = await getNearbyHospitals();
        final doctors = <Doctor>[];
        for (final h in hospitals) {
          doctors.addAll(h.doctors);
        }
        return doctors.take(limit).toList();
      } catch (_) {
        // Final fallback: return empty list
        return [];
      }
    }
  }

  static Future<List<Hospital>> getHospitalsByCategory(String category) async {
    try {
      // First try to get hospitals filtered by category from API
      final List<dynamic> list = await _api.getJsonList('/api/hospitals', query: {
        ..._locationQuery(),
        'specialties': category.toLowerCase(),
      });
      final hospitals = list.map((e) => Hospital.fromJson(e as Map<String, dynamic>)).toList();
      
      // Filter hospitals that have doctors in the specified category
      final filteredHospitals = hospitals.where((hospital) {
        return hospital.doctors.any((doctor) => 
          doctor.specialty.toLowerCase().contains(category.toLowerCase()) ||
          hospital.specialties.any((specialty) => 
            specialty.toLowerCase().contains(category.toLowerCase())
          )
        );
      }).toList();
      
      // Calculate distances and sort
      if (LocationService.hasLocation) {
        final userLat = LocationService.currentLatitude!;
        final userLon = LocationService.currentLongitude!;
        for (var i = 0; i < filteredHospitals.length; i++) {
          final h = filteredHospitals[i];
          final dist = LocationService.calculateDistance(userLat, userLon, h.latitude, h.longitude);
          filteredHospitals[i] = Hospital(
            id: h.id,
            name: h.name,
            address: h.address,
            latitude: h.latitude,
            longitude: h.longitude,
            distance: dist,
            specialties: h.specialties,
            rating: h.rating,
            phoneNumber: h.phoneNumber,
            doctors: h.doctors,
            hasEmergency: h.hasEmergency,
            imageUrl: h.imageUrl,
          );
        }
        filteredHospitals.sort((a, b) => a.distance.compareTo(b.distance));
      }
      
      return filteredHospitals;
    } catch (e) {
      print('API call failed for category $category: $e');
      // Fallback: get all hospitals and filter locally
      try {
        final hospitals = await getNearbyHospitals();
        final filteredHospitals = hospitals.where((hospital) {
          return hospital.doctors.any((doctor) => 
            doctor.specialty.toLowerCase().contains(category.toLowerCase()) ||
            hospital.specialties.any((specialty) => 
              specialty.toLowerCase().contains(category.toLowerCase())
            )
          );
        }).toList();
        return filteredHospitals;
      } catch (_) {
        // Final fallback: return empty list
        return [];
      }
    }
  }

  static Future<String> bookAppointment(Appointment appointment) async {
    final res = await _api.postJson('/api/appointments', appointment.toJson());
    final id = (res['id'] ?? res['appointmentId'] ?? '').toString();
    _appointments.add(appointment);
    return id.isNotEmpty ? id : appointment.id;
  }

  static List<Appointment> getUserAppointments() {
    return _appointments;
  }

  static Future<List<String>> getAvailableTimeSlots(String doctorId, DateTime date) async {
    final list = await _api.getJsonList('/api/doctors/$doctorId/availability', query: {
      'date': date.toIso8601String(),
    });
    return list.map((e) => e.toString()).toList();
  }

  static Future<bool> isDoctorAvailable(String doctorId, DateTime date) async {
    final data = await _api.getJson('/api/doctors/$doctorId/availability/check', query: {
      'date': date.toIso8601String(),
    });
    return data['available'] == true;
  }

  static Future<List<DateTime>> getAlternativeDates(String doctorId) async {
    final list = await _api.getJsonList('/api/doctors/$doctorId/alternative-dates');
    return list.map((e) => DateTime.tryParse(e.toString()) ?? DateTime.now()).toList();
  }

  static void setCurrentUser(User user) {
    _currentUser = user;
    _saveUserToStorage(user);
  }

  static User? getCurrentUser() {
    return _currentUser;
  }

  static String? getAuthToken() {
    return _authToken;
  }

  static void setAuthToken(String token) {
    _authToken = token;
    _saveTokenToStorage(token);
  }

  // Role persistence
  static Future<void> setUserRole(String role) async {
    _userRole = role;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
    } catch (e) {
      // Non-fatal
      print('❌ Error saving user role: $e');
    }
  }

  static String? getUserRole() {
    return _userRole;
  }

  static Future<void> _saveUserToStorage(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user.toJson());
      await prefs.setString('current_user', userJson);
      await prefs.setBool('is_logged_in', true);
      print('✅ User data saved to SharedPreferences');
    } catch (e) {
      print('❌ Error saving user data: $e');
      // Continue without throwing - user can still use the app
    }
  }

  static Future<void> _saveTokenToStorage(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('✅ Token saved to SharedPreferences');
    } catch (e) {
      print('❌ Error saving token: $e');
    }
  }

  static Future<String?> _loadTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        print('✅ Token loaded from SharedPreferences');
        return token;
      }
    } catch (e) {
      print('❌ Error loading token: $e');
    }
    return null;
  }

  static Future<User?> loadUserFromStorage({bool forceRefresh = false}) async {
    // If already initialized and not forcing refresh, return current user
    if (_hasInitialized && !forceRefresh) {
      return _currentUser;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      _userRole = prefs.getString('user_role');
      
      if (isLoggedIn) {
        // Load token first
        _authToken = await _loadTokenFromStorage();
        
        final userJson = prefs.getString('current_user');
        if (userJson != null) {
          try {
            final userData = json.decode(userJson) as Map<String, dynamic>;
            _currentUser = User.fromJson(userData);
            _hasInitialized = true;
            return _currentUser;
          } catch (e) {
            print('Error parsing user data from storage: $e');
            await clearUserData();
          }
        }
        
        // If no user data in storage but we have a token, try API
        if (_currentUser == null && _authToken != null) {
          await _fetchUserFromApi();
        }
      }
    } catch (e) {
      print('Error loading user from storage: $e');
      // Try to fetch user from API if storage fails
      await _fetchUserFromApi();
    }
    
    _hasInitialized = true;
    return _currentUser;
  }

  static Future<void> _fetchUserFromApi() async {
    try {
      // Load token from storage first
      _authToken = await _loadTokenFromStorage();
      
      if (_authToken == null) {
        print('No auth token found, user needs to login');
        return;
      }
      
      // Fetch current user profile from API with token
      final response = await _api.getJsonWithAuth('/user/profile', _authToken!);
      
      if (response['success'] == true && response['data'] != null) {
        final userData = response['data'] as Map<String, dynamic>;
        _currentUser = User.fromJson(userData);
        print('Successfully fetched user from API');
        
        // Try to save to storage for future use
        if (_currentUser != null) {
          await _saveUserToStorage(_currentUser!);
        }
      } else {
        print('Failed to fetch user from API: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error fetching user from API: $e');
      // If API also fails, user will need to login
    }
  }

  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      await prefs.remove('is_logged_in');
      await prefs.remove('auth_token');
      await prefs.remove('user_role');
    } catch (e) {
      print('Error clearing user data: $e');
    }
    _currentUser = null;
    _authToken = null;
    _userRole = null;
  }

  static Map<String, String> _locationQuery() {
    if (!LocationService.hasLocation) return {};
    return {
      'lat': LocationService.currentLatitude!.toString(),
      'lon': LocationService.currentLongitude!.toString(),
    };
  }

  // Payment Method Storage
  static Future<void> savePaymentMethod(PaymentMethodDetails paymentMethod) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing payment methods
      final existingMethods = await getPaymentMethods();
      
      // If this is set as default, unset others
      final updatedMethods = existingMethods.where((m) => m.id != paymentMethod.id).map((method) {
        if (paymentMethod.isDefault) {
          return PaymentMethodDetails(
            id: method.id,
            type: method.type,
            bankName: method.bankName,
            cardNumber: method.cardNumber,
            cardHolderName: method.cardHolderName,
            expiryDate: method.expiryDate,
            cvv: method.cvv,
            nidaNumber: method.nidaNumber,
            createdAt: method.createdAt,
            isDefault: false,
          );
        }
        return method;
      }).toList();
      updatedMethods.add(paymentMethod);
      
      // Save all payment methods
      final methodsJson = updatedMethods.map((m) => m.toJson()).toList();
      await prefs.setString('payment_methods', json.encode(methodsJson));
      
      // If this is the default or first method, save it as selected
      if (paymentMethod.isDefault || existingMethods.isEmpty) {
        await prefs.setString('selected_payment_method_id', paymentMethod.id);
      }
      
      print('✅ Payment method saved: ${paymentMethod.id}');
    } catch (e) {
      print('❌ Error saving payment method: $e');
    }
  }

  static Future<List<PaymentMethodDetails>> getPaymentMethods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final methodsJson = prefs.getString('payment_methods');
      
      if (methodsJson == null) {
        return [];
      }
      
      final List<dynamic> methodsList = json.decode(methodsJson);
      return methodsList
          .map((m) => PaymentMethodDetails.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error loading payment methods: $e');
      print('Error details: ${e.toString()}');
      return <PaymentMethodDetails>[];
    }
  }

  static Future<PaymentMethodDetails?> getSelectedPaymentMethod() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedId = prefs.getString('selected_payment_method_id');
      
      if (selectedId == null) {
        // Get default payment method or first one
        final methods = await getPaymentMethods();
        if (methods.isNotEmpty) {
          return methods.firstWhere(
            (m) => m.isDefault,
            orElse: () => methods.first,
          );
        }
        return null;
      }
      
      final methods = await getPaymentMethods();
      return methods.firstWhere(
        (m) => m.id == selectedId,
        orElse: () => methods.isNotEmpty ? methods.first : PaymentMethodDetails(
          id: '',
          type: '',
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      print('❌ Error loading selected payment method: $e');
      return null;
    }
  }

  static Future<void> setSelectedPaymentMethod(String paymentMethodId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_payment_method_id', paymentMethodId);
      print('✅ Selected payment method updated: $paymentMethodId');
    } catch (e) {
      print('❌ Error setting selected payment method: $e');
    }
  }

  static Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final methods = await getPaymentMethods();
      final updatedMethods = methods.where((m) => m.id != paymentMethodId).toList();
      
      final methodsJson = updatedMethods.map((m) => m.toJson()).toList();
      await prefs.setString('payment_methods', json.encode(methodsJson));
      
      // If deleted method was selected, select first available or clear
      final selectedId = prefs.getString('selected_payment_method_id');
      if (selectedId == paymentMethodId) {
        if (updatedMethods.isNotEmpty) {
          await prefs.setString('selected_payment_method_id', updatedMethods.first.id);
        } else {
          await prefs.remove('selected_payment_method_id');
        }
      }
      
      print('✅ Payment method deleted: $paymentMethodId');
    } catch (e) {
      print('❌ Error deleting payment method: $e');
    }
  }
}
