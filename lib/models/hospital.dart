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
}
