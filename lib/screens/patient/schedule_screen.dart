import 'package:flutter/material.dart';
import '../../widgets/dynamic_app_bar.dart';
import '../../widgets/drawer.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Upcoming', 'Completed'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(
        currentRoute: '/appointments',
        userName: 'John Doe',
        userEmail: 'john@example.com',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DynamicAppBar(title: 'Schedule'),
            // Content area
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tabs Section
                      _buildTabs(),
                      const SizedBox(height: 24),
                      
                      // Appointments List
                      _buildAppointmentsList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildTabs() {
    return Row(
      children: List.generate(_tabs.length, (index) {
        final isSelected = index == _selectedTabIndex;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTabIndex = index;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1976D2) : Colors.grey[200],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              _tabs[index],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAppointmentsList() {
    if (_selectedTabIndex == 0) {
      return _buildUpcomingAppointments();
    } else {
      return _buildCompletedAppointments();
    }
  }

  Widget _buildUpcomingAppointments() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildAppointmentSection(
          title: 'About Doctor',
          appointments: [
            AppointmentData(
              doctorName: 'Dr. Doctor Name',
              specialty: 'Therapist',
              imageUrl: 'https://via.placeholder.com/80',
              date: '12/01/2023',
              time: '10:30 AM',
              status: 'Confirmed',
              isConfirmed: true,
            ),
            AppointmentData(
              doctorName: 'Dr. Sarah Wilson',
              specialty: 'Cardiologist',
              imageUrl: 'https://via.placeholder.com/80',
              date: '12/05/2023',
              time: '2:00 PM',
              status: 'Confirmed',
              isConfirmed: true,
            ),
            AppointmentData(
              doctorName: 'Dr. Michael Brown',
              specialty: 'Pediatrician',
              imageUrl: 'https://via.placeholder.com/80',
              date: '12/08/2023',
              time: '9:00 AM',
              status: 'Pending',
              isConfirmed: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedAppointments() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildAppointmentSection(
          title: 'About Doctor',
          appointments: [
            AppointmentData(
              doctorName: 'Dr. Emily Davis',
              specialty: 'Dermatologist',
              imageUrl: 'https://via.placeholder.com/80',
              date: '11/25/2023',
              time: '11:00 AM',
              status: 'Completed',
              isConfirmed: true,
            ),
            AppointmentData(
              doctorName: 'Dr. David Wilson',
              specialty: 'Neurologist',
              imageUrl: 'https://via.placeholder.com/80',
              date: '11/20/2023',
              time: '3:30 PM',
              status: 'Completed',
              isConfirmed: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppointmentSection({
    required String title,
    required List<AppointmentData> appointments,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        ...appointments.map((appointment) => _buildAppointmentCard(appointment)),
      ],
    );
  }

  Widget _buildAppointmentCard(AppointmentData appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          // Doctor Info Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.specialty,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Doctor Profile Picture
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(appointment.imageUrl),
                  onBackgroundImageError: (exception, stackTrace) {},
                  child: appointment.imageUrl.isEmpty 
                      ? Icon(Icons.person, size: 40, color: Colors.grey[600]) 
                      : null,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Appointment Details Row
          Row(
            children: [
              // Date
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment.date,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Time
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment.time,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: appointment.isConfirmed ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        appointment.status,
                        style: TextStyle(
                          fontSize: 14,
                          color: appointment.isConfirmed ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons Row
          Row(
            children: [
              // Cancel Button
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      _showCancelDialog(context, appointment);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.grey[700],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Reschedule Button
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      _showRescheduleDialog(context, appointment);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B46C1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Reschedule',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, AppointmentData appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Cancel Appointment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          content: Text(
            'Are you sure you want to cancel your appointment with ${appointment.doctorName} on ${appointment.date} at ${appointment.time}?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'No, Keep It',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Handle cancellation logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appointment cancelled successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRescheduleDialog(BuildContext context, AppointmentData appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Reschedule Appointment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          content: Text(
            'Would you like to reschedule your appointment with ${appointment.doctorName}?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Redirecting to reschedule page...'),
                    backgroundColor: Color(0xFF1976D2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Reschedule',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AppointmentData {
  final String doctorName;
  final String specialty;
  final String imageUrl;
  final String date;
  final String time;
  final String status;
  final bool isConfirmed;

  AppointmentData({
    required this.doctorName,
    required this.specialty,
    required this.imageUrl,
    required this.date,
    required this.time,
    required this.status,
    required this.isConfirmed,
  });
}
