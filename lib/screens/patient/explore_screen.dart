import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/hospital.dart';
import '../../services/data_service.dart';
import '../../services/location_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<Hospital> _hospitals = [];
  bool _isLoading = true;
  LatLng? _userLocation;
  Hospital? _selectedHospital;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadHospitals();
    _getUserLocation();
  }

  Future<void> _loadHospitals() async {
    try {
      final hospitals = await DataService.getNearbyHospitals();
      setState(() {
        _hospitals = hospitals;
        _createMarkers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load hospitals: $e')),
      );
    }
  }

  Future<void> _getUserLocation() async {
    if (LocationService.hasLocation) {
      setState(() {
        _userLocation = LatLng(
          LocationService.currentLatitude!,
          LocationService.currentLongitude!,
        );
      });
    }
  }

  void _createMarkers() {
    _markers.clear();
    
    // Add user location marker
    if (_userLocation != null) {
      _markers.add(
        Marker(
          point: _userLocation!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    // Add hospital markers with profile images
    for (int i = 0; i < _hospitals.length; i++) {
      final hospital = _hospitals[i];
      _markers.add(
        Marker(
          point: LatLng(hospital.latitude, hospital.longitude),
          width: 60,
          height: 60,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = i;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedIndex == i ? Colors.blue : Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: hospital.imageUrl.isNotEmpty
                    ? Image.network(
                        hospital.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: hospital.hasEmergency ? Colors.red : Colors.green,
                            child: Icon(
                              Icons.local_hospital,
                              color: Colors.white,
                              size: 30,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: hospital.hasEmergency ? Colors.red : Colors.green,
                        child: Icon(
                          Icons.local_hospital,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _getDirections(Hospital hospital) async {
    final String url;
    
    if (_userLocation != null) {
      url = 'https://www.openstreetmap.org/directions?engine=fossgis_osrm_car&route=${_userLocation!.latitude},${_userLocation!.longitude};${hospital.latitude},${hospital.longitude}';
    } else {
      url = 'https://www.openstreetmap.org/#map=16/${hospital.latitude}/${hospital.longitude}';
    }
    
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  }

  Future<void> _callHospital(Hospital hospital) async {
    final Uri uri = Uri.parse('tel:${hospital.phoneNumber}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not make phone call')),
      );
    }
  }

  void _centerMapOnUser() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15.0);
    }
  }

  void _centerMapOnHospital(Hospital hospital) {
    _mapController.move(LatLng(hospital.latitude, hospital.longitude), 15.0);
  }

  Widget _buildDoctorCard(Hospital hospital, int index) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        _centerMapOnHospital(hospital);
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
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
          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                color: Colors.grey[200],
              ),
              child: hospital.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        hospital.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: hospital.hasEmergency ? Colors.red : Colors.green,
                            child: Icon(
                              Icons.local_hospital,
                              color: Colors.white,
                              size: 50,
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      color: hospital.hasEmergency ? Colors.red : Colors.green,
                      child: Icon(
                        Icons.local_hospital,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hospital Name
                  Text(
                    hospital.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Specialty (using first specialty or "General Hospital")
                  Text(
                    hospital.specialties.isNotEmpty ? hospital.specialties.first : 'General Hospital',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Rating and Distance
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        hospital.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Lato',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${hospital.distance.toStringAsFixed(1)} KM',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Address
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[400], size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hospital.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Lato',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map Section
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _userLocation ?? 
                              LatLng(_hospitals.isNotEmpty ? _hospitals.first.latitude : -6.80660, 
                                     _hospitals.isNotEmpty ? _hospitals.first.longitude : 39.28535),
                          initialZoom: 12.0,
                          minZoom: 3.0,
                          maxZoom: 18.0,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.quick_clinic',
                            maxZoom: 18,
                          ),
                          MarkerLayer(markers: _markers),
                        ],
                      ),
                      
                      // Floating Search Bar
                      Positioned(
                        top: 50,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey[600], size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Find Doctor, Hospital...',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                    fontFamily: 'Lato',
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(Icons.tune, color: Colors.grey[600], size: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Floating Action Buttons
                      Positioned(
                        top: 120,
                        right: 16,
                        child: Column(
                          children: [
                            FloatingActionButton(
                              onPressed: _centerMapOnUser,
                              mini: true,
                              backgroundColor: Colors.white,
                              child: const Icon(Icons.my_location, color: Color(0xFF1976D2)),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton(
                              onPressed: () {
                                if (_hospitals.isNotEmpty) {
                                  _centerMapOnHospital(_hospitals[_selectedIndex]);
                                }
                              },
                              mini: true,
                              backgroundColor: Colors.white,
                              child: const Icon(Icons.center_focus_strong, color: Color(0xFF1976D2)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom Doctor Cards
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nearby Hospitals',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _hospitals.length,
                          itemBuilder: (context, index) {
                            return _buildDoctorCard(_hospitals[index], index);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}