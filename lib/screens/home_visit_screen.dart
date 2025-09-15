import 'package:flutter/material.dart';
import '../models/home_visit.dart';
import '../services/home_visit_service.dart';
import '../services/location_service.dart';
import '../widgets/dynamic_app_bar.dart';
import 'home_visit_booking_screen.dart';

class HomeVisitScreen extends StatefulWidget {
  const HomeVisitScreen({super.key});

  @override
  _HomeVisitScreenState createState() => _HomeVisitScreenState();
}

class _HomeVisitScreenState extends State<HomeVisitScreen> {
  List<HomeVisit> _homeVisits = [];
  List<HomeVisit> _filteredVisits = [];
  bool _isLoading = true;
  String? _selectedProviderType;
  String? _selectedSpecialty;
  double? _maxPrice;
  String? _selectedDay;
  String? _selectedTime;
  double? _userLatitude;
  double? _userLongitude;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _providerTypes = ['All', 'doctor', 'nurse'];
  final List<String> _specialties = [
    'All',
    'General Medicine',
    'Pediatrics',
    'Elderly Care',
    'Home Care Nursing',
    'Chronic Disease Management',
  ];
  final List<String> _days = [
    'All',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  final List<String> _timeSlots = [
    'All',
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  @override
  void initState() {
    super.initState();
    _loadHomeVisits();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final locationResult = await LocationService.getCurrentLocation();
      if (locationResult.success) {
        setState(() {
          _userLatitude = locationResult.latitude;
          _userLongitude = locationResult.longitude;
        });
      }
    } catch (e) {
      // Handle location error
    }
  }

  Future<void> _loadHomeVisits() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final visits = await HomeVisitService.getAvailableHomeVisits();
      setState(() {
        _homeVisits = visits;
        _filteredVisits = visits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredVisits = _homeVisits.where((visit) {
        // Filter by provider type
        if (_selectedProviderType != null && 
            _selectedProviderType != 'All' && 
            visit.providerType != _selectedProviderType) {
          return false;
        }

        // Filter by specialty
        if (_selectedSpecialty != null && 
            _selectedSpecialty != 'All' && 
            !visit.specialty.toLowerCase().contains(_selectedSpecialty!.toLowerCase())) {
          return false;
        }

        // Filter by max price
        if (_maxPrice != null && visit.price > _maxPrice!) {
          return false;
        }

        // Filter by available day
        if (_selectedDay != null && 
            _selectedDay != 'All' && 
            !visit.availableDays.contains(_selectedDay!.toLowerCase())) {
          return false;
        }

        // Filter by available time
        if (_selectedTime != null && 
            _selectedTime != 'All' && 
            !visit.availableTimeSlots.contains(_selectedTime)) {
          return false;
        }

        // Filter by search text
        if (_searchController.text.isNotEmpty) {
          final searchLower = _searchController.text.toLowerCase();
          if (!visit.providerName.toLowerCase().contains(searchLower) &&
              !visit.specialty.toLowerCase().contains(searchLower) &&
              !visit.location.toLowerCase().contains(searchLower)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          DynamicAppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: 'Home Visit Services',
            actions: [
              IconButton(
                icon: const Icon(Icons.location_on),
                onPressed: _getUserLocation,
                tooltip: 'Update Location',
              ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                _buildSearchAndFilters(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredVisits.isEmpty
                          ? _buildEmptyState()
                          : _buildHomeVisitsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search doctors, nurses, or specialties...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => _applyFilters(),
          ),
          const SizedBox(height: 16),
          
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Provider Type',
                  value: _selectedProviderType ?? 'All',
                  options: _providerTypes,
                  onChanged: (value) {
                    setState(() {
                      _selectedProviderType = value == 'All' ? null : value;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Specialty',
                  value: _selectedSpecialty ?? 'All',
                  options: _specialties,
                  onChanged: (value) {
                    setState(() {
                      _selectedSpecialty = value == 'All' ? null : value;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Day',
                  value: _selectedDay ?? 'All',
                  options: _days,
                  onChanged: (value) {
                    setState(() {
                      _selectedDay = value == 'All' ? null : value;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Time',
                  value: _selectedTime ?? 'All',
                  options: _timeSlots,
                  onChanged: (value) {
                    setState(() {
                      _selectedTime = value == 'All' ? null : value;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _buildPriceFilter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return PopupMenuButton<String>(
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $value',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceFilter() {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Max Price: ${_maxPrice != null ? 'TZS ${_maxPrice!.toStringAsFixed(0)}' : 'Any'}',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Colors.green[700]),
          ],
        ),
      ),
      itemBuilder: (context) => [
        'Any',
        'TZS 1000',
        'TZS 2000',
        'TZS 3000',
        'TZS 5000',
        'TZS 10000',
      ].map((option) {
        return PopupMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onSelected: (value) {
        setState(() {
          if (value == 'Any') {
            _maxPrice = null;
          } else {
            _maxPrice = double.parse(value.replaceAll('TZS ', ''));
          }
        });
        _applyFilters();
      },
    );
  }

  Widget _buildHomeVisitsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredVisits.length,
      itemBuilder: (context, index) {
        final visit = _filteredVisits[index];
        return _buildHomeVisitCard(visit);
      },
    );
  }

  Widget _buildHomeVisitCard(HomeVisit visit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToBooking(visit),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage(visit.providerImageUrl),
                    onBackgroundImageError: (e, s) {},
                    child: visit.providerImageUrl.contains('assets/') 
                        ? Icon(Icons.person, size: 30, color: Colors.grey[600])
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                visit.providerName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: visit.providerType == 'doctor' 
                                    ? Colors.blue[100] 
                                    : Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                visit.providerType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: visit.providerType == 'doctor' 
                                      ? Colors.blue[700] 
                                      : Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          visit.specialty,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber[600], size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${visit.rating} (${visit.reviewCount} reviews)',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Location and travel time
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red[600], size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      visit.location,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${visit.estimatedTravelTime} min',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Services
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: visit.services.map((service) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      service,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Price and availability
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TZS ${visit.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'per visit',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  )),
                  ElevatedButton(
                    onPressed: () => _navigateToBooking(visit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Book Now'),
                  ),
                ],
              ),
            ],
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
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No providers found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search criteria',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedProviderType = null;
                _selectedSpecialty = null;
                _maxPrice = null;
                _selectedDay = null;
                _selectedTime = null;
                _searchController.clear();
              });
              _applyFilters();
            },
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  void _navigateToBooking(HomeVisit visit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeVisitBookingScreen(homeVisit: visit),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
