import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';

class StudentLocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const StudentLocationPickerScreen({super.key, this.initialLocation});

  @override
  State<StudentLocationPickerScreen> createState() => _StudentLocationPickerScreenState();
}

class _StudentLocationPickerScreenState extends State<StudentLocationPickerScreen> {
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  bool _isLoadingLocation = false;

  // Default to Pune, Maharashtra, India if no initial location and no GPS
  static const LatLng _defaultLocation = LatLng(18.5204, 73.8567);

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    if (_selectedLocation == null) {
      _fetchCurrentLocationForMap();
    }
  }

  Future<void> _fetchCurrentLocationForMap() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions denied.';
      }
      if (permission == LocationPermission.deniedForever) throw 'Location permissions permanently denied.';

      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      final latLng = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _selectedLocation = latLng;
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16.0));
    } catch (e) {
      debugPrint("Could not fetch location for map: $e");
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    final initialCameraPosition = CameraPosition(
      target: _selectedLocation ?? _defaultLocation,
      zoom: _selectedLocation != null ? 16.0 : 12.0,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Select Home Location',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _selectedLocation == null
                ? null
                : () => Navigator.of(context).pop(_selectedLocation),
            child: const Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialCameraPosition,
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTapped,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected_home'),
                      position: _selectedLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                    ),
                  }
                : {},
          ),
          
          // Instruction Overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded, color: AppTheme.warningOrange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedLocation == null 
                          ? 'Tap anywhere on the map to place the home pin.' 
                          : 'Tap elsewhere to move the pin.',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoadingLocation)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
