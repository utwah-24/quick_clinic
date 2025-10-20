class Hospital {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distance;
  final List<String> specialties;
  final double rating;
  final String phoneNumber;
  final List<Doctor> doctors;
  final bool hasEmergency;
  final String imageUrl;

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.specialties,
    required this.rating,
    required this.phoneNumber,
    required this.doctors,
    required this.hasEmergency,
    required this.imageUrl,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      distance: _parseDouble(json['distance']),
      specialties: (json['specialties'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
      rating: _parseDouble(json['rating']),
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      doctors: (json['doctors'] as List?)?.map((e) => Doctor.fromJson(e as Map<String, dynamic>)).toList() ?? <Doctor>[],
      hasEmergency: json['hasEmergency'] == true || json['hasEmergency'] == 1 || json['hasEmergency'] == 'true',
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'distance': distance,
        'specialties': specialties,
        'rating': rating,
        'phoneNumber': phoneNumber,
        'doctors': doctors.map((d) => d.toJson()).toList(),
        'hasEmergency': hasEmergency,
        'imageUrl': imageUrl,
      };
}

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String qualification;
  final int experience;
  final double rating;
  final String imageUrl;
  final List<String> availableDays;
  final String availableTime;
  final double consultationFee;
  final String bio;
  final List<String> languages;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.qualification,
    required this.experience,
    required this.rating,
    required this.imageUrl,
    required this.availableDays,
    required this.availableTime,
    required this.consultationFee,
    required this.bio,
    required this.languages,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      qualification: json['qualification'] ?? '',
      experience: (json['experience'] ?? 0) is int ? json['experience'] : int.tryParse(json['experience']?.toString() ?? '0') ?? 0,
      rating: _parseDouble(json['rating']),
      imageUrl: json['imageUrl']?.toString() ?? '',
      availableDays: (json['availableDays'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
      availableTime: json['availableTime']?.toString() ?? '',
      consultationFee: _parseDouble(json['consultationFee']),
      bio: json['bio']?.toString() ?? '',
      languages: (json['languages'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'specialty': specialty,
        'qualification': qualification,
        'experience': experience,
        'rating': rating,
        'imageUrl': imageUrl,
        'availableDays': availableDays,
        'availableTime': availableTime,
        'consultationFee': consultationFee,
        'bio': bio,
        'languages': languages,
      };
}
