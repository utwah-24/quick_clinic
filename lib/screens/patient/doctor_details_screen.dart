import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../models/hospital.dart';
import '../../models/appointment.dart';
import '../../models/payment_method.dart';
import 'booking_screen.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final double rating;
  final String imageUrl;
  final int reviewCount;
  final String? hospitalId;
  final Hospital? hospital; // Optional: pass hospital directly if available

  const DoctorDetailsScreen({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.rating,
    required this.imageUrl,
    required this.reviewCount,
    this.hospitalId,
    this.hospital,
  });

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  bool _isFavorited = false;
  bool _showFullAbout = false;
  Hospital? _hospital;
  bool _isLoadingLocation = true;
  String _locationText = 'Loading location...';

  @override
  void initState() {
    super.initState();
    _loadHospitalLocation();
  }

  Future<void> _loadHospitalLocation() async {
    // If hospital is already provided, use it directly
    if (widget.hospital != null) {
      setState(() {
        _hospital = widget.hospital;
        _locationText = widget.hospital!.address;
        _isLoadingLocation = false;
      });
      return;
    }

    // Otherwise, try to fetch from API using hospitalId
    if (widget.hospitalId != null) {
      try {
        final hospital = await DataService.getHospitalById(widget.hospitalId!);
        if (hospital != null) {
          setState(() {
            _hospital = hospital;
            _locationText = hospital.address;
            _isLoadingLocation = false;
          });
        } else {
          setState(() {
            _locationText = 'Location not available';
            _isLoadingLocation = false;
          });
        }
      } catch (e) {
        print('Error loading hospital: $e');
        setState(() {
          _locationText = 'Location not available';
          _isLoadingLocation = false;
        });
      }
    } else {
      setState(() {
        _locationText = 'Location not available';
        _isLoadingLocation = false;
      });
    }
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
        title: const Text(
          'Doctor Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
              ),
              child: const Icon(
                Icons.share,
                color: Colors.black,
                size: 20,
              ),
            ),
            onPressed: () {
              // Handle share
            },
          ),
          IconButton(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
              ),
              child: Icon(
                _isFavorited ? Icons.favorite : Icons.favorite_border,
                color: _isFavorited ? Colors.red : Colors.black,
                size: 20,
              ),
            ),
            onPressed: () {
              setState(() {
                _isFavorited = !_isFavorited;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Profile Section
            _buildDoctorProfile(),
            
            const SizedBox(height: 24),
            
            // Statistics Section
            _buildStatistics(),
            
            const SizedBox(height: 32),
            
            // About Section
            _buildAboutSection(),
            
            const SizedBox(height: 32),
            
            // Working Hours Section
            _buildWorkingHours(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              // Check if hospital is available
              if (_hospital == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hospital information not available')),
                );
                return;
              }

              // Find or create doctor object
              Doctor? doctor;
              if (_hospital!.doctors.isNotEmpty) {
                doctor = _hospital!.doctors.firstWhere(
                  (d) => d.name == widget.doctorName,
                  orElse: () => _hospital!.doctors.first,
                );
              } else {
                // Create a minimal doctor object from available info
                doctor = Doctor(
                  id: widget.doctorName.toLowerCase().replaceAll(' ', '_'),
                  name: widget.doctorName,
                  specialty: widget.specialty,
                  qualification: 'MD',
                  experience: 5,
                  rating: widget.rating,
                  imageUrl: widget.imageUrl,
                  availableDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
                  availableTime: '9:00 AM - 5:00 PM',
                  consultationFee: 50000,
                  bio: 'Experienced doctor',
                  languages: ['Swahili', 'English'],
                );
              }

              // Get stored payment method or use default
              PaymentMethod paymentMethod = PaymentMethod.card; // default
              final storedPaymentMethod = await DataService.getSelectedPaymentMethod();
              if (storedPaymentMethod != null) {
                if (storedPaymentMethod.type == 'credit_card') {
                  paymentMethod = PaymentMethod.card;
                } else if (storedPaymentMethod.type == 'nida') {
                  paymentMethod = PaymentMethod.insurance;
                }
              }

              // Navigate directly to booking screen
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingScreen(
                      hospital: _hospital!,
                      doctor: doctor!,
                      paymentMethod: paymentMethod,
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B2D5B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Book Appointment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Lato',
              ),
            ),
          ),
       
        ),
      ),
    );
  }

  Widget _buildDoctorProfile() {
    return Column(
      children: [
        // Profile Picture with Verification Badge
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
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
                child: widget.imageUrl.isNotEmpty
                    ? Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.person,
                          size: 60,
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
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF0B2D5B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Doctor Name
        Text(
          widget.doctorName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Lato',
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Specialty
        Text(
          widget.specialty,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontFamily: 'Lato',
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Location
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on,
              color: const Color(0xFF0B2D5B)!,
              size: 16,
            ),
            const SizedBox(width: 4),
            if (_isLoadingLocation)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                ),
              )
            else
              Expanded(
                child: Text(
                  _locationText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Lato',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.local_hospital,
              color: const Color(0xFF0B2D5B)!,
              size: 16,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(Icons.people, '7,500+', 'Patients'),
        _buildStatItem(Icons.work, '10+', 'Years Exp.'),
        _buildStatItem(Icons.star, '${widget.rating}+', 'Rating'),
        _buildStatItem(Icons.chat_bubble, '${widget.reviewCount}', 'Review'),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF0B2D5B)!.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0B2D5B)!,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Lato',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Lato',
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Lato',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _showFullAbout
              ? 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.'
              : 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.5,
            fontFamily: 'Lato',
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _showFullAbout = !_showFullAbout;
            });
          },
          child: Text(
            _showFullAbout ? 'Read less' : 'Read more',
            style: const TextStyle(
              fontSize: 14,
              color: const Color(0xFF0B2D5B),
              fontWeight: FontWeight.w600,
              fontFamily: 'Lato',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingHours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Working Hours',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Lato',
          ),
        ),
        const SizedBox(height: 16),
        ...['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'].map(
          (day) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontFamily: 'Lato',
                  ),
                ),
                Text(
                  '00:00 - 00:00',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
