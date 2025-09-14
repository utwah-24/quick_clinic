class HomeVisit {
  final String id;
  final String providerId;
  final String providerName;
  final String providerType; // 'doctor' or 'nurse'
  final String specialty;
  final String providerImageUrl;
  final double rating;
  final int reviewCount;
  final double price;
  final String currency;
  final String location;
  final double latitude;
  final double longitude;
  final int estimatedTravelTime; // in minutes
  final List<String> availableDays; // ['monday', 'tuesday', etc.]
  final List<String> availableTimeSlots; // ['09:00', '10:00', etc.]
  final bool isAvailable;
  final String description;
  final List<String> services; // ['diagnosis', 'prescription', 'basic care', etc.]
  final bool acceptsInsurance;
  final DateTime createdAt;

  HomeVisit({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.providerType,
    required this.specialty,
    required this.providerImageUrl,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.currency,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.estimatedTravelTime,
    required this.availableDays,
    required this.availableTimeSlots,
    required this.isAvailable,
    required this.description,
    required this.services,
    required this.acceptsInsurance,
    required this.createdAt,
  });

  factory HomeVisit.fromJson(Map<String, dynamic> json) {
    return HomeVisit(
      id: json['id'],
      providerId: json['providerId'],
      providerName: json['providerName'],
      providerType: json['providerType'],
      specialty: json['specialty'],
      providerImageUrl: json['providerImageUrl'],
      rating: json['rating'].toDouble(),
      reviewCount: json['reviewCount'],
      price: json['price'].toDouble(),
      currency: json['currency'],
      location: json['location'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      estimatedTravelTime: json['estimatedTravelTime'],
      availableDays: List<String>.from(json['availableDays']),
      availableTimeSlots: List<String>.from(json['availableTimeSlots']),
      isAvailable: json['isAvailable'],
      description: json['description'],
      services: List<String>.from(json['services']),
      acceptsInsurance: json['acceptsInsurance'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'providerName': providerName,
      'providerType': providerType,
      'specialty': specialty,
      'providerImageUrl': providerImageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'price': price,
      'currency': currency,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'estimatedTravelTime': estimatedTravelTime,
      'availableDays': availableDays,
      'availableTimeSlots': availableTimeSlots,
      'isAvailable': isAvailable,
      'description': description,
      'services': services,
      'acceptsInsurance': acceptsInsurance,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
