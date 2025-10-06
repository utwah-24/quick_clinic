import 'package:flutter/material.dart';

class DoctorRequestsScreen extends StatefulWidget {
  const DoctorRequestsScreen({super.key});

  @override
  State<DoctorRequestsScreen> createState() => _DoctorRequestsScreenState();
}

class _DoctorRequestsScreenState extends State<DoctorRequestsScreen> {
  List<AppointmentRequest> _requests = [
    AppointmentRequest(
      id: '1',
      patientName: 'Sarah Johnson',
      patientAge: 28,
      appointmentDate: '2024-01-15',
      appointmentTime: '10:00 AM',
      specialty: 'General Checkup',
      reason: 'Annual physical examination and routine blood work',
      urgency: 'Normal',
      patientPhone: '+1 234-567-8900',
      patientEmail: 'sarah.johnson@email.com',
      status: 'pending',
    ),
    AppointmentRequest(
      id: '2',
      patientName: 'Michael Chen',
      patientAge: 45,
      appointmentDate: '2024-01-15',
      appointmentTime: '02:30 PM',
      specialty: 'Follow-up',
      reason: 'Follow-up visit for blood pressure medication adjustment',
      urgency: 'High',
      patientPhone: '+1 345-678-9012',
      patientEmail: 'michael.chen@email.com',
      status: 'pending',
    ),
    AppointmentRequest(
      id: '3',
      patientName: 'Emily Rodriguez',
      patientAge: 32,
      appointmentDate: '2024-01-16',
      appointmentTime: '09:30 AM',
      specialty: 'Consultation',
      reason: 'New patient consultation for chronic headaches',
      urgency: 'Normal',
      patientPhone: '+1 456-789-0123',
      patientEmail: 'emily.rodriguez@email.com',
      status: 'pending',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(40),
              color: Colors.white ,
              // decoration: BoxDecoration(
              //   gradient: LinearGradient(
              //     begin: Alignment.topLeft,
              //     end: Alignment.bottomRight,
              //     colors: [Colors.blue[800]!, Colors.blue[400]!],
              //   ),
              // ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appointment Requests',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard('Pending', _requests.where((r) => r.status == 'pending').length.toString(), Colors.orange),
                      const SizedBox(width: 16),
                      _buildStatCard('Total', _requests.length.toString(), Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
            
            // Requests List
            Expanded(
              child: _requests.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final request = _requests[index];
                        return _buildRequestCard(request);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No pending requests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All appointment requests have been reviewed',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(AppointmentRequest request) {
    Color urgencyColor = request.urgency == 'High' ? Colors.red : Colors.orange;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with patient info and urgency
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.patientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Age: ${request.patientAge} • ${request.specialty}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: urgencyColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    request.urgency,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: urgencyColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Appointment details
            _buildDetailRow(Icons.calendar_today, 'Date & Time', '${request.appointmentDate} at ${request.appointmentTime}'),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.medical_services, 'Reason', request.reason),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.phone, 'Phone', request.patientPhone),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.email, 'Email', request.patientEmail),
            
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _declineRequest(request.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptRequest(request.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  void _acceptRequest(String requestId) {
    setState(() {
      _requests.removeWhere((request) => request.id == requestId);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appointment request accepted!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _declineRequest(String requestId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Decline Request'),
          content: const Text('Are you sure you want to decline this appointment request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _requests.removeWhere((request) => request.id == requestId);
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appointment request declined.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: const Text(
                'Decline',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AppointmentRequest {
  final String id;
  final String patientName;
  final int patientAge;
  final String appointmentDate;
  final String appointmentTime;
  final String specialty;
  final String reason;
  final String urgency;
  final String patientPhone;
  final String patientEmail;
  final String status;

  AppointmentRequest({
    required this.id,
    required this.patientName,
    required this.patientAge,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.specialty,
    required this.reason,
    required this.urgency,
    required this.patientPhone,
    required this.patientEmail,
    required this.status,
  });
}
