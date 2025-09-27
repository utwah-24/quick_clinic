import 'package:flutter/material.dart';
import '../models/hospital.dart';
import '../models/appointment.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../services/localization_service.dart';

class BookingScreen extends StatefulWidget {
  final Hospital hospital;
  final Doctor doctor;
  final PaymentMethod paymentMethod;

  const BookingScreen({
    super.key,
    required this.hospital,
    required this.doctor,
    required this.paymentMethod,
  });

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _problemController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;
  List<String> _availableTimeSlots = [];
  bool _isLoading = false;
  bool _isDoctorAvailable = true;

  @override
  void initState() {
    super.initState();
    _checkDoctorAvailability();
  }

  Future<void> _checkDoctorAvailability() async {
    setState(() => _isLoading = true);

    final isAvailable = await DataService.isDoctorAvailable(widget.doctor.id, _selectedDate);
    
    if (isAvailable) {
      final timeSlots = await DataService.getAvailableTimeSlots(widget.doctor.id, _selectedDate);
      setState(() {
        _isDoctorAvailable = true;
        _availableTimeSlots = timeSlots;
        _isLoading = false;
      });
    } else {
      final alternativeDates = await DataService.getAlternativeDates(widget.doctor.id);
      setState(() {
        _isDoctorAvailable = false;
        _isLoading = false;
      });
      
      _showAlternativeDatesDialog(alternativeDates);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(LocalizationService.translate('book_appointment')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBookingInfo(),
                    const SizedBox(height: 24),
                    if (_isDoctorAvailable) ...[
                      _buildDateSelection(),
                      const SizedBox(height: 24),
                      _buildTimeSlotSelection(),
                      const SizedBox(height: 24),
                      _buildPatientDetails(),
                      const SizedBox(height: 24),
                      _buildBookingButton(),
                    ] else
                      _buildUnavailableMessage(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBookingInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text('Hospital: ${widget.hospital.name}'),
          Text('Doctor: ${widget.doctor.name}'),
          Text('Specialty: ${widget.doctor.specialty}'),
          Text('Consultation Fee: KSh ${widget.doctor.consultationFee.toStringAsFixed(0)}'),
          const Text('Booking Fee: KSh 500'),
          const Divider(),
          Text(
            'Total: KSh ${(widget.doctor.consultationFee + 500).toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationService.translate('appointment_date'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _selectDate,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationService.translate('time_slot'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTimeSlots.map((slot) {
            return ChoiceChip(
              label: Text(slot),
              selected: _selectedTimeSlot == slot,
              onSelected: (selected) {
                setState(() {
                  _selectedTimeSlot = selected ? slot : null;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPatientDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Patient Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: LocalizationService.translate('patient_name'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter patient name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: LocalizationService.translate('phone_number'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _problemController,
          decoration: InputDecoration(
            labelText: LocalizationService.translate('problem_description'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.description),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please describe your problem';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBookingButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _selectedTimeSlot != null ? _confirmBooking : null,
        child: Text(LocalizationService.translate('confirm_booking')),
      ),
    );
  }

  Widget _buildUnavailableMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.info, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            LocalizationService.translate('doctor_not_available'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dr. ${widget.doctor.name} is not available on the selected date.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final alternativeDates = await DataService.getAlternativeDates(widget.doctor.id);
              _showAlternativeDatesDialog(alternativeDates);
            },
            child: const Text('View Alternative Dates'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null;
      });
      _checkDoctorAvailability();
    }
  }

  void _showAlternativeDatesDialog(List<DateTime> alternativeDates) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('alternative_dates')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: alternativeDates.map((date) {
            return ListTile(
              title: Text('${date.day}/${date.month}/${date.year}'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedDate = date;
                  _selectedTimeSlot = null;
                });
                _checkDoctorAvailability();
                
                NotificationService.notifyDoctorUnavailable(
                  doctorName: widget.doctor.name,
                  alternativeDate: '${date.day}/${date.month}/${date.year}',
                );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final appointment = Appointment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        hospitalId: widget.hospital.id,
        hospitalName: widget.hospital.name,
        doctorId: widget.doctor.id,
        doctorName: widget.doctor.name,
        doctorSpecialty: widget.doctor.specialty,
        appointmentDate: _selectedDate,
        timeSlot: _selectedTimeSlot!,
        patientName: _nameController.text,
        patientPhone: _phoneController.text,
        problem: _problemController.text,
        status: AppointmentStatus.confirmed,
        amount: widget.doctor.consultationFee + 500,
        paymentMethod: widget.paymentMethod,
        paymentStatus: PaymentStatus.pending,
        createdAt: DateTime.now(),
      );

      await DataService.bookAppointment(appointment);

      await NotificationService.notifyAppointmentConfirmed(
        doctorName: widget.doctor.name,
        date: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
        time: _selectedTimeSlot!,
      );

      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(LocalizationService.translate('booking_successful')),
          ],
        ),
        content: Text(LocalizationService.translate('appointment_confirmed')),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _problemController.dispose();
    super.dispose();
  }
}
