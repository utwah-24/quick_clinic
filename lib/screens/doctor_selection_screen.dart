import 'package:flutter/material.dart';
import 'booking_screen.dart';
import '../models/hospital.dart';
import '../models/appointment.dart';
import '../services/localization_service.dart';

class DoctorSelectionScreen extends StatefulWidget {
  final Hospital hospital;
  final PaymentMethod paymentMethod;

  const DoctorSelectionScreen({
    super.key,
    required this.hospital,
    required this.paymentMethod,
  });

  @override
  _DoctorSelectionScreenState createState() => _DoctorSelectionScreenState();
}

class _DoctorSelectionScreenState extends State<DoctorSelectionScreen> {
  String? _selectedSpecialty;
  Doctor? _selectedDoctor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Doctor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHospitalInfo(),
            const SizedBox(height: 24),
            _buildSpecialtySelection(),
            const SizedBox(height: 24),
            if (_selectedSpecialty != null) _buildDoctorsList(),
            const Spacer(),
            if (_selectedDoctor != null) _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.hospital.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(widget.hospital.address),
          Text('Payment: ${_getPaymentMethodString(widget.paymentMethod)}'),
        ],
      ),
    );
  }

  Widget _buildSpecialtySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationService.translate('doctor_specialties'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildSpecialtyCard('General Medicine', Icons.person, Colors.blue),
        const SizedBox(height: 8),
        _buildSpecialtyCard('Ophthalmology', Icons.visibility, Colors.green),
        const SizedBox(height: 8),
        _buildSpecialtyCard('Cardiology', Icons.favorite, Colors.red),
      ],
    );
  }

  Widget _buildSpecialtyCard(String specialty, IconData icon, Color color) {
    final isSelected = _selectedSpecialty == specialty;
    final doctorsInSpecialty = widget.hospital.doctors
        .where((d) => d.specialty.contains(specialty.split(' ')[0]))
        .toList();

    return Card(
      color: isSelected ? color.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSpecialty = specialty;
            _selectedDoctor = null;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      specialty,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${doctorsInSpecialty.length} doctor(s) available',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorsList() {
    final doctorsInSpecialty = widget.hospital.doctors
        .where((d) => d.specialty.contains(_selectedSpecialty!.split(' ')[0]))
        .toList();

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Doctors',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: doctorsInSpecialty.length,
              itemBuilder: (context, index) {
                final doctor = doctorsInSpecialty[index];
                return _buildDoctorCard(doctor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    final isSelected = _selectedDoctor?.id == doctor.id;

    return Card(
      color: isSelected ? const Color(0xFF2E7D32).withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDoctor = doctor;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.network(
                  doctor.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: Icon(Icons.person, color: Colors.grey[600]),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(doctor.qualification),
                    Text('${doctor.experience} years experience'),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.orange),
                        Text(' ${doctor.rating}'),
                        const SizedBox(width: 16),
                        Text('KSh ${doctor.consultationFee.toStringAsFixed(0)}'),
                      ],
                    ),
                    Text(
                      doctor.availableTime,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingScreen(
                hospital: widget.hospital,
                doctor: _selectedDoctor!,
                paymentMethod: widget.paymentMethod,
              ),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 8),
            Text(LocalizationService.translate('book_appointment')),
          ],
        ),
      ),
    );
  }

  String _getPaymentMethodString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.insurance:
        return 'Insurance';
    }
  }
}
