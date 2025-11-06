import 'package:flutter/material.dart';
import 'hospital_profile_screen.dart';
import '../../models/hospital.dart';
import '../../services/data_service.dart';
// import '../../widgets/drawer.dart';
// Removed DynamicAppBar in favor of a search bar

// Helper tuple tying a doctor to its hospital (file-private)
class _DoctorWithHospital {
  final Doctor doctor;
  final Hospital hospital;
  _DoctorWithHospital({required this.doctor, required this.hospital});
}

class HospitalsScreen extends StatefulWidget {
  const HospitalsScreen({super.key});

  @override
  _HospitalsScreenState createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends State<HospitalsScreen> {
  List<Hospital> _hospitals = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showDoctors = false; // toggle state: false = Hospitals, true = Doctors
  late final ScrollController _scrollController;
  static const double _adsMaxHeight = 200.0;
  double _adsCurrentHeight = 200.0;
  double _adsOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final hospitals = await DataService.getNearbyHospitals();
      if (!mounted) return;
      setState(() {
        _hospitals = hospitals;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading hospitals: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading hospitals: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
    });
  }

  List<Hospital> get _visibleHospitals {
    if (_searchQuery.isEmpty) return _hospitals;
    final q = _searchQuery.toLowerCase();
    return _hospitals.where((h) {
      final inName = h.name.toLowerCase().contains(q);
      final inAddress = h.address.toLowerCase().contains(q);
      final inSpecialties = h.specialties.any((s) => s.toLowerCase().contains(q));
      return inName || inAddress || inSpecialties;
    }).toList();
  }

  void _handleScroll() {
    final double offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final double clamped = offset.clamp(0.0, _adsMaxHeight);
    final double progress = clamped / _adsMaxHeight; // 0.0 → 1.0
    final double newHeight = _adsMaxHeight * (1.0 - progress);
    final double newOpacity = 1.0 - progress;

    // Only update when there's a visible change to avoid rebuild spam
    if ((newHeight - _adsCurrentHeight).abs() > 0.5 || (newOpacity - _adsOpacity).abs() > 0.02) {
      setState(() {
        _adsCurrentHeight = newHeight;
        _adsOpacity = newOpacity;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // drawer: const AppDrawer(
      //   currentRoute: '/hospitals',
      //   userName: 'John Doe',
      //   userEmail: 'john@example.com',
      // ),
      body: SafeArea( 
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B2D5B), Color(0xFF0B2D5B)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAdsSpace(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 26),
                        child: _buildToggle(),
                      ),
                      _buildSearchBar(),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : _showDoctors
                                    ? _buildDoctorsArea()
                                    : (_visibleHospitals.isEmpty
                                        ? (_searchQuery.isEmpty ? _buildEmptyState() : _buildNoResultsState())
                                        : _buildHospitalsList()),
                          ),
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
    );
  }
  Widget _buildAdsSpace() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      height: _adsCurrentHeight,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            opacity: _adsOpacity,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              height: _adsMaxHeight - 50, // inner card visual height
              width: double.infinity,
              child: const Center(child: Text('Ads')),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_hospital, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hospitals found nearby',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadHospitals,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalsList() {
    return RefreshIndicator(
      onRefresh: _loadHospitals,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _visibleHospitals.length,
        itemBuilder: (context, index) {
          final hospital = _visibleHospitals[index];
          return _buildHospitalCard(hospital);
        },
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hospitals found for "$_searchQuery"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              'Try searching by hospital name, area in Dar es Salaam, or service.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      // height: 60,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Material(
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.15),
        color: Colors.white38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.search, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: _showDoctors
                        ? 'Search doctors or hospitals'
                        : 'Search hospitals around Dar es Salaam',
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                if (_showDoctors) return;
                setState(() => _showDoctors = true);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Doctors',
                    style: TextStyle(
                      color: _showDoctors ? const Color(0xFF1976D2) : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 4,
                    width: _showDoctors ? 80 : 0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                if (!_showDoctors) return;
                setState(() => _showDoctors = false);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hospitals',
                    style: TextStyle(
                      color: !_showDoctors ? const Color(0xFF1976D2) : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 4,
                    width: !_showDoctors ? 80 : 0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_DoctorWithHospital> get _allDoctors {
    final list = <_DoctorWithHospital>[];
    for (final h in _hospitals) {
      for (final d in h.doctors) {
        list.add(_DoctorWithHospital(doctor: d, hospital: h));
      }
    }
    return list;
  }

  List<_DoctorWithHospital> get _visibleDoctors {
    if (_searchQuery.isEmpty) return _allDoctors;
    final q = _searchQuery.toLowerCase();
    return _allDoctors.where((row) {
      final inName = row.doctor.name.toLowerCase().contains(q);
      final inSpecialty = row.doctor.specialty.toLowerCase().contains(q);
      final inHospital = row.hospital.name.toLowerCase().contains(q);
      return inName || inSpecialty || inHospital;
    }).toList();
  }

  Widget _buildDoctorsArea() {
    final visible = _visibleDoctors;
    if (visible.isEmpty) {
      return _searchQuery.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('No doctors found nearby', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadHospitals, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('No doctors found for "$_searchQuery"', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  ],
                ),
              ),
            );
    }
    return RefreshIndicator(
      onRefresh: _loadHospitals,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final row = visible[index];
          return _buildDoctorCard(row);
        },
      ),
    );
  }

  Widget _buildDoctorCard(_DoctorWithHospital row) {
    final d = row.doctor;
    final h = row.hospital;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _selectDoctor(row),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.specialty,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.local_hospital, size: 14, color: Colors.blue[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            h.name,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(d.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectDoctor(_DoctorWithHospital row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HospitalProfileScreen(
          hospital: row.hospital,
          selectedDoctor: row.doctor,
        ),
      ),
    );
  }

  Widget _buildHospitalCard(Hospital hospital) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: InkWell(
        onTap: () => _selectHospital(hospital),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    hospital.imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: Image.asset(hospital.imageUrl, width: 60, height: 60, color: Colors.grey[600]),
                        // child: Icon(Icons.local_hospital, size: 60, color: Colors.grey[600]),
                      );
                    },
                  ),
                ),
                // Rating Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          '${hospital.rating} (1k+ Review)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Favorite Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Icon(
                      Icons.favorite_border,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clinic Name
                  Text(
                    hospital.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Services
                  Text(
                    hospital.specialties.take(2).join(', '),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.blue[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hospital.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Distance/Time
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.blue[600]),
                      const SizedBox(width: 4),
                      Text(
                        hospital.distance > 0 
                            ? '15 min • ${hospital.distance.toStringAsFixed(1)}km'
                            : '15 min • 1.5km',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectHospital(Hospital hospital) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HospitalProfileScreen(hospital: hospital),
      ),
    );
  }
}
