import 'package:flutter/material.dart';
import '../../models/hospital.dart';
import '../../models/appointment.dart';
import '../../services/data_service.dart';
import 'appointment_summary_screen.dart';

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
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1)); // Start from tomorrow
  String? _selectedTimeSlot;
  List<String> _availableTimeSlots = [];
  bool _isLoadingTimeSlots = false; // Used for time slots loading
  // Track dates that have no available time slots
  final Set<String> _datesWithNoSlots = {};
  bool _isCheckingAllDates = false;

  static const Color _brandColor = Color(0xFF0B2D5B);

  @override
  void initState() {
    super.initState();
    print('🕐 [DEBUG] ========================================');
    print('🕐 [DEBUG] BookingScreen initState() called');
    print('🕐 [DEBUG] Doctor ID: ${widget.doctor.id}');
    print('🕐 [DEBUG] Doctor Name: ${widget.doctor.name}');
    print('🕐 [DEBUG] Hospital ID: ${widget.hospital.id}');
    print('🕐 [DEBUG] Hospital Name: ${widget.hospital.name}');
    print('🕐 [DEBUG] Initial Date: ${_selectedDate.toIso8601String()}');
    print('🕐 [DEBUG] Fetching initial time slots...');
    print('🕐 [DEBUG] ========================================');
    _refreshTimeSlots();
    _checkAllDatesAvailability();
  }


  @override
  Widget build(BuildContext context) {
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
          'Book Appointment',
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
              _buildDoctorProfile(),
              const SizedBox(height: 24),
              _buildStatistics(),
              const SizedBox(height: 32),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'BOOK APPOINTMENT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildDateSelection(),
              const SizedBox(height: 24),
              _buildTimeSlotSelection(),
              const SizedBox(height: 16),
              // _buildCustomScheduleOption(),
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
        child: _buildBookingButton(),
      ),
    );
  }

  Widget _buildDoctorProfile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture with Verification Badge
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: widget.doctor.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.doctor.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey[600],
                          ),
                        ),
                ),
              ),
              // Verification Badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: _brandColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ' ${widget.doctor.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.doctor.specialty,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: _brandColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.hospital.address,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.local_hospital,
                      color: _brandColor,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(Icons.people, '7,500+', 'Patients'),
          _buildStatItem(Icons.work, '${widget.doctor.experience}+', 'Years Exp.'),
          _buildStatItem(Icons.star, '${widget.doctor.rating.toStringAsFixed(1)}+', 'Rating'),
          _buildStatItem(Icons.chat_bubble, '4,956', 'Review'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _brandColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: _brandColor,
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelection() {
    final today = DateTime.now();
    // Start from tomorrow (index 0 = tomorrow) since backend requires date to be after today
    final dates = List.generate(7, (index) => today.add(Duration(days: index + 1)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Day',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = _selectedDate.year == date.year &&
                  _selectedDate.month == date.month &&
                  _selectedDate.day == date.day;
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final hasNoSlots = _datesWithNoSlots.contains(_getDateKey(date));

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildDateButton(
                  date: date,
                  isSelected: isSelected,
                  isToday: isToday,
                  hasNoSlots: hasNoSlots,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required DateTime date,
    required bool isSelected,
    required bool isToday,
    required bool hasNoSlots,
  }) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = weekdays[date.weekday - 1];

    // Determine border color: red if no slots, brand color if selected, grey otherwise
    Color borderColor;
    if (hasNoSlots && !isSelected) {
      borderColor = Colors.red;
    } else if (isSelected) {
      borderColor = _brandColor;
    } else {
      borderColor = Colors.grey[300]!;
    }

    // Determine border width: thicker if no slots or selected
    double borderWidth = hasNoSlots && !isSelected ? 2.0 : (isSelected ? 1.0 : 1.0);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
          _selectedTimeSlot = null;
        });
        _refreshTimeSlots();
      },
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? _brandColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isToday ? 'Today' : dayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : (hasNoSlots ? Colors.red[700] : Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day} ${_getMonthName(date.month)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : (hasNoSlots ? Colors.red[700] : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildTimeSlotSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: _isLoadingTimeSlots
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _availableTimeSlots.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Text(
                          'No time slots available',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _availableTimeSlots.length,
                      itemBuilder: (context, index) {
                        final slot = _availableTimeSlots[index];
                        final isSelected = _selectedTimeSlot == slot;

                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _buildTimeButton(
                            time: slot,
                            isSelected: isSelected,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildTimeButton({
    required String time,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeSlot = isSelected ? null : time;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? _brandColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _brandColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            time,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildCustomScheduleOption() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20),
  //     child: Row(
  //       children: [
  //         Text(
  //           'Want a custom schedule?',
  //           style: TextStyle(
  //             fontSize: 14,
  //             color: Colors.grey[600],
  //           ),
  //         ),
  //         const SizedBox(width: 8),
  //         GestureDetector(
  //           onTap: () {
  //             // Handle custom schedule request
  //           },
  //           child: const Text(
  //             'Request Schedule',
  //             style: TextStyle(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w600,
  //               color: _brandColor,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }


  Widget _buildBookingButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _selectedTimeSlot != null ? _confirmBooking : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Make Appointment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _refreshTimeSlots() async {
    print('🕐 [DEBUG] _refreshTimeSlots() called');
    print('🕐 [DEBUG] Doctor ID: ${widget.doctor.id}');
    print('🕐 [DEBUG] Doctor Name: ${widget.doctor.name}');
    print('🕐 [DEBUG] Selected Date: ${_selectedDate.toIso8601String()}');
    print('🕐 [DEBUG] Selected Date (formatted): ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}');
    
    setState(() {
      _isLoadingTimeSlots = true;
      _selectedTimeSlot = null; // Clear selection when refreshing
    });

    try {
      print('🕐 [DEBUG] Calling DataService.getAvailableTimeSlots...');
      final timeSlots = await DataService.getAvailableTimeSlots(widget.doctor.id, _selectedDate);
      print('🕐 [DEBUG] Received ${timeSlots.length} time slots from API');
      print('🕐 [DEBUG] Time slots: $timeSlots');
      
      final dateKey = _getDateKey(_selectedDate);
      setState(() {
        _availableTimeSlots = timeSlots;
        _isLoadingTimeSlots = false;
        // Update the set of dates with no slots
        if (timeSlots.isEmpty) {
          _datesWithNoSlots.add(dateKey);
        } else {
          _datesWithNoSlots.remove(dateKey);
        }
      });
      print('🕐 [DEBUG] Time slots updated in UI');
    } catch (e) {
      print('🕐 [DEBUG] ❌ Error fetching time slots: $e');
      print('🕐 [DEBUG] Stack trace: ${StackTrace.current}');
      final dateKey = _getDateKey(_selectedDate);
      setState(() {
        _availableTimeSlots = [];
        _isLoadingTimeSlots = false;
        // Mark date as having no slots on error
        _datesWithNoSlots.add(dateKey);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load time slots: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  Future<void> _checkAllDatesAvailability() async {
    if (_isCheckingAllDates) return;
    
    setState(() {
      _isCheckingAllDates = true;
    });

    final today = DateTime.now();
    final dates = List.generate(7, (index) => today.add(Duration(days: index + 1)));
    
    // Check availability for all dates in parallel
    final futures = dates.map((date) async {
      try {
        final timeSlots = await DataService.getAvailableTimeSlots(widget.doctor.id, date);
        return {
          'date': date,
          'hasSlots': timeSlots.isNotEmpty,
        };
      } catch (e) {
        print('⚠️ Error checking availability for ${_getDateKey(date)}: $e');
        return {
          'date': date,
          'hasSlots': false,
        };
      }
    });

    final results = await Future.wait(futures);
    
    if (mounted) {
      setState(() {
        _datesWithNoSlots.clear();
        for (var result in results) {
          final date = result['date'] as DateTime;
          final hasSlots = result['hasSlots'] as bool;
          if (!hasSlots) {
            _datesWithNoSlots.add(_getDateKey(date));
          }
        }
        _isCheckingAllDates = false;
      });
      print('📅 Dates with no slots: ${_datesWithNoSlots.length}');
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    // Get current user data
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

    // Check doctor availability before confirming
    final isAvailable = await DataService.isDoctorAvailable(widget.doctor.id, _selectedDate);
    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor is not available on the selected date. Please choose another date.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to summary screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentSummaryScreen(
          hospital: widget.hospital,
          doctor: widget.doctor,
          selectedDate: _selectedDate,
          selectedTimeSlot: _selectedTimeSlot!,
          amount: widget.doctor.consultationFee + 500,
        ),
      ),
    );
  }

}
