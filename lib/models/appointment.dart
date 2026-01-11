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
    // Handle nested doctor object (API might return doctor as an object)
    String? doctorName;
    String? doctorSpecialty;
    String? doctorId;
    
    if (json['doctor'] is Map<String, dynamic>) {
      final doctor = json['doctor'] as Map<String, dynamic>;
      doctorName = doctor['name']?.toString() ?? 
                   doctor['doctorName']?.toString() ?? 
                   json['doctorName']?.toString();
      doctorSpecialty = doctor['specialty']?.toString() ?? 
                        doctor['specialization']?.toString() ?? 
                        doctor['doctorSpecialty']?.toString() ?? 
                        json['doctorSpecialty']?.toString();
      doctorId = doctor['id']?.toString() ?? 
                 doctor['doctorId']?.toString() ?? 
                 json['doctorId']?.toString();
    } else {
      // Try direct fields
      doctorName = json['doctorName']?.toString();
      doctorSpecialty = json['doctorSpecialty']?.toString();
      doctorId = json['doctorId']?.toString();
    }
    
    // Handle nested hospital object
    String? hospitalName;
    String? hospitalId;
    
    if (json['hospital'] is Map<String, dynamic>) {
      final hospital = json['hospital'] as Map<String, dynamic>;
      hospitalName = hospital['name']?.toString() ?? json['hospitalName']?.toString();
      hospitalId = hospital['id']?.toString() ?? json['hospitalId']?.toString();
    } else {
      hospitalName = json['hospitalName']?.toString();
      hospitalId = json['hospitalId']?.toString();
    }

    // Handle amount - can be string or number
    double amount = 0;
    if (json['amount'] != null) {
      if (json['amount'] is String) {
        amount = double.tryParse(json['amount'] as String) ?? 0;
      } else if (json['amount'] is num) {
        amount = (json['amount'] as num).toDouble();
      }
    }

    return Appointment(
      id: json['id']?.toString() ?? '',
      hospitalId: hospitalId ?? '',
      hospitalName: hospitalName ?? '',
      doctorId: doctorId ?? '',
      doctorName: doctorName ?? '',
      doctorSpecialty: doctorSpecialty ?? '',
      appointmentDate: DateTime.tryParse(json['appointmentDate']?.toString() ?? '') ?? DateTime.now(),
      timeSlot: json['timeSlot']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? '',
      patientPhone: json['patientPhone']?.toString() ?? '',
      problem: json['problem']?.toString() ?? '',
      status: _mapAppointmentStatus(json['status']?.toString()),
      amount: amount,
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
