import 'package:flutter/material.dart';
import '../../models/hospital.dart';
import '../../services/data_service.dart';
import 'hospital_profile_screen.dart';

class CategoryHospitalsScreen extends StatefulWidget {
  final String categoryName;

  const CategoryHospitalsScreen({
    super.key,
    required this.categoryName,
  });

  @override
  State<CategoryHospitalsScreen> createState() => _CategoryHospitalsScreenState();
}

class _CategoryHospitalsScreenState extends State<CategoryHospitalsScreen> {
  List<Hospital> _hospitals = [];
  Map<String, List<Doctor>> _hospitalDoctors = {}; // Map of hospitalId to filtered doctors
  Map<String, bool> _loadingDoctors = {}; // Track which hospitals are loading doctors
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHospitalsByCategory();
  }

  Future<void> _loadHospitalsByCategory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final hospitals = await DataService.getHospitalsByCategory(widget.categoryName);
      setState(() {
        _hospitals = hospitals;
        _loading = false;
      });
      
      // Fetch doctors for each hospital and filter by category
      _loadDoctorsForAllHospitals(hospitals);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadDoctorsForAllHospitals(List<Hospital> hospitals) async {
    // Fetch doctors for each hospital in parallel
    final futures = hospitals.map((hospital) async {
      setState(() {
        _loadingDoctors[hospital.id] = true;
      });

      try {
        final doctors = await DataService.getHospitalDoctorsByCategory(
          hospital.id,
          widget.categoryName,
        );
        
        if (mounted) {
          setState(() {
            _hospitalDoctors[hospital.id] = doctors;
            _loadingDoctors[hospital.id] = false;
          });
        }
        return {'hospitalId': hospital.id, 'doctors': doctors};
      } catch (e) {
        print('❌ Error loading doctors for hospital ${hospital.id}: $e');
        if (mounted) {
          setState(() {
            _hospitalDoctors[hospital.id] = [];
            _loadingDoctors[hospital.id] = false;
          });
        }
        return {'hospitalId': hospital.id, 'doctors': <Doctor>[]};
      }
    });

    await Future.wait(futures);
    print('✅ Finished loading doctors for all hospitals');
  }

  Future<void> _loadDoctorsForHospital(String hospitalId) async {
    if (_loadingDoctors[hospitalId] == true) return;

    setState(() {
      _loadingDoctors[hospitalId] = true;
    });

    try {
      final doctors = await DataService.getHospitalDoctorsByCategory(
        hospitalId,
        widget.categoryName,
      );
      
      if (mounted) {
        setState(() {
          _hospitalDoctors[hospitalId] = doctors;
          _loadingDoctors[hospitalId] = false;
        });
      }
    } catch (e) {
      print('❌ Error loading doctors for hospital $hospitalId: $e');
      if (mounted) {
        setState(() {
          _hospitalDoctors[hospitalId] = [];
          _loadingDoctors[hospitalId] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '${widget.categoryName} Hospitals',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadHospitalsByCategory,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B2D5B)),
              ),
            )
          : _error != null
              ? _buildErrorState()
              : _hospitals.isEmpty
                  ? _buildEmptyState()
                  : _buildHospitalsList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load hospitals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unknown error occurred',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadHospitalsByCategory,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B2D5B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Hospitals Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No hospitals with ${widget.categoryName} doctors available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B2D5B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalsList() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_hospitals.length} hospitals found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hospitals with ${widget.categoryName} specialists',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _hospitals.length,
            itemBuilder: (context, index) {
              final hospital = _hospitals[index];
              return _buildHospitalCard(hospital);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHospitalCard(Hospital hospital) {
    final doctors = _hospitalDoctors[hospital.id] ?? [];
    final isLoadingDoctors = _loadingDoctors[hospital.id] ?? false;
    final filteredDoctorsCount = doctors.length;
    
    // Load doctors if not already loaded
    if (!_hospitalDoctors.containsKey(hospital.id) && !isLoadingDoctors) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDoctorsForHospital(hospital.id);
      });
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HospitalProfileScreen(hospital: hospital),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Hospital Image
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: hospital.imageUrl.isNotEmpty
                            ? Image.network(
                                hospital.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.local_hospital,
                                    size: 30,
                                    color: Colors.grey[400],
                                  );
                                },
                              )
                            : Icon(
                                Icons.local_hospital,
                                size: 30,
                                color: Colors.grey[400],
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Hospital Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hospital.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hospital.address,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.orange[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hospital.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.people,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              if (isLoadingDoctors)
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      const Color(0xFF0B2D5B),
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  filteredDoctorsCount > 0
                                      ? '$filteredDoctorsCount ${widget.categoryName} ${filteredDoctorsCount == 1 ? 'doctor' : 'doctors'}'
                                      : 'No ${widget.categoryName} doctors',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: filteredDoctorsCount > 0 
                                        ? const Color(0xFF0B2D5B)
                                        : Colors.grey[600],
                                    fontWeight: filteredDoctorsCount > 0 
                                        ? FontWeight.w600 
                                        : FontWeight.normal,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Show filtered doctors if available
                if (filteredDoctorsCount > 0 && !isLoadingDoctors) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B2D5B).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF0B2D5B).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.categoryName} Specialists:',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0B2D5B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...doctors.take(3).map((doctor) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.medical_services,
                                size: 14,
                                color: const Color(0xFF0B2D5B),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  doctor.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )),
                        if (doctors.length > 3)
                          Text(
                            '+ ${doctors.length - 3} more',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Specialties - Show all matching specialties
                if (hospital.specialties.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: hospital.specialties
                        .where((specialty) {
                          final specialtyLower = specialty.toLowerCase().trim();
                          final categoryLower = widget.categoryName.toLowerCase().trim();
                          // Show specialty if it matches the category
                          return specialtyLower == categoryLower ||
                                 specialtyLower.contains(categoryLower) ||
                                 categoryLower.contains(specialtyLower) ||
                                 specialtyLower.split(RegExp(r'[\s-]+')).any((word) => 
                                   categoryLower.split(RegExp(r'[\s-]+')).contains(word));
                        })
                        .map((specialty) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B2D5B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF0B2D5B)),
                              ),
                              child: Text(
                                specialty,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0B2D5B),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Distance and Emergency
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hospital.distance > 0 
                              ? '${hospital.distance.toStringAsFixed(1)} km away'
                              : 'Distance not available',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (hospital.hasEmergency)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.emergency,
                              size: 12,
                              color: Colors.red[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Emergency',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
