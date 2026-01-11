import 'package:flutter/material.dart';

import '../../models/hospital.dart' show Doctor;
import '../../utils/responsive.dart';
import 'doctor_details_screen.dart';

class PopularDoctorsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> popularDoctorsWithHospital;

  const PopularDoctorsScreen({
    super.key,
    required this.popularDoctorsWithHospital,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const SizedBox(height: 24),
              Text(
                'Popular\ndoctors 👨‍⚕️🔥',
                style: TextStyle(
                  fontSize: Responsive.sp(context, 40),
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              // Refresh label (visual only for now)
              Text(
                'refresh',
                style: TextStyle(
                  fontSize: Responsive.sp(context, 12),
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              // Grid of popular doctors
              Expanded(
                child: popularDoctorsWithHospital.isEmpty
                    ? Center(
                        child: Text(
                          'No popular doctors found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: popularDoctorsWithHospital.length,
                        itemBuilder: (context, index) {
                          final doctorData = popularDoctorsWithHospital[index];
                          final d = doctorData['doctor'] as Doctor;
                          return _PopularDoctorTile(
                            name: d.name,
                            specialty: d.specialty,
                            rating: d.rating,
                            imageUrl: d.imageUrl,
                            hospitalId: doctorData['hospitalId'] as String?,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularDoctorTile extends StatelessWidget {
  final String name;
  final String specialty;
  final double rating;
  final String imageUrl;
  final String? hospitalId;

  const _PopularDoctorTile({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.imageUrl,
    required this.hospitalId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorDetailsScreen(
                  doctorName: name,
                  specialty: specialty,
                  rating: rating,
                  imageUrl: imageUrl,
                  reviewCount: 124,
                  hospitalId: hospitalId,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Doctor profile image
                ClipOval(
                  child: Image.network(
                    imageUrl,
                    height: 56,
                    width: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 28,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Doctor name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                // Rating row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
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


