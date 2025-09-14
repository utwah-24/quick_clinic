class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime dateOfBirth;
  final String gender;
  final String address;
  final String emergencyContact;
  final String emergencyContactPhone;
  final List<String> medicalHistory;
  final List<String> allergies;
  final String bloodGroup;
  final String profileImageUrl;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.gender,
    required this.address,
    required this.emergencyContact,
    required this.emergencyContactPhone,
    required this.medicalHistory,
    required this.allergies,
    required this.bloodGroup,
    required this.profileImageUrl,
    required this.createdAt,
  });
}
