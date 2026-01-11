import 'package:flutter/material.dart';
import '../../models/hospital.dart';
import '../../models/appointment.dart';
import '../../models/payment_method.dart';
import '../../models/user.dart';
import '../../services/data_service.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../../services/localization_service.dart';

class AppointmentSummaryScreen extends StatefulWidget {
  final Hospital hospital;
  final Doctor doctor;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final double amount;

  const AppointmentSummaryScreen({
    super.key,
    required this.hospital,
    required this.doctor,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.amount,
  });

  @override
  _AppointmentSummaryScreenState createState() => _AppointmentSummaryScreenState();
}

class _AppointmentSummaryScreenState extends State<AppointmentSummaryScreen> {
  PaymentMethod? _selectedPaymentMethod;
  PaymentMethodDetails? _selectedCard;
  List<PaymentMethodDetails> _paymentMethods = [];
  bool _isLoading = false;
  bool _isLoadingPaymentMethods = true;

  static const Color _brandColor = Color(0xFF0B2D5B);

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
    _verifyToken();
  }

  Future<void> _verifyToken() async {
    // Verify token is available before user tries to book
    final token = await DataService.getAuthToken();
    if (token == null) {
      print('⚠️ WARNING: No auth token found in summary screen');
    } else {
      print('✅ Token verified in summary screen: ${token.substring(0, 20)}...');
    }
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _isLoadingPaymentMethods = true);
    try {
      final methods = await DataService.getPaymentMethods();
      setState(() {
        _paymentMethods = methods;
        // Set default payment method
        if (methods.isNotEmpty) {
          final defaultMethod = methods.firstWhere(
            (m) => m.isDefault,
            orElse: () => methods.first,
          );
          if (defaultMethod.type == 'credit_card') {
            _selectedCard = defaultMethod;
            _selectedPaymentMethod = PaymentMethod.card;
          } else if (defaultMethod.type == 'nida') {
            _selectedPaymentMethod = PaymentMethod.insurance; // Using insurance as placeholder for nida
          }
        } else {
          // Default to cash if no payment methods
          _selectedPaymentMethod = PaymentMethod.cash;
        }
        _isLoadingPaymentMethods = false;
      });
    } catch (e) {
      print('Error loading payment methods: $e');
      setState(() {
        _selectedPaymentMethod = PaymentMethod.cash;
        _isLoadingPaymentMethods = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = DataService.getCurrentUser();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Appointment Summary',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(user),
            const SizedBox(height: 24),
            _buildPaymentSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: _buildSendAppointmentButton(),
      ),
    );
  }

  Widget _buildSummaryCard(User? user) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointment Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          _buildSummaryRow('Doctor', widget.doctor.name),
          const Divider(height: 24),
          _buildSummaryRow('Specialty', widget.doctor.specialty),
          const Divider(height: 24),
          _buildSummaryRow('Hospital', widget.hospital.name),
          const Divider(height: 24),
          _buildSummaryRow('Date', _formatDate(widget.selectedDate)),
          const Divider(height: 24),
          _buildSummaryRow('Time', widget.selectedTimeSlot),
          const Divider(height: 24),
          _buildSummaryRow('Patient', user?.name ?? 'N/A'),
          const Divider(height: 24),
          _buildSummaryRow('Phone', user?.phone ?? 'N/A'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'TZS ${widget.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _brandColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingPaymentMethods)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                _buildPaymentOption(
                  PaymentMethod.cash,
                  'Cash',
                  Icons.money,
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildCardPaymentOption(),
                const SizedBox(height: 12),
                _buildNidaPaymentOption(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    PaymentMethod method,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedPaymentMethod == method;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
          if (method != PaymentMethod.card) {
            _selectedCard = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: Colors.black,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24)
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[400]!, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPaymentOption() {
    final cardMethods = _paymentMethods.where((m) => m.type == 'credit_card').toList();
    final isSelected = _selectedPaymentMethod == PaymentMethod.card;
    
    if (cardMethods.isEmpty) {
      return GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No card payment methods available. Please add a card in settings.'),
              backgroundColor: Colors.orange,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.credit_card, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Card (No cards available)',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedPaymentMethod = PaymentMethod.card;
              if (_selectedCard == null && cardMethods.isNotEmpty) {
                _selectedCard = cardMethods.firstWhere(
                  (m) => m.isDefault,
                  orElse: () => cardMethods.first,
                );
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.credit_card, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Card',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      if (_selectedCard != null)
                        Text(
                          _selectedCard!.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.blue, size: 24)
                else
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[400]!, width: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isSelected && cardMethods.length > 1) ...[
          const SizedBox(height: 8),
          ...cardMethods.map((card) {
            final isCardSelected = _selectedCard?.id == card.id;
            return Padding(
              padding: const EdgeInsets.only(left: 56, top: 4),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCard = card;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCardSelected ? Colors.blue.withOpacity(0.05) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCardSelected ? Colors.blue : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCardSelected ? Colors.blue : Colors.transparent,
                          border: Border.all(
                            color: isCardSelected ? Colors.blue : Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: isCardSelected
                            ? const Icon(Icons.check, size: 10, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          card.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCardSelected ? FontWeight.w600 : FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildNidaPaymentOption() {
    final nidaMethods = _paymentMethods.where((m) => m.type == 'nida').toList();
    final isSelected = _selectedPaymentMethod == PaymentMethod.insurance; // Using insurance as placeholder
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = PaymentMethod.insurance; // Using insurance enum for nida
          _selectedCard = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.badge, color: Colors.purple, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NIDA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (nidaMethods.isNotEmpty && nidaMethods.first.nidaNumber != null)
                    Text(
                      'NIDA: ${nidaMethods.first.nidaNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.purple, size: 24)
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[400]!, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendAppointmentButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_selectedPaymentMethod != null && !_isLoading) ? _sendAppointment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Send Appointment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _sendAppointment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = DataService.getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to book an appointment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create appointment with payment method
      // Note: If NIDA was selected (using insurance enum as placeholder), 
      // we'll send "nida" to the API in the toJson method
      final appointment = Appointment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        hospitalId: widget.hospital.id,
        hospitalName: widget.hospital.name,
        doctorId: widget.doctor.id,
        doctorName: widget.doctor.name,
        doctorSpecialty: widget.doctor.specialty,
        appointmentDate: widget.selectedDate,
        timeSlot: widget.selectedTimeSlot,
        patientName: user.name,
        patientPhone: user.phone,
        problem: user.medicalHistory.isNotEmpty 
            ? user.medicalHistory.join(', ') 
            : 'General consultation',
        status: AppointmentStatus.pending,
        amount: widget.amount,
        paymentMethod: _selectedPaymentMethod!,
        paymentStatus: PaymentStatus.pending,
        createdAt: DateTime.now(),
      );

      // Send appointment to API
      // If NIDA was selected (using insurance enum as placeholder), 
      // we need to send "nida" to the API instead of "insurance"
      final token = await DataService.getAuthToken();
      if (token == null) {
        throw Exception('Authentication required. Please login to book an appointment.');
      }
      
      print('🔵 [DEBUG] Using auth token: ${token.substring(0, 20)}...');

      // Validate that the appointment date is at least tomorrow
      // Backend requires date to be "after today" (strictly greater than today)
      final today = DateTime.now();
      final selectedDateOnly = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
      final todayOnly = DateTime(today.year, today.month, today.day);
      
      if (selectedDateOnly.isBefore(todayOnly) || selectedDateOnly.isAtSameMomentAs(todayOnly)) {
        throw Exception('Appointment date must be after today. Please select a future date.');
      }

      final appointmentJson = appointment.toJson();
      
      // Override appointmentDate to be date-only (YYYY-MM-DD) format
      // The backend combines this with timeSlot, so we need date-only
      final dateOnly = '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}';
      appointmentJson['appointmentDate'] = dateOnly;
      
      // Override payment method to "nida" if NIDA was selected
      if (_selectedPaymentMethod == PaymentMethod.insurance && 
          _paymentMethods.any((m) => m.type == 'nida')) {
        appointmentJson['paymentMethod'] = 'nida';
      }

      // Use ApiClient directly to send the appointment with correct payment method
      final api = ApiClient();
      final response = await api.postJsonWithAuth('/api/appointments', appointmentJson, token);
      
      // Extract appointment ID from response
      final appointmentId = (response['id'] ?? response['appointmentId'] ?? appointment.id).toString();
      print('✅ Appointment booked successfully with ID: $appointmentId');

      Appointment? savedAppointment;
      if (response['data'] is Map<String, dynamic>) {
        try {
          final responseData = response['data'] as Map<String, dynamic>;
          savedAppointment = Appointment.fromJson(responseData);
          // Ensure doctor info is preserved if API doesn't return it
          if (savedAppointment.doctorName.isEmpty) {
            savedAppointment = Appointment(
              id: savedAppointment.id,
              hospitalId: savedAppointment.hospitalId.isEmpty ? appointment.hospitalId : savedAppointment.hospitalId,
              hospitalName: savedAppointment.hospitalName.isEmpty ? appointment.hospitalName : savedAppointment.hospitalName,
              doctorId: savedAppointment.doctorId.isEmpty ? appointment.doctorId : savedAppointment.doctorId,
              doctorName: appointment.doctorName, // Use original doctor name
              doctorSpecialty: savedAppointment.doctorSpecialty.isEmpty ? appointment.doctorSpecialty : savedAppointment.doctorSpecialty,
              appointmentDate: savedAppointment.appointmentDate,
              timeSlot: savedAppointment.timeSlot.isEmpty ? appointment.timeSlot : savedAppointment.timeSlot,
              patientName: savedAppointment.patientName.isEmpty ? appointment.patientName : savedAppointment.patientName,
              patientPhone: savedAppointment.patientPhone.isEmpty ? appointment.patientPhone : savedAppointment.patientPhone,
              problem: savedAppointment.problem.isEmpty ? appointment.problem : savedAppointment.problem,
              status: savedAppointment.status,
              amount: savedAppointment.amount == 0 ? appointment.amount : savedAppointment.amount,
              paymentMethod: savedAppointment.paymentMethod,
              paymentStatus: savedAppointment.paymentStatus,
              createdAt: savedAppointment.createdAt,
            );
          }
          print('✅ Parsed appointment from response data - Doctor: ${savedAppointment.doctorName}');
        } catch (e) {
          print('⚠️ Unable to parse appointment from response data: $e');
          print('   Response data: ${response['data']}');
        }
      }

      if (savedAppointment == null) {
        try {
          savedAppointment = Appointment.fromJson(response);
          // Ensure doctor info is preserved if API doesn't return it
          if (savedAppointment.doctorName.isEmpty) {
            savedAppointment = Appointment(
              id: savedAppointment.id,
              hospitalId: savedAppointment.hospitalId.isEmpty ? appointment.hospitalId : savedAppointment.hospitalId,
              hospitalName: savedAppointment.hospitalName.isEmpty ? appointment.hospitalName : savedAppointment.hospitalName,
              doctorId: savedAppointment.doctorId.isEmpty ? appointment.doctorId : savedAppointment.doctorId,
              doctorName: appointment.doctorName, // Use original doctor name
              doctorSpecialty: savedAppointment.doctorSpecialty.isEmpty ? appointment.doctorSpecialty : savedAppointment.doctorSpecialty,
              appointmentDate: savedAppointment.appointmentDate,
              timeSlot: savedAppointment.timeSlot.isEmpty ? appointment.timeSlot : savedAppointment.timeSlot,
              patientName: savedAppointment.patientName.isEmpty ? appointment.patientName : savedAppointment.patientName,
              patientPhone: savedAppointment.patientPhone.isEmpty ? appointment.patientPhone : savedAppointment.patientPhone,
              problem: savedAppointment.problem.isEmpty ? appointment.problem : savedAppointment.problem,
              status: savedAppointment.status,
              amount: savedAppointment.amount == 0 ? appointment.amount : savedAppointment.amount,
              paymentMethod: savedAppointment.paymentMethod,
              paymentStatus: savedAppointment.paymentStatus,
              createdAt: savedAppointment.createdAt,
            );
          }
          print('✅ Parsed appointment from root response - Doctor: ${savedAppointment.doctorName}');
        } catch (e) {
          print('⚠️ Unable to parse appointment from root response: $e');
          print('   Response: $response');
        }
      }

      // Always use the original appointment data to ensure doctor info is preserved
      savedAppointment ??= Appointment(
        id: appointmentId.isNotEmpty ? appointmentId : appointment.id,
        hospitalId: appointment.hospitalId,
        hospitalName: appointment.hospitalName,
        doctorId: appointment.doctorId,
        doctorName: appointment.doctorName,
        doctorSpecialty: appointment.doctorSpecialty,
        appointmentDate: appointment.appointmentDate,
        timeSlot: appointment.timeSlot,
        patientName: appointment.patientName,
        patientPhone: appointment.patientPhone,
        problem: appointment.problem,
        status: appointment.status,
        amount: appointment.amount,
        paymentMethod: appointment.paymentMethod,
        paymentStatus: appointment.paymentStatus,
        createdAt: appointment.createdAt,
      );

      // Final check: ensure doctor name is not empty
      if (savedAppointment.doctorName.isEmpty) {
        print('⚠️ WARNING: Doctor name is empty, using widget.doctor.name');
        savedAppointment = Appointment(
          id: savedAppointment.id,
          hospitalId: savedAppointment.hospitalId.isEmpty ? widget.hospital.id : savedAppointment.hospitalId,
          hospitalName: savedAppointment.hospitalName.isEmpty ? widget.hospital.name : savedAppointment.hospitalName,
          doctorId: savedAppointment.doctorId.isEmpty ? widget.doctor.id : savedAppointment.doctorId,
          doctorName: widget.doctor.name, // Force use original doctor name
          doctorSpecialty: savedAppointment.doctorSpecialty.isEmpty ? widget.doctor.specialty : savedAppointment.doctorSpecialty,
          appointmentDate: savedAppointment.appointmentDate,
          timeSlot: savedAppointment.timeSlot.isEmpty ? widget.selectedTimeSlot : savedAppointment.timeSlot,
          patientName: savedAppointment.patientName,
          patientPhone: savedAppointment.patientPhone,
          problem: savedAppointment.problem,
          status: savedAppointment.status,
          amount: savedAppointment.amount == 0 ? widget.amount : savedAppointment.amount,
          paymentMethod: savedAppointment.paymentMethod,
          paymentStatus: savedAppointment.paymentStatus,
          createdAt: savedAppointment.createdAt,
        );
      }

      print('💾 Saving appointment: ${savedAppointment.doctorName} (ID: ${savedAppointment.id})');
      DataService.addOrUpdateUserAppointment(savedAppointment);

      await NotificationService.notifyAppointmentConfirmed(
        doctorName: widget.doctor.name,
        date: '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
        time: widget.selectedTimeSlot,
        appointmentId: savedAppointment.id,
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

