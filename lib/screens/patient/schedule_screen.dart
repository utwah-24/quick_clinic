import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../services/data_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/drawer.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Upcoming', 'Completed'];
  List<Appointment> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  bool _isLoadingAppointments = false;

  Future<void> _loadAppointments() async {
    if (_isLoadingAppointments) return; // Prevent multiple simultaneous loads
    
    setState(() {
      _isLoading = true;
      _isLoadingAppointments = true;
    });

    try {
      // First load from cache for immediate display
      final cachedAppointments = DataService.getUserAppointments();
      if (cachedAppointments.isNotEmpty && mounted) {
        setState(() {
          _appointments = List<Appointment>.from(cachedAppointments);
          _isLoading = false;
          _isLoadingAppointments = false;
        });
        print('📋 Loaded ${_appointments.length} cached appointments');
        for (var apt in _appointments) {
          print('  - ${apt.doctorName} (ID: ${apt.id}) on ${apt.appointmentDate} at ${apt.timeSlot}');
        }
      }

      // Then fetch from API to get latest data (but don't block UI)
      try {
        final appointments = await DataService.fetchUserAppointments();
        if (mounted) {
          setState(() {
            _appointments = List<Appointment>.from(appointments);
            _isLoading = false;
            _isLoadingAppointments = false;
          });
          print('📋 Schedule screen loaded ${_appointments.length} appointments from API');
          for (var apt in _appointments) {
            print('  - ${apt.doctorName} (ID: ${apt.id}) on ${apt.appointmentDate} at ${apt.timeSlot} (${apt.status})');
          }
        }
      } catch (apiError) {
        print('⚠️ API fetch failed, using cached: $apiError');
        // Keep cached appointments if API fails
        if (mounted && _appointments.isEmpty) {
          final cachedAppointments = DataService.getUserAppointments();
          setState(() {
            _appointments = List<Appointment>.from(cachedAppointments);
            _isLoading = false;
            _isLoadingAppointments = false;
          });
        } else if (mounted) {
          setState(() {
            _isLoading = false;
            _isLoadingAppointments = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading appointments: $e');
      // Fallback to cached appointments
      final cachedAppointments = DataService.getUserAppointments();
      if (mounted) {
        setState(() {
          _appointments = List<Appointment>.from(cachedAppointments);
          _isLoading = false;
          _isLoadingAppointments = false;
        });
        print('📋 Using ${_appointments.length} cached appointments after error');
      }
    }
  }

  Future<void> _refreshAppointments() async {
    await _loadAppointments();
  }

  List<Appointment> get _upcomingAppointments {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = _appointments.where((appointment) {
      final appointmentDate = DateTime(
        appointment.appointmentDate.year,
        appointment.appointmentDate.month,
        appointment.appointmentDate.day,
      );
      if (appointment.status == AppointmentStatus.cancelled) {
        return false;
      }
      if (appointment.status == AppointmentStatus.completed) {
        return false;
      }
      return !appointmentDate.isBefore(today);
    }).toList();
    upcoming.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    return upcoming;
  }

  List<Appointment> get _completedAppointments {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completed = _appointments.where((appointment) {
      final appointmentDate = DateTime(
        appointment.appointmentDate.year,
        appointment.appointmentDate.month,
        appointment.appointmentDate.day,
      );
      if (appointment.status == AppointmentStatus.completed) {
        return true;
      }
      if (appointment.status == AppointmentStatus.cancelled) {
        return false;
      }
      return appointmentDate.isBefore(today);
    }).toList();
    completed.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
    return completed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(
        currentRoute: '/appointments',
        userName: 'John Doe',
        userEmail: 'john@example.com',
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAppointments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 50 ),
                    _buildTabs(),
                    // const SizedBox(height: 10),
                    _buildAppointmentsList(),
                  ],
                ),
              ),
            ),
          ),
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
              color: isSelected ? const Color(0xFF0B2D5B) : Colors.grey[200],
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
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final selectedAppointments =
        _selectedTabIndex == 0 ? _upcomingAppointments : _completedAppointments;

    if (selectedAppointments.isEmpty) {
      final isUpcoming = _selectedTabIndex == 0;
      return _buildEmptyState(
        title: isUpcoming ? 'No upcoming appointments yet' : 'No completed appointments yet',
        message: isUpcoming
            ? 'Book a new appointment to see it appear here.'
            : 'Completed appointments will be listed here once they are finished.',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: selectedAppointments.length,
      itemBuilder: (context, index) {
        final appointment = selectedAppointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64),
     
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/illustrations/no_upcoming .png', width: 400, height: 400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final statusColor = _statusColor(appointment.status);
    final statusLabel = _formatStatus(appointment.status);
    final isActionEnabled = _canModifyAppointment(appointment);
    
    // Ensure doctor name is not empty
    final doctorName = appointment.doctorName.isNotEmpty 
        ? appointment.doctorName 
        : 'Unknown Doctor';
    final doctorSpecialty = appointment.doctorSpecialty.isNotEmpty 
        ? appointment.doctorSpecialty 
        : 'General';
    final hospitalName = appointment.hospitalName.isNotEmpty 
        ? appointment.hospitalName 
        : '';

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Info Row - Make this more prominent
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Avatar
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8F0FE),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(doctorName),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B2D5B),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Doctor Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor Name - Make it larger and more prominent
                    Text(
                      doctorName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Specialty
                    Text(
                      doctorSpecialty,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hospitalName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        hospitalName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 16),
          // Date, Time, and Status Row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _formatDate(appointment.appointmentDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        appointment.timeSlot,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: isActionEnabled
                        ? () => _showCancelDialog(context, appointment)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isActionEnabled ? Colors.grey[200] : Colors.grey[100],
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
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: isActionEnabled
                        ? () => _showRescheduleDialog(context, appointment)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B46C1),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.deepPurpleAccent.shade100,
                      disabledForegroundColor: Colors.white,
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

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.completed:
        return const Color(0xFF0B2D5B);
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.rescheduled:
        return Colors.purple;
      case AppointmentStatus.pending:
        return Colors.orange;
    }
  }

  bool _canModifyAppointment(Appointment appointment) {
    switch (appointment.status) {
      case AppointmentStatus.pending:
      case AppointmentStatus.confirmed:
      case AppointmentStatus.rescheduled:
        return true;
      case AppointmentStatus.completed:
      case AppointmentStatus.cancelled:
        return false;
    }
  }

  String _formatStatus(AppointmentStatus status) {
    final raw = status.toString().split('.').last;
    if (raw.isEmpty) {
      return 'Pending';
    }
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return first + last;
  }

  void _showCancelDialog(BuildContext context, Appointment appointment) {
    bool isCancelling = false;
    
    showDialog(
      context: context,
      barrierDismissible: !isCancelling,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
              content: isCancelling
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Text(
                      'Are you sure you want to cancel your appointment with ${appointment.doctorName} on ${_formatDate(appointment.appointmentDate)} at ${appointment.timeSlot}?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
              actions: isCancelling
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          'No, Keep It',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          setDialogState(() {
                            isCancelling = true;
                          });

                          try {
                            // Cancel the appointment
                            await DataService.cancelAppointment(appointment.id);

                            // Create notification about cancellation
                            final dateStr = '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year}';
                            await NotificationService.createInAppNotification(
                              title: 'Appointment Cancelled',
                              description: 'Appointment with Dr. ${appointment.doctorName} on $dateStr at ${appointment.timeSlot} cancelled',
                              icon: Icons.cancel,
                              iconColor: Colors.red,
                              iconBackgroundColor: Colors.red.shade50,
                              appointmentId: appointment.id,
                            );

                            if (mounted) {
                              Navigator.of(dialogContext).pop();
                              
                              // Refresh appointments
                              await _loadAppointments();
                              
                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Appointment cancelled successfully'),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            print('❌ Error cancelling appointment: $e');
                            if (mounted) {
                              Navigator.of(dialogContext).pop();
                              
                              // Refresh appointments even on error since local cache was updated
                              await _loadAppointments();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().contains('locally')
                                        ? 'Cancellation saved locally. Please check your connection.'
                                        : 'Failed to cancel appointment: ${e.toString()}',
                                  ),
                                  backgroundColor: Colors.orange,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
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
      },
    );
  }

  void _showRescheduleDialog(BuildContext context, Appointment appointment) {
    showDialog(
      context: context,
      builder: (dialogContext) {
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
              onPressed: () => Navigator.of(dialogContext).pop(),
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
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Redirecting to reschedule flow...'),
                    backgroundColor: Color(0xFF0B2D5B),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B2D5B),
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