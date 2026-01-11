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

  static Future<List<Doctor>> getHospitalDoctors(String hospitalId) async {
    try {
      print('📋 Fetching doctors for hospital: $hospitalId');
      final list = await _api.getJsonList('/api/hospitals/$hospitalId/doctors');
      final doctors = list
          .where((item) => item is Map<String, dynamic>)
          .map((item) {
            try {
              return Doctor.fromJson(item as Map<String, dynamic>);
            } catch (e) {
              print('❌ Error parsing doctor: $e');
              return null;
            }
          })
          .where((doctor) => doctor != null)
          .cast<Doctor>()
          .toList();
      print('✅ Fetched ${doctors.length} doctors for hospital $hospitalId');
      return doctors;
    } catch (e) {
      print('❌ Error fetching doctors for hospital $hospitalId: $e');
      return [];
    }
  }

  static Future<List<Doctor>> getHospitalDoctorsByCategory(String hospitalId, String category) async {
    try {
      print('📋 Fetching doctors for hospital: $hospitalId with category: $category');
      final doctors = await getHospitalDoctors(hospitalId);
      // Filter doctors by category/specialty
      final filteredDoctors = doctors.where((doctor) {
        final specialty = doctor.specialty.toLowerCase();
        final categoryLower = category.toLowerCase();
        return specialty.contains(categoryLower) || 
               specialty == categoryLower ||
               specialty.split(' ').any((word) => word == categoryLower);
      }).toList();
      print('✅ Found ${filteredDoctors.length} doctors matching category "$category" in hospital $hospitalId');
      return filteredDoctors;
    } catch (e) {
      print('❌ Error fetching doctors by category: $e');
      return [];
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

  static Future<List<Hospital>> _fetchAllHospitalsWithRetry({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('📋 Fetching hospitals (attempt $attempt/$maxRetries)');
        final List<dynamic> list = await _api.getJsonList('/api/hospitals', query: _locationQuery());
        final hospitals = list.map((e) => Hospital.fromJson(e as Map<String, dynamic>)).toList();
        print('✅ Successfully fetched ${hospitals.length} hospitals from API');
        return hospitals;
      } catch (e) {
        final isConnectionError = e.toString().contains('Connection closed') ||
                                  e.toString().contains('SocketException') ||
                                  e.toString().contains('TimeoutException');
        
        if (isConnectionError && attempt < maxRetries) {
          print('⚠️ Connection error on attempt $attempt, retrying in ${attempt * 2} seconds...');
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        
        // If it's the last attempt or not a connection error, rethrow
        if (attempt == maxRetries) {
          print('❌ Failed to fetch hospitals after $maxRetries attempts: $e');
          rethrow;
        }
      }
    }
    return [];
  }

  static bool _matchesCategory(String specialty, String category) {
    final specialtyLower = specialty.toLowerCase().trim();
    final categoryLower = category.toLowerCase().trim();
    
    // Exact match
    if (specialtyLower == categoryLower) {
      return true;
    }
    
    // Contains match (bidirectional)
    if (specialtyLower.contains(categoryLower) || categoryLower.contains(specialtyLower)) {
      return true;
    }
    
    // Word match (e.g., "Cardiology" matches "Cardiologist", "Psychiatry" matches "Psychiatrist")
    final specialtyWords = specialtyLower.split(RegExp(r'[\s-]+'));
    final categoryWords = categoryLower.split(RegExp(r'[\s-]+'));
    
    // Check if any word matches
    if (specialtyWords.any((word) => categoryWords.contains(word)) ||
        categoryWords.any((word) => specialtyWords.contains(word))) {
      return true;
    }
    
    // Check for common variations (e.g., "Psychiatry" vs "Psychiatrist")
    final specialtyRoot = specialtyLower.replaceAll(RegExp(r'(ist|ology|ian|ist)$'), '');
    final categoryRoot = categoryLower.replaceAll(RegExp(r'(ist|ology|ian|ist)$'), '');
    if (specialtyRoot.isNotEmpty && categoryRoot.isNotEmpty && 
        (specialtyRoot.contains(categoryRoot) || categoryRoot.contains(specialtyRoot))) {
      return true;
    }
    
    return false;
  }

  static Future<List<Hospital>> getHospitalsByCategory(String category) async {
    try {
      print('📋 Fetching hospitals for category: "$category"');
      
      // Fetch all hospitals with retry logic
      final hospitals = await _fetchAllHospitalsWithRetry();
      
      if (hospitals.isEmpty) {
        print('⚠️ No hospitals returned from API');
        return [];
      }
      
      print('📋 Received ${hospitals.length} hospitals from API');
      final allSpecialties = hospitals.expand((h) => h.specialties).toSet().toList();
      print('📋 Available specialties in all hospitals: $allSpecialties');
      
      // Filter hospitals where specialties array contains a matching specialty
      final filteredHospitals = hospitals.where((hospital) {
        // Check if any specialty in the hospital's specialties array matches the category
        final hasMatchingSpecialty = hospital.specialties.any((specialty) {
          if (_matchesCategory(specialty, category)) {
            print('✅ Hospital "${hospital.name}": Match - specialty "$specialty" matches category "$category"');
            return true;
          }
          return false;
        });
        
        // Also check doctors if no specialty match (fallback)
        if (!hasMatchingSpecialty && hospital.doctors.isNotEmpty) {
          final hasMatchingDoctor = hospital.doctors.any((doctor) {
            if (_matchesCategory(doctor.specialty, category)) {
              print('✅ Hospital "${hospital.name}": Doctor match - doctor specialty "${doctor.specialty}" matches category "$category"');
              return true;
            }
            return false;
          });
          if (hasMatchingDoctor) {
            return true;
          }
        }
        
        if (!hasMatchingSpecialty) {
          print('❌ Hospital "${hospital.name}": No match - specialties: ${hospital.specialties}, category: "$category"');
        }
        
        return hasMatchingSpecialty;
      }).toList();
      
      print('✅ Filtered to ${filteredHospitals.length} hospitals matching category "$category"');
      
      // Calculate distances and sort
      if (LocationService.hasLocation && filteredHospitals.isNotEmpty) {
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
    } catch (e, stackTrace) {
      print('❌ Error fetching hospitals for category "$category": $e');
      print('❌ Stack trace: $stackTrace');
      // Return empty list instead of trying fallback (which would make another API call)
      return [];
    }
  }

  static Future<String> bookAppointment(Appointment appointment) async {
    // Get auth token
    final token = await getAuthToken();
    if (token == null) {
      throw Exception('Authentication required. Please login to book an appointment.');
    }
    
    print('🔵 [DEBUG] bookAppointment() called');
    print('🔵 [DEBUG] Appointment: ${appointment.toJson()}');
    print('🔵 [DEBUG] Using auth token: ${token.substring(0, 20)}...');
    
    final res = await _api.postJsonWithAuth('/api/appointments', appointment.toJson(), token);
    final id = (res['id'] ?? res['appointmentId'] ?? '').toString();
    addOrUpdateUserAppointment(
      Appointment(
        id: id.isNotEmpty ? id : appointment.id,
        hospitalId: appointment.hospitalId,
        hospitalName: appointment.hospitalName,
        doctorId: appointment.doctorId,
        doctorName: appointment.doctorName,
        doctorSpecialty: appointment.doctorSpecialty,
        appointmentDate: appointment.appointmentDate,
        timeSlot: appointment.timeSlot,
        patientName: appointment.patientName,
        patientPhone: appointment.patientPhone,
        problem: appointment.problem,
        status: appointment.status,
        amount: appointment.amount,
        paymentMethod: appointment.paymentMethod,
        paymentStatus: appointment.paymentStatus,
        createdAt: appointment.createdAt,
      ),
    );
    print('🔵 [DEBUG] Appointment booked successfully with ID: $id');
    return id.isNotEmpty ? id : appointment.id;
  }

  static List<Appointment> getUserAppointments() {
    return List.unmodifiable(_appointments);
  }

  static Future<List<Appointment>> fetchUserAppointments() async {
    try {
      // Load locally cancelled appointments first
      final locallyCancelledIds = await _loadLocalCancellations();
      
      final token = await getAuthToken();
      if (token == null) {
        print('⚠️ No auth token, returning cached appointments');
        // Apply local cancellations to cached appointments
        _applyLocalCancellations(locallyCancelledIds);
        return _appointments;
      }

      print('📋 Fetching appointments from API...');
      
      // Try to get as a list with auth first
      try {
        final listResponse = await _api.getJsonListWithAuth('/api/appointments', token);
        if (listResponse.isNotEmpty) {
          final appointments = listResponse
              .where((item) => item is Map<String, dynamic>)
              .map((item) {
                try {
                  final appointment = Appointment.fromJson(item as Map<String, dynamic>);
                  // Validate that appointment has required fields
                  if (appointment.id.isEmpty) {
                    print('⚠️ WARNING: Appointment has empty ID, skipping');
                    print('   Item: $item');
                    return null;
                  }
                  // Log if doctor name is missing
                  if (appointment.doctorName.isEmpty) {
                    print('⚠️ WARNING: Appointment ${appointment.id} has empty doctor name');
                    print('   Item: $item');
                  }
                  return appointment;
                } catch (e, stackTrace) {
                  print('❌ Error parsing appointment: $e');
                  print('   Stack trace: $stackTrace');
                  print('   Item: $item');
                  return null;
                }
              })
              .where((apt) => apt != null)
              .cast<Appointment>()
              .toList();
          
          // Merge API appointments with cached ones to preserve doctor info
          final cachedAppointmentsMap = Map<String, Appointment>.fromEntries(
            _appointments.map((apt) => MapEntry(apt.id, apt))
          );
          
          // Update or add appointments from API, preserving doctor info and local cancellations from cache
          for (var apiAppt in appointments) {
            final cachedAppt = cachedAppointmentsMap[apiAppt.id];
            if (cachedAppt != null) {
              // Preserve cancelled status from cache if it was locally cancelled (API might not have synced yet)
              final shouldPreserveCancellation = cachedAppt.status == AppointmentStatus.cancelled && 
                                                  apiAppt.status != AppointmentStatus.cancelled;
              
              // Preserve doctor info from cache if API doesn't have it OR if we're preserving cancellation
              if ((apiAppt.doctorName.isEmpty && cachedAppt.doctorName.isNotEmpty) || shouldPreserveCancellation) {
                apiAppt = Appointment(
                  id: apiAppt.id,
                  hospitalId: apiAppt.hospitalId.isEmpty ? cachedAppt.hospitalId : apiAppt.hospitalId,
                  hospitalName: apiAppt.hospitalName.isEmpty ? cachedAppt.hospitalName : apiAppt.hospitalName,
                  doctorId: apiAppt.doctorId.isEmpty ? cachedAppt.doctorId : apiAppt.doctorId,
                  doctorName: cachedAppt.doctorName.isNotEmpty ? cachedAppt.doctorName : apiAppt.doctorName,
                  doctorSpecialty: apiAppt.doctorSpecialty.isEmpty ? cachedAppt.doctorSpecialty : apiAppt.doctorSpecialty,
                  appointmentDate: apiAppt.appointmentDate,
                  timeSlot: apiAppt.timeSlot.isEmpty ? cachedAppt.timeSlot : apiAppt.timeSlot,
                  patientName: apiAppt.patientName.isEmpty ? cachedAppt.patientName : apiAppt.patientName,
                  patientPhone: apiAppt.patientPhone.isEmpty ? cachedAppt.patientPhone : apiAppt.patientPhone,
                  problem: apiAppt.problem.isEmpty ? cachedAppt.problem : apiAppt.problem,
                  status: shouldPreserveCancellation ? AppointmentStatus.cancelled : apiAppt.status,
                  amount: apiAppt.amount == 0 ? cachedAppt.amount : apiAppt.amount,
                  paymentMethod: apiAppt.paymentMethod,
                  paymentStatus: apiAppt.paymentStatus,
                  createdAt: apiAppt.createdAt,
                );
                if (shouldPreserveCancellation) {
                  print('✅ Merged appointment ${apiAppt.id} - preserved local cancellation');
                } else {
                  print('✅ Merged appointment ${apiAppt.id} - preserved doctor: ${apiAppt.doctorName}');
                }
              } else if (shouldPreserveCancellation) {
                // If we're not merging for doctor info but should preserve cancellation, still update status
                apiAppt = Appointment(
                  id: apiAppt.id,
                  hospitalId: apiAppt.hospitalId,
                  hospitalName: apiAppt.hospitalName,
                  doctorId: apiAppt.doctorId,
                  doctorName: apiAppt.doctorName,
                  doctorSpecialty: apiAppt.doctorSpecialty,
                  appointmentDate: apiAppt.appointmentDate,
                  timeSlot: apiAppt.timeSlot,
                  patientName: apiAppt.patientName,
                  patientPhone: apiAppt.patientPhone,
                  problem: apiAppt.problem,
                  status: AppointmentStatus.cancelled,
                  amount: apiAppt.amount,
                  paymentMethod: apiAppt.paymentMethod,
                  paymentStatus: apiAppt.paymentStatus,
                  createdAt: apiAppt.createdAt,
                );
                print('✅ Updated appointment ${apiAppt.id} - preserved local cancellation');
              }
            }
            cachedAppointmentsMap[apiAppt.id] = apiAppt;
          }
          
          // Also preserve locally cancelled appointments that might not be in API response
          for (var cachedAppt in _appointments) {
            if (cachedAppt.status == AppointmentStatus.cancelled && 
                !cachedAppointmentsMap.containsKey(cachedAppt.id)) {
              // This appointment was locally cancelled but not in API response, keep it
              cachedAppointmentsMap[cachedAppt.id] = cachedAppt;
              print('✅ Preserved locally cancelled appointment: ${cachedAppt.id}');
            }
          }
          
          // Update the in-memory list with merged appointments
          _appointments.clear();
          _appointments.addAll(cachedAppointmentsMap.values.toList());
          
          // Apply local cancellations from persistent storage
          _applyLocalCancellations(locallyCancelledIds);
          
          print('✅ Fetched ${appointments.length} appointments from API (list format)');
          for (var apt in _appointments) {
            print('   - ${apt.doctorName.isNotEmpty ? apt.doctorName : "⚠️ EMPTY"} (ID: ${apt.id})');
          }
          return _appointments;
        }
      } catch (listError) {
        print('📋 List format failed, trying map format: $listError');
      }
      
      // Fallback to map format
      final response = await _api.getJsonWithAuth('/api/appointments', token);
      List<Appointment> appointments = [];
      
      // Handle different response formats
      if (response['data'] is List) {
        final dataList = response['data'] as List;
        appointments = dataList
            .where((item) => item is Map<String, dynamic>)
            .map((item) {
                try {
                  final appointment = Appointment.fromJson(item as Map<String, dynamic>);
                  // Validate that appointment has required fields
                  if (appointment.id.isEmpty) {
                    print('⚠️ WARNING: Appointment has empty ID, skipping');
                    print('   Item: $item');
                    return null;
                  }
                  // Log if doctor name is missing
                  if (appointment.doctorName.isEmpty) {
                    print('⚠️ WARNING: Appointment ${appointment.id} has empty doctor name from API');
                    print('   Raw data: $item');
                  }
                  return appointment;
                } catch (e, stackTrace) {
                  print('❌ Error parsing appointment: $e');
                  print('   Stack trace: $stackTrace');
                  print('   Item: $item');
                  return null;
                }
            })
            .where((apt) => apt != null)
            .cast<Appointment>()
            .toList();
      } else if (response['appointments'] is List) {
        final appointmentsList = response['appointments'] as List;
        appointments = appointmentsList
            .where((item) => item is Map<String, dynamic>)
            .map((item) {
              try {
                final appointment = Appointment.fromJson(item as Map<String, dynamic>);
                if (appointment.doctorName.isEmpty) {
                  print('⚠️ WARNING: Appointment ${appointment.id} has empty doctor name from API');
                  print('   Raw data: $item');
                }
                return appointment;
              } catch (e) {
                print('❌ Error parsing appointment: $e');
                print('   Item: $item');
                return null;
              }
            })
            .where((apt) => apt != null)
            .cast<Appointment>()
            .toList();
      } else if (response['results'] is List) {
        final resultsList = response['results'] as List;
        appointments = resultsList
            .where((item) => item is Map<String, dynamic>)
            .map((item) {
              try {
                final appointment = Appointment.fromJson(item as Map<String, dynamic>);
                if (appointment.doctorName.isEmpty) {
                  print('⚠️ WARNING: Appointment ${appointment.id} has empty doctor name from API');
                  print('   Raw data: $item');
                }
                return appointment;
              } catch (e) {
                print('❌ Error parsing appointment: $e');
                print('   Item: $item');
                return null;
              }
            })
            .where((apt) => apt != null)
            .cast<Appointment>()
            .toList();
      }

      // Merge API appointments with cached ones to preserve doctor info
      // If API appointment has empty doctor name, use cached version if available
      final cachedAppointments = Map<String, Appointment>.fromEntries(
        _appointments.map((apt) => MapEntry(apt.id, apt))
      );
      
      // Update or add appointments from API, preserving local cancellations
      for (var apiAppt in appointments) {
        final cachedAppt = cachedAppointments[apiAppt.id];
        if (cachedAppt != null) {
          // Preserve cancelled status from cache if it was locally cancelled (API might not have synced yet)
          final shouldPreserveCancellation = cachedAppt.status == AppointmentStatus.cancelled && 
                                              apiAppt.status != AppointmentStatus.cancelled;
          
          // Merge: use API data but preserve doctor info from cache if API doesn't have it OR if preserving cancellation
          if ((apiAppt.doctorName.isEmpty && cachedAppt.doctorName.isNotEmpty) || shouldPreserveCancellation) {
            apiAppt = Appointment(
              id: apiAppt.id,
              hospitalId: apiAppt.hospitalId.isEmpty ? cachedAppt.hospitalId : apiAppt.hospitalId,
              hospitalName: apiAppt.hospitalName.isEmpty ? cachedAppt.hospitalName : apiAppt.hospitalName,
              doctorId: apiAppt.doctorId.isEmpty ? cachedAppt.doctorId : apiAppt.doctorId,
              doctorName: cachedAppt.doctorName.isNotEmpty ? cachedAppt.doctorName : apiAppt.doctorName, // Preserve cached doctor name
              doctorSpecialty: apiAppt.doctorSpecialty.isEmpty ? cachedAppt.doctorSpecialty : apiAppt.doctorSpecialty,
              appointmentDate: apiAppt.appointmentDate,
              timeSlot: apiAppt.timeSlot.isEmpty ? cachedAppt.timeSlot : apiAppt.timeSlot,
              patientName: apiAppt.patientName.isEmpty ? cachedAppt.patientName : apiAppt.patientName,
              patientPhone: apiAppt.patientPhone.isEmpty ? cachedAppt.patientPhone : apiAppt.patientPhone,
              problem: apiAppt.problem.isEmpty ? cachedAppt.problem : apiAppt.problem,
              status: shouldPreserveCancellation ? AppointmentStatus.cancelled : apiAppt.status,
              amount: apiAppt.amount == 0 ? cachedAppt.amount : apiAppt.amount,
              paymentMethod: apiAppt.paymentMethod,
              paymentStatus: apiAppt.paymentStatus,
              createdAt: apiAppt.createdAt,
            );
            if (shouldPreserveCancellation) {
              print('✅ Merged appointment ${apiAppt.id} - preserved local cancellation');
            } else {
              print('✅ Merged appointment ${apiAppt.id} - preserved doctor name: ${apiAppt.doctorName}');
            }
          } else if (shouldPreserveCancellation) {
            // If we're not merging for doctor info but should preserve cancellation, still update status
            apiAppt = Appointment(
              id: apiAppt.id,
              hospitalId: apiAppt.hospitalId,
              hospitalName: apiAppt.hospitalName,
              doctorId: apiAppt.doctorId,
              doctorName: apiAppt.doctorName,
              doctorSpecialty: apiAppt.doctorSpecialty,
              appointmentDate: apiAppt.appointmentDate,
              timeSlot: apiAppt.timeSlot,
              patientName: apiAppt.patientName,
              patientPhone: apiAppt.patientPhone,
              problem: apiAppt.problem,
              status: AppointmentStatus.cancelled,
              amount: apiAppt.amount,
              paymentMethod: apiAppt.paymentMethod,
              paymentStatus: apiAppt.paymentStatus,
              createdAt: apiAppt.createdAt,
            );
            print('✅ Updated appointment ${apiAppt.id} - preserved local cancellation');
          }
        }
        cachedAppointments[apiAppt.id] = apiAppt;
      }
      
      // Also preserve locally cancelled appointments that might not be in API response
      for (var cachedAppt in _appointments) {
        if (cachedAppt.status == AppointmentStatus.cancelled && 
            !cachedAppointments.containsKey(cachedAppt.id)) {
          // This appointment was locally cancelled but not in API response, keep it
          cachedAppointments[cachedAppt.id] = cachedAppt;
          print('✅ Preserved locally cancelled appointment: ${cachedAppt.id}');
        }
      }
      
      // Update the in-memory list with merged appointments
      _appointments.clear();
      _appointments.addAll(cachedAppointments.values.toList());
      
      // Apply local cancellations from persistent storage
      _applyLocalCancellations(locallyCancelledIds);
      
      print('✅ Fetched ${appointments.length} appointments from API (map format)');
      for (var apt in _appointments) {
        print('   - ${apt.doctorName.isNotEmpty ? apt.doctorName : "⚠️ EMPTY"} (ID: ${apt.id})');
      }
      return _appointments;
    } catch (e) {
      print('❌ Error fetching appointments from API: $e');
      print('📋 Returning ${_appointments.length} cached appointments');
      // Load and apply local cancellations even on error
      final locallyCancelledIds = await _loadLocalCancellations();
      _applyLocalCancellations(locallyCancelledIds);
      // Return cached appointments if API fails
      return _appointments;
    }
  }

  static void _applyLocalCancellations(Set<String> locallyCancelledIds) {
    if (locallyCancelledIds.isEmpty) return;
    
    for (var appointmentId in locallyCancelledIds) {
      final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
      if (index >= 0) {
        final appointment = _appointments[index];
        // Only apply cancellation if status is not already cancelled (from API)
        if (appointment.status != AppointmentStatus.cancelled) {
          _appointments[index] = Appointment(
            id: appointment.id,
            hospitalId: appointment.hospitalId,
            hospitalName: appointment.hospitalName,
            doctorId: appointment.doctorId,
            doctorName: appointment.doctorName,
            doctorSpecialty: appointment.doctorSpecialty,
            appointmentDate: appointment.appointmentDate,
            timeSlot: appointment.timeSlot,
            patientName: appointment.patientName,
            patientPhone: appointment.patientPhone,
            problem: appointment.problem,
            status: AppointmentStatus.cancelled,
            amount: appointment.amount,
            paymentMethod: appointment.paymentMethod,
            paymentStatus: appointment.paymentStatus,
            createdAt: appointment.createdAt,
          );
          print('✅ Applied local cancellation to appointment: $appointmentId');
        }
      }
    }
  }

  static void addOrUpdateUserAppointment(Appointment appointment) {
    final index = _appointments.indexWhere((existing) => existing.id == appointment.id);
    if (index >= 0) {
      _appointments[index] = appointment;
      print('✅ Updated appointment: ${appointment.id} - ${appointment.doctorName}');
    } else {
      _appointments.insert(0, appointment);
      print('✅ Added new appointment: ${appointment.id} - ${appointment.doctorName}');
    }
    print('📋 Total appointments in cache: ${_appointments.length}');
  }

  static Future<void> _saveLocalCancellation(String appointmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cancelledAppointmentsJson = prefs.getString('locally_cancelled_appointments');
      Set<String> cancelledIds = {};
      
      if (cancelledAppointmentsJson != null) {
        final List<dynamic> cancelledList = json.decode(cancelledAppointmentsJson);
        cancelledIds = cancelledList.map((id) => id.toString()).toSet();
      }
      
      cancelledIds.add(appointmentId);
      await prefs.setString('locally_cancelled_appointments', json.encode(cancelledIds.toList()));
      print('✅ Saved local cancellation for appointment: $appointmentId');
    } catch (e) {
      print('❌ Error saving local cancellation: $e');
    }
  }

  static Future<Set<String>> _loadLocalCancellations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cancelledAppointmentsJson = prefs.getString('locally_cancelled_appointments');
      
      if (cancelledAppointmentsJson != null) {
        final List<dynamic> cancelledList = json.decode(cancelledAppointmentsJson);
        final cancelledIds = cancelledList.map((id) => id.toString()).toSet();
        print('✅ Loaded ${cancelledIds.length} locally cancelled appointments');
        return cancelledIds;
      }
      return <String>{};
    } catch (e) {
      print('❌ Error loading local cancellations: $e');
      return <String>{};
    }
  }

  static Future<void> _removeLocalCancellation(String appointmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cancelledAppointmentsJson = prefs.getString('locally_cancelled_appointments');
      
      if (cancelledAppointmentsJson != null) {
        final List<dynamic> cancelledList = json.decode(cancelledAppointmentsJson);
        final cancelledIds = cancelledList.map((id) => id.toString()).toSet();
        cancelledIds.remove(appointmentId);
        await prefs.setString('locally_cancelled_appointments', json.encode(cancelledIds.toList()));
        print('✅ Removed local cancellation for appointment: $appointmentId');
      }
    } catch (e) {
      print('❌ Error removing local cancellation: $e');
    }
  }

  static Future<void> cancelAppointment(String appointmentId) async {
    final token = await getAuthToken();
    if (token == null) {
      throw Exception('Authentication required. Please login to cancel an appointment.');
    }

    try {
      // Try PUT endpoint first (typical REST API pattern)
      try {
        final response = await _api.putJsonWithAuth(
          '/api/appointments/$appointmentId',
          {'status': 'cancelled'},
          token,
        );
        
        // Update local appointment cache
        final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
        if (index >= 0) {
          final appointment = _appointments[index];
          _appointments[index] = Appointment(
            id: appointment.id,
            hospitalId: appointment.hospitalId,
            hospitalName: appointment.hospitalName,
            doctorId: appointment.doctorId,
            doctorName: appointment.doctorName,
            doctorSpecialty: appointment.doctorSpecialty,
            appointmentDate: appointment.appointmentDate,
            timeSlot: appointment.timeSlot,
            patientName: appointment.patientName,
            patientPhone: appointment.patientPhone,
            problem: appointment.problem,
            status: AppointmentStatus.cancelled,
            amount: appointment.amount,
            paymentMethod: appointment.paymentMethod,
            paymentStatus: appointment.paymentStatus,
            createdAt: appointment.createdAt,
          );
          print('✅ Appointment cancelled: $appointmentId');
        }
        
        // Remove from local cancellations since API confirmed it
        await _removeLocalCancellation(appointmentId);
        
        // If API returns appointment data, parse and use it
        if (response['id'] != null || response['appointmentId'] != null) {
          final updatedAppointment = Appointment.fromJson(response);
          addOrUpdateUserAppointment(updatedAppointment);
        }
      } catch (patchError) {
        // Fallback: Try POST to cancel endpoint
        try {
          final response = await _api.postJsonWithAuth(
            '/api/appointments/$appointmentId/cancel',
            {},
            token,
          );
          
          // Update local cache
          final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
          if (index >= 0) {
            final appointment = _appointments[index];
            _appointments[index] = Appointment(
              id: appointment.id,
              hospitalId: appointment.hospitalId,
              hospitalName: appointment.hospitalName,
              doctorId: appointment.doctorId,
              doctorName: appointment.doctorName,
              doctorSpecialty: appointment.doctorSpecialty,
              appointmentDate: appointment.appointmentDate,
              timeSlot: appointment.timeSlot,
              patientName: appointment.patientName,
              patientPhone: appointment.patientPhone,
              problem: appointment.problem,
              status: AppointmentStatus.cancelled,
              amount: appointment.amount,
              paymentMethod: appointment.paymentMethod,
              paymentStatus: appointment.paymentStatus,
              createdAt: appointment.createdAt,
            );
          }
          
          // Remove from local cancellations since API confirmed it
          await _removeLocalCancellation(appointmentId);
          
          if (response['id'] != null || response['appointmentId'] != null) {
            final updatedAppointment = Appointment.fromJson(response);
            addOrUpdateUserAppointment(updatedAppointment);
          }
        } catch (postError) {
          // If both API calls fail, still update local cache for offline support
          final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
          if (index >= 0) {
            final appointment = _appointments[index];
            _appointments[index] = Appointment(
              id: appointment.id,
              hospitalId: appointment.hospitalId,
              hospitalName: appointment.hospitalName,
              doctorId: appointment.doctorId,
              doctorName: appointment.doctorName,
              doctorSpecialty: appointment.doctorSpecialty,
              appointmentDate: appointment.appointmentDate,
              timeSlot: appointment.timeSlot,
              patientName: appointment.patientName,
              patientPhone: appointment.patientPhone,
              problem: appointment.problem,
              status: AppointmentStatus.cancelled,
              amount: appointment.amount,
              paymentMethod: appointment.paymentMethod,
              paymentStatus: appointment.paymentStatus,
              createdAt: appointment.createdAt,
            );
            
            // Save cancellation to persistent storage
            await _saveLocalCancellation(appointmentId);
            
            print('⚠️ API calls failed, but updated local cache. Error: $postError');
            throw Exception('Failed to cancel appointment on server. Changes saved locally.');
          }
          throw postError;
        }
      }
    } catch (e) {
      print('❌ Error cancelling appointment: $e');
      // If API fails but we have the appointment, save cancellation locally
      final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
      if (index >= 0 && !e.toString().contains('Changes saved locally')) {
        await _saveLocalCancellation(appointmentId);
      }
      rethrow;
    }
  }

  static Future<List<String>> getAvailableTimeSlots(String doctorId, DateTime date) async {
    final endpoint = '/api/doctors/$doctorId/availability';
    final dateQuery = date.toIso8601String();
    
    print('🔵 [DEBUG] ========================================');
    print('🔵 [DEBUG] getAvailableTimeSlots() called');
    print('🔵 [DEBUG] Doctor ID: $doctorId');
    print('🔵 [DEBUG] Date: $dateQuery');
    print('🔵 [DEBUG] Endpoint: $endpoint');
    print('🔵 [DEBUG] Full URL: ${ApiClient.baseUrl}$endpoint?date=$dateQuery');
    
    try {
      print('🔵 [DEBUG] Making API call...');
      final list = await _api.getJsonList(endpoint, query: {
        'date': dateQuery,
      });
      
      print('🔵 [DEBUG] API Response received');
      print('🔵 [DEBUG] Response type: ${list.runtimeType}');
      print('🔵 [DEBUG] Response length: ${list.length}');
      print('🔵 [DEBUG] Raw response: $list');
      
      // Handle different response formats
      List<String> parsedSlots = [];
      
      // Check if response is a list of strings (direct format)
      if (list.isNotEmpty && list.first is String) {
        print('🔵 [DEBUG] Response is a direct list of strings');
        parsedSlots = list.map((e) => e.toString()).where((time) => time.isNotEmpty).toList();
      }
      // Check if response is wrapped in a Map with success/data structure
      else if (list.isNotEmpty && list.first is Map) {
        final firstItem = list.first as Map<String, dynamic>;
        print('🔵 [DEBUG] Response is a Map, checking structure...');
        print('🔵 [DEBUG] Map keys: ${firstItem.keys.toList()}');
        
        // Check if it has a 'data' key with 'availableTimeSlots'
        if (firstItem.containsKey('data') && firstItem['data'] is Map) {
          final data = firstItem['data'] as Map<String, dynamic>;
          print('🔵 [DEBUG] Found data key, checking for availableTimeSlots...');
          print('🔵 [DEBUG] Data keys: ${data.keys.toList()}');
          
          if (data.containsKey('availableTimeSlots') && data['availableTimeSlots'] is List) {
            final timeSlots = data['availableTimeSlots'] as List;
            print('🔵 [DEBUG] Found availableTimeSlots: $timeSlots');
            parsedSlots = timeSlots.map((e) => e.toString()).where((time) => time.isNotEmpty).toList();
          } else {
            print('🔵 [DEBUG] ⚠️ availableTimeSlots not found in data');
          }
        }
        // Check if it's a direct Map with time slot fields
        else if (firstItem.containsKey('availableTimeSlots') && firstItem['availableTimeSlots'] is List) {
          final timeSlots = firstItem['availableTimeSlots'] as List;
          print('🔵 [DEBUG] Found availableTimeSlots directly in Map: $timeSlots');
          parsedSlots = timeSlots.map((e) => e.toString()).where((time) => time.isNotEmpty).toList();
        }
        // Try to extract individual time slots from Map entries
        else {
          print('🔵 [DEBUG] Trying to extract time slots from Map entries...');
          for (var item in list) {
            if (item is Map) {
              final time = item['time'] ?? item['slot'] ?? item['timeSlot'] ?? '';
              if (time.toString().isNotEmpty) {
                parsedSlots.add(time.toString());
              }
            } else if (item is String) {
              parsedSlots.add(item);
            }
          }
        }
      }
      // Direct list of time slot objects
      else {
        print('🔵 [DEBUG] Processing as direct list...');
        parsedSlots = list.map((e) {
          if (e is String) {
            return e;
          } else if (e is Map) {
            return (e['time'] ?? e['slot'] ?? e['timeSlot'] ?? '').toString();
          } else {
            return e.toString();
          }
        }).where((time) => time.isNotEmpty).toList();
      }
      
      print('🔵 [DEBUG] Parsed time slots: $parsedSlots');
      print('🔵 [DEBUG] Final count: ${parsedSlots.length}');
      print('🔵 [DEBUG] ========================================');
      
      return parsedSlots;
    } catch (e) {
      print('🔵 [DEBUG] ❌ Error in getAvailableTimeSlots: $e');
      print('🔵 [DEBUG] Stack trace: ${StackTrace.current}');
      print('🔵 [DEBUG] ========================================');
      rethrow;
    }
  }

  static Future<bool> isDoctorAvailable(String doctorId, DateTime date) async {
    try {
      print('🔵 [DEBUG] isDoctorAvailable() called for doctor $doctorId on ${date.toIso8601String()}');
      
      // Use the existing availability endpoint which already returns isAvailable
      final list = await _api.getJsonList('/api/doctors/$doctorId/availability', query: {
        'date': date.toIso8601String(),
      });
      
      // Check if response has the isAvailable field
      if (list.isNotEmpty && list.first is Map) {
        final firstItem = list.first as Map<String, dynamic>;
        
        // Check if it has a 'data' key with 'isAvailable'
        if (firstItem.containsKey('data') && firstItem['data'] is Map) {
          final data = firstItem['data'] as Map<String, dynamic>;
          if (data.containsKey('isAvailable')) {
            final isAvailable = data['isAvailable'] == true;
            print('🔵 [DEBUG] isAvailable from API: $isAvailable');
            return isAvailable;
          }
          // If no isAvailable field, check if there are time slots
          if (data.containsKey('availableTimeSlots') && data['availableTimeSlots'] is List) {
            final timeSlots = data['availableTimeSlots'] as List;
            final hasSlots = timeSlots.isNotEmpty;
            print('🔵 [DEBUG] No isAvailable field, checking time slots: ${timeSlots.length} slots found');
            return hasSlots;
          }
        }
        // Check if it's a direct Map with isAvailable
        else if (firstItem.containsKey('isAvailable')) {
          final isAvailable = firstItem['isAvailable'] == true;
          print('🔵 [DEBUG] isAvailable from direct Map: $isAvailable');
          return isAvailable;
        }
      }
      
      // Fallback: if we got time slots, doctor is available
      final timeSlots = await getAvailableTimeSlots(doctorId, date);
      final isAvailable = timeSlots.isNotEmpty;
      print('🔵 [DEBUG] Fallback check: ${timeSlots.length} time slots, isAvailable: $isAvailable');
      return isAvailable;
    } catch (e) {
      print('🔵 [DEBUG] ❌ Error checking doctor availability: $e');
      // If API fails, assume doctor is available (fail open)
      return true;
    }
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

  static Future<String?> getAuthToken() async {
    // If token is already in memory, return it
    if (_authToken != null) {
      print('✅ Token found in memory');
      return _authToken;
    }
    
    // Otherwise, try to load from storage
    print('🔍 Token not in memory, loading from storage...');
    _authToken = await _loadTokenFromStorage();
    if (_authToken != null) {
      print('✅ Token loaded from storage in getAuthToken()');
      print('🔍 Token length: ${_authToken!.length}');
      print('🔍 Token preview: ${_authToken!.substring(0, _authToken!.length > 50 ? 50 : _authToken!.length)}...');
    } else {
      print('⚠️ No token found in memory or storage');
    }
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
