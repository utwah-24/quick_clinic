import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// import '../doctor/doctor_selection_screen.dart';
import '../../models/hospital.dart';
// import '../../models/appointment.dart';
// import '../../services/localization_service.dart';
import 'doctor_details_screen.dart';
import 'subscription_prompt_screen.dart';

class HospitalProfileScreen extends StatefulWidget {
  final Hospital hospital;
  final Doctor? selectedDoctor;

  const HospitalProfileScreen({super.key, required this.hospital, this.selectedDoctor});

  @override
  _HospitalProfileScreenState createState() => _HospitalProfileScreenState();
}

class _HospitalProfileScreenState extends State<HospitalProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.selectedDoctor != null ? 1 : 0, // focus Specialist if doctor selected
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with blurred background
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.black),
                  onPressed: () {},
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.black),
                  onPressed: () {},
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred background image
                  Image.network(
                    widget.hospital.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.local_hospital, size: 100, color: Colors.grey[600]),
                      );
                    },
                  ),
                  // Blur effect
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Rating badge
                  Positioned(
                    top: 100,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B2D5B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.hospital.rating} (1k+ Review)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          //  Hospital details card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clinic name
                  Text(
                    widget.hospital.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Services
                  Text(
                    widget.hospital.specialties.take(3).join(', ') + ',',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: const Color(0xFF0B2D5B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.hospital.address,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Operating hours and distance
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 18, color: const Color(0xFF0B2D5B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '15 min • ${widget.hospital.distance.toStringAsFixed(1)}km • Mon Sun | 11 am - 11pm',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Action buttons
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    Icons.message,
                    'Message',
                    onTap: _navigateToSubscription,
                  ),
                  _buildActionButton(
                    Icons.phone,
                    'Call',
                    onTap: _navigateToSubscription,
                  ),
                  _buildActionButton(
                    Icons.directions,
                    'Direction',
                    onTap: _showDirectionsSheet,
                  ),
                  _buildActionButton(Icons.send, 'Share'),
                ],
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          
          // Navigation tabs
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF0B2D5B),
                labelColor: const Color(0xFF0B2D5B),
                unselectedLabelColor: Colors.grey[600],
                tabs: const [
                  Tab(text: 'Treatments'),
                  Tab(text: 'Specialist'),
                  Tab(text: 'Gallery'),
                  Tab(text: 'Review'),
                ],
              ),
            ),
          ),
          
          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTreatmentsTab(),
                _buildSpecialistTab(),
                _buildGalleryTab(),
                _buildReviewTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {VoidCallback? onTap}) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF0B2D5B),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showDirectionsSheet() {
    final double lat = widget.hospital.latitude;
    final double lng = widget.hospital.longitude;
    print('🔍 Directions requested for hospital: ${widget.hospital.name}');
    print('🔍 Coordinates: lat=$lat, lng=$lng');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Directions',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.hospital.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.map, color: Color(0xFF0B2D5B)),
                  title: const Text('Open Google Maps'),
                  subtitle: Text('$lat, $lng'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _openInGoogleMaps(lat, lng);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubscriptionPromptScreen(),
      ),
    );
  }

  Future<void> _openInGoogleMaps(double lat, double lng) async {
    // Try iOS Google Maps scheme first; on Android this will fall through to web
    final Uri appUri = Uri.parse('comgooglemaps://?daddr=$lat,$lng&directionsmode=driving');
    final Uri androidUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    final Uri webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    print('🔍 Launch intents -> appUri: $appUri');
    print('🔍 Launch intents -> androidUri: $androidUri');
    print('🔍 Launch intents -> webUri: $webUri');

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri);
        return;
      }
      if (await canLaunchUrl(androidUri)) {
        await launchUrl(androidUri);
        return;
      }
    } catch (_) {}

    await launchUrl(webUri);
  }

  Widget _buildTreatmentsTab() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Treatments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2D5B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '(${widget.hospital.specialties.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.hospital.specialties.length,
              itemBuilder: (context, index) {
                return _buildTreatmentCard(widget.hospital.specialties[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentCard(String treatment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            treatment,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: const Color(0xFF0B2D5B)),
        ],
      ),
    );
  }

  Widget _buildSpecialistTab() {
    final List<Doctor> doctors = widget.hospital.doctors;
    final Doctor? selected = widget.selectedDoctor;
    final List<Doctor> ordered = [
      if (selected != null) selected,
      ...doctors.where((d) => selected == null || d.id != selected.id),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: ordered.length,
        itemBuilder: (context, index) {
          final d = ordered[index];
          final bool isSelected = selected != null && d.id == selected.id;
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorDetailsScreen(
                    doctorName: d.name,
                    specialty: d.specialty,
                    rating: d.rating,
                    imageUrl: d.imageUrl,
                    reviewCount: 124, // Default review count, can be adjusted
                    hospitalId: widget.hospital.id,
                    hospital: widget.hospital, // Pass the hospital object directly
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? const Color(0xFF0B2D5B) : Colors.grey[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      d.imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[300],
                        child: Icon(Icons.person, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d.specialty,
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(d.rating.toStringAsFixed(1)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
          );
        },
      ),
    );
 
  }

  Widget _buildGalleryTab() {
    return const Center(child: Text('Gallery Tab'));
  }

  Widget _buildReviewTab() {
    return const Center(child: Text('Review Tab'));
  }

}