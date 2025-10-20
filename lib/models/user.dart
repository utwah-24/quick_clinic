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

  factory User.fromJson(Map<String, dynamic> json) {
    final String imageUrl = json['profileImageUrl']?.toString() ?? '';
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      dateOfBirth: DateTime.tryParse(json['dateOfBirth']?.toString() ?? '') ?? DateTime.now(),
      gender: json['gender']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      emergencyContact: json['emergencyContact']?.toString() ?? '',
      emergencyContactPhone: json['emergencyContactPhone']?.toString() ?? '',
      medicalHistory: (json['medicalHistory'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
      allergies: (json['allergies'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
      bloodGroup: json['bloodGroup']?.toString() ?? '',
      profileImageUrl: imageUrl,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'gender': gender,
        'address': address,
        'emergencyContact': emergencyContact,
        'emergencyContactPhone': emergencyContactPhone,
        'medicalHistory': medicalHistory,
        'allergies': allergies,
        'bloodGroup': bloodGroup,
        'profileImageUrl': profileImageUrl,
        'createdAt': createdAt.toIso8601String(),
      };
}
