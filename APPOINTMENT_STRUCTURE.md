### Appointment Model Structure

This documents the `Appointment` data model used in the app.

#### Fields

```text
id                : String         // Unique identifier
hospitalId        : String         // Hospital ID
hospitalName      : String         // Hospital display name
doctorId          : String         // Doctor ID
doctorName        : String         // Doctor display name
doctorSpecialty   : String         // Doctor specialty at booking time
appointmentDate   : DateTime       // ISO 8601 string in JSON
timeSlot          : String         // Selected time slot (e.g., "10:00 - 10:30")
patientName       : String         // Patient full name
patientPhone      : String         // Patient phone number
problem           : String         // Short description of the issue
status            : AppointmentStatus  // Booking status
amount            : double         // Total amount (fee + any charges)
paymentMethod     : PaymentMethod  // Chosen payment method
paymentStatus     : PaymentStatus  // Payment state
createdAt         : DateTime       // ISO 8601 string in JSON
```

#### Enums

```text
AppointmentStatus: pending | confirmed | completed | cancelled | rescheduled
PaymentMethod    : mpesa | card | cash | insurance
PaymentStatus    : pending | paid | failed | refunded
```

#### Dart Class (reference)

```dart
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
}
```

#### Example JSON

```json
{
  "id": "apt_20250922_001",
  "hospitalId": "hosp_001",
  "hospitalName": "Quick Clinic Nairobi",
  "doctorId": "doc_123",
  "doctorName": "Dr. Jane Doe",
  "doctorSpecialty": "Cardiology",
  "appointmentDate": "2025-09-23T09:00:00.000Z",
  "timeSlot": "09:00 - 09:30",
  "patientName": "John Smith",
  "patientPhone": "+254712345678",
  "problem": "Chest discomfort and shortness of breath",
  "status": "confirmed",
  "amount": 4000.0,
  "paymentMethod": "mpesa",
  "paymentStatus": "pending",
  "createdAt": "2025-09-22T12:34:56.000Z"
}
```

Notes:
- DateTime values are serialized as ISO 8601 strings.
- Enum values use their lowercase string names in JSON.


