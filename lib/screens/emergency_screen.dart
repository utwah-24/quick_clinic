import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/localization_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  _EmergencyScreenState createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedEmergencyType = 'medical';
  bool _isRequestingAmbulance = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final content = Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red[50]!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEmergencyHeader(),
                const SizedBox(height: 32),
                _buildQuickEmergencyButtons(),
                const SizedBox(height: 32),
                _buildEmergencyForm(),
                const SizedBox(height: 32),
                _buildRequestAmbulanceButton(),
              ],
            ),
          ),
        ),
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: content,
        ),
      ),
    );
  }

  Widget _buildEmergencyHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.emergency, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            LocalizationService.translate('emergency'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Emergency services available 24/7',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickEmergencyButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Emergency Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.phone,
                title: 'Call 911',
                color: Colors.red,
                onTap: _callEmergencyServices,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.local_hospital,
                title: 'Nearest Hospital',
                color: Colors.blue,
                onTap: _findNearestHospital,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationService.translate('ambulance_request'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildEmergencyTypeSelection(),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Patient Name',
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
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Emergency Description',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.description),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please describe the emergency';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmergencyTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Type:', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Medical'),
                selected: _selectedEmergencyType == 'medical',
                onSelected: (selected) {
                  setState(() {
                    _selectedEmergencyType = 'medical';
                  });
                },
                selectedColor: Colors.red[100],
                checkmarkColor: Colors.red[700],
                labelStyle: TextStyle(
                  color: _selectedEmergencyType == 'medical' 
                      ? Colors.red[700] 
                      : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              ChoiceChip(
                label: const Text('Accident'),
                selected: _selectedEmergencyType == 'accident',
                onSelected: (selected) {
                  setState(() {
                    _selectedEmergencyType = 'accident';
                  });
                },
                selectedColor: Colors.red[100],
                checkmarkColor: Colors.red[700],
                labelStyle: TextStyle(
                  color: _selectedEmergencyType == 'accident' 
                      ? Colors.red[700] 
                      : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              ChoiceChip(
                label: const Text('Fire'),
                selected: _selectedEmergencyType == 'fire',
                onSelected: (selected) {
                  setState(() {
                    _selectedEmergencyType = 'fire';
                  });
                },
                selectedColor: Colors.red[100],
                checkmarkColor: Colors.red[700],
                labelStyle: TextStyle(
                  color: _selectedEmergencyType == 'fire' 
                      ? Colors.red[700] 
                      : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              ChoiceChip(
                label: const Text('Other'),
                selected: _selectedEmergencyType == 'other',
                onSelected: (selected) {
                  setState(() {
                    _selectedEmergencyType = 'other';
                  });
                },
                selectedColor: Colors.red[100],
                checkmarkColor: Colors.red[700],
                labelStyle: TextStyle(
                  color: _selectedEmergencyType == 'other' 
                      ? Colors.red[700] 
                      : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestAmbulanceButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isRequestingAmbulance ? null : _requestAmbulance,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        child: _isRequestingAmbulance
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Requesting Ambulance...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_hospital),
                  const SizedBox(width: 8),
                  Text(LocalizationService.translate('ambulance_request')),
                ],
              ),
      ),
    );
  }

  void _callEmergencyServices() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Call'),
        content: const Text('This would dial emergency services (911/999) in a real app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _findNearestHospital() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nearest Hospital'),
        content: const Text('This would show directions to the nearest hospital with emergency services.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestAmbulance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRequestingAmbulance = true);

    try {
      // Simulate ambulance request
      await Future.delayed(const Duration(seconds: 3));

      await NotificationService.notifyEmergencyResponse(
        message: 'Ambulance dispatched! ETA: 8-12 minutes',
      );

      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Emergency request failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isRequestingAmbulance = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Emergency Request Sent'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🚨 Emergency services have been notified!'),
            const SizedBox(height: 12),
            Text('Patient: ${_nameController.text}'),
            Text('Phone: ${_phoneController.text}'),
            Text('Type: $_selectedEmergencyType'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🚑 Ambulance dispatched!\nEstimated arrival: 8-12 minutes',
                style: TextStyle(
                  color: Colors.green[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
