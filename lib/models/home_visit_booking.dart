class HomeVisitBooking {
  final String id;
  final String homeVisitId;
  final String providerId;
  final String providerName;
  final String providerType;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String patientAddress;
  final double patientLatitude;
  final double patientLongitude;
  final DateTime scheduledDate;
  final String timeSlot;
  final String visitReason;
  final String symptoms;
  final double amount;
  final String currency;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final String? notes;
  final DateTime? actualVisitTime;
  final DateTime? completedTime;
  final DateTime createdAt;

  HomeVisitBooking({
    required this.id,
    required this.homeVisitId,
    required this.providerId,
    required this.providerName,
    required this.providerType,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.patientAddress,
    required this.patientLatitude,
    required this.patientLongitude,
    required this.scheduledDate,
    required this.timeSlot,
    required this.visitReason,
    required this.symptoms,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentStatus,
    this.notes,
    this.actualVisitTime,
    this.completedTime,
    required this.createdAt,
  });

  factory HomeVisitBooking.fromJson(Map<String, dynamic> json) {
    return HomeVisitBooking(
      id: json['id'],
      homeVisitId: json['homeVisitId'],
      providerId: json['providerId'],
      providerName: json['providerName'],
      providerType: json['providerType'],
      patientId: json['patientId'],
      patientName: json['patientName'],
      patientPhone: json['patientPhone'],
      patientAddress: json['patientAddress'],
      patientLatitude: json['patientLatitude'].toDouble(),
      patientLongitude: json['patientLongitude'].toDouble(),
      scheduledDate: DateTime.parse(json['scheduledDate']),
      timeSlot: json['timeSlot'],
      visitReason: json['visitReason'],
      symptoms: json['symptoms'],
      amount: json['amount'].toDouble(),
      currency: json['currency'],
      status: BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['paymentStatus'],
      ),
      notes: json['notes'],
      actualVisitTime: json['actualVisitTime'] != null 
          ? DateTime.parse(json['actualVisitTime']) 
          : null,
      completedTime: json['completedTime'] != null 
          ? DateTime.parse(json['completedTime']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeVisitId': homeVisitId,
      'providerId': providerId,
      'providerName': providerName,
      'providerType': providerType,
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'patientAddress': patientAddress,
      'patientLatitude': patientLatitude,
      'patientLongitude': patientLongitude,
      'scheduledDate': scheduledDate.toIso8601String(),
      'timeSlot': timeSlot,
      'visitReason': visitReason,
      'symptoms': symptoms,
      'amount': amount,
      'currency': currency,
      'status': status.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'notes': notes,
      'actualVisitTime': actualVisitTime?.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rescheduled,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
}
