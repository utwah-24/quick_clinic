import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_service.dart';
import '../services/localization_service.dart';

class LocationPermissionScreen extends StatefulWidget {
  final VoidCallback onPermissionGranted;

  const LocationPermissionScreen({
    super.key,
    required this.onPermissionGranted,
  });

  @override
  _LocationPermissionScreenState createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isLoading = false;

  static const String _kLocationPermissionGrantedKey = 'location_permission_granted';

  @override
  void initState() {
    super.initState();
    _checkSavedPermission();
  }

  Future<void> _checkSavedPermission() async {
    setState(() {
      _isLoading = true;
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool alreadyGranted =
        prefs.getBool(_kLocationPermissionGrantedKey) ?? false;

    if (alreadyGranted && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onPermissionGranted();
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on,
              size: 100,
              // color: Color(,
            ),
            const SizedBox(height: 32),
            Text(
              LocalizationService.translate('location_permission'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              LocalizationService.translate('location_permission_desc'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _requestLocation,
                      child: Text(LocalizationService.translate('allow_location')),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // Continue without location (limited functionality)
                      widget.onPermissionGranted();
                    },
                    child: Text(LocalizationService.translate('deny')),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _requestLocation() async {
    setState(() {
      _isLoading = true;
    });

    final result = await LocationService.getCurrentLocation();
    
    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kLocationPermissionGrantedKey, true);
      widget.onPermissionGranted();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
