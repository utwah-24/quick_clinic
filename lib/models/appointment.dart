class Appointment {
  final String id;
  final String hospitalId;
  final String hospitalName;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final DateTime appointmentDate;
  final String timeSlot;
  final String patientName;
  final String patientPhone;
  final String problem;
  final AppointmentStatus status;
  final double amount;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.hospitalId,
    required this.hospitalName,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.appointmentDate,
    required this.timeSlot,
    required this.patientName,
    required this.patientPhone,
    required this.problem,
    required this.status,
    required this.amount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id']?.toString() ?? '',
      hospitalId: json['hospitalId']?.toString() ?? '',
      hospitalName: json['hospitalName']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      doctorName: json['doctorName']?.toString() ?? '',
      doctorSpecialty: json['doctorSpecialty']?.toString() ?? '',
      appointmentDate: DateTime.tryParse(json['appointmentDate']?.toString() ?? '') ?? DateTime.now(),
      timeSlot: json['timeSlot']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? '',
      patientPhone: json['patientPhone']?.toString() ?? '',
      problem: json['problem']?.toString() ?? '',
      status: _mapAppointmentStatus(json['status']?.toString()),
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: _mapPaymentMethod(json['paymentMethod']?.toString()),
      paymentStatus: _mapPaymentStatus(json['paymentStatus']?.toString()),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hospitalId': hospitalId,
        'hospitalName': hospitalName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'doctorSpecialty': doctorSpecialty,
        'appointmentDate': appointmentDate.toIso8601String(),
        'timeSlot': timeSlot,
        'patientName': patientName,
        'patientPhone': patientPhone,
        'problem': problem,
        'status': status.toString().split('.').last,
        'amount': amount,
        'paymentMethod': paymentMethod.toString().split('.').last,
        'paymentStatus': paymentStatus.toString().split('.').last,
        'createdAt': createdAt.toIso8601String(),
      };
}

enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  rescheduled,
}

enum PaymentMethod {
  mpesa,
  card,
  cash,
  insurance,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
}

AppointmentStatus _mapAppointmentStatus(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'pending':
      return AppointmentStatus.pending;
    case 'confirmed':
      return AppointmentStatus.confirmed;
    case 'completed':
      return AppointmentStatus.completed;
    case 'cancelled':
      return AppointmentStatus.cancelled;
    case 'rescheduled':
      return AppointmentStatus.rescheduled;
    default:
      return AppointmentStatus.pending;
  }
}

PaymentMethod _mapPaymentMethod(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'mpesa':
      return PaymentMethod.mpesa;
    case 'card':
      return PaymentMethod.card;
    case 'cash':
      return PaymentMethod.cash;
    case 'insurance':
      return PaymentMethod.insurance;
    default:
      return PaymentMethod.cash;
  }
}

PaymentStatus _mapPaymentStatus(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'pending':
      return PaymentStatus.pending;
    case 'paid':
      return PaymentStatus.paid;
    case 'failed':
      return PaymentStatus.failed;
    case 'refunded':
      return PaymentStatus.refunded;
    default:
      return PaymentStatus.pending;
  }
}
