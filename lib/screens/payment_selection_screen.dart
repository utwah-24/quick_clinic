import 'package:flutter/material.dart';
import 'doctor_selection_screen.dart';
import '../models/hospital.dart';
import '../models/appointment.dart';
import '../services/localization_service.dart';

class PaymentSelectionScreen extends StatefulWidget {
  final Hospital hospital;

  const PaymentSelectionScreen({super.key, required this.hospital});

  @override
  _PaymentSelectionScreenState createState() => _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState extends State<PaymentSelectionScreen> {
  PaymentMethod? _selectedPaymentMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.translate('payment_method')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHospitalInfo(),
            const SizedBox(height: 32),
            _buildPaymentInfo(),
            const SizedBox(height: 24),
            _buildPaymentMethods(),
            const SizedBox(height: 100), // Space for button
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: _buildContinueButton(),
      ),
    );
  }

  Widget _buildHospitalInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_hospital, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text(
                'Selected Hospital',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.hospital.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(widget.hospital.address),
          Text('Rating: ${widget.hospital.rating} ⭐'),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
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
          const Icon(Icons.payment, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            'Booking Fee Required',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'KSh 500 booking fee to secure your appointment',
            style: TextStyle(
              fontSize: 16,
              color: Colors.orange[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '(This prevents no-shows and ensures doctor availability)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationService.translate('payment_method'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildPaymentOption(
          PaymentMethod.mpesa,
          LocalizationService.translate('mpesa'),
          Icons.phone_android,
          Colors.green,
          'Pay via M-Pesa mobile money',
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          PaymentMethod.card,
          LocalizationService.translate('card'),
          Icons.credit_card,
          Colors.blue,
          'Pay with credit or debit card',
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          PaymentMethod.cash,
          LocalizationService.translate('cash'),
          Icons.money,
          Colors.orange,
          'Pay cash at the hospital',
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          PaymentMethod.insurance,
          LocalizationService.translate('insurance'),
          Icons.security,
          Colors.purple,
          'Use health insurance coverage',
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    PaymentMethod method,
    String title,
    IconData icon,
    Color color,
    String description,
  ) {
    return Card(
      child: RadioListTile<PaymentMethod>(
        value: method,
        groupValue: _selectedPaymentMethod,
        onChanged: (PaymentMethod? value) {
          setState(() {
            _selectedPaymentMethod = value;
          });
        },
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        activeColor: color,
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _selectedPaymentMethod != null ? _continueToBooking : null,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_forward),
            SizedBox(width: 8),
            Text('Continue to Book Appointment'),
          ],
        ),
      ),
    );
  }

  void _continueToBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorSelectionScreen(
          hospital: widget.hospital,
          paymentMethod: _selectedPaymentMethod!,
        ),
      ),
    );
  }
}
