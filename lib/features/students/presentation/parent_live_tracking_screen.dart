import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_pick/features/students/data/student_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/mqtt_service.dart';
import '../../trips/presentation/utils/marker_generator.dart';
import '../../../core/services/auth_service.dart';

class ParentLiveTrackingScreen extends ConsumerStatefulWidget {
  final StudentModel student;
  final String sessionId;

  const ParentLiveTrackingScreen({
    super.key, 
    required this.student,
    required this.sessionId,
  });

  @override
  ConsumerState<ParentLiveTrackingScreen> createState() => _ParentLiveTrackingScreenState();
}

class _ParentLiveTrackingScreenState extends ConsumerState<ParentLiveTrackingScreen> {
  final MqttService _mqttService = MqttService();
  bool _isConnected = false;
  
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  BitmapDescriptor? _vanMarker;
  BitmapDescriptor? _homeMarkerCache;
  
  double? _distanceInMeters;
  double _currentSpeedKmh = 0.0;
  LatLng? _currentVanPosition;

  bool _autoCenter = true;
  bool _isAnimating = false;

  DateTime? _lastTelemetryTime;
  Timer? _staleTimer;
  bool _isDataStale = false;

  @override
  void initState() {
    super.initState();
    _initMarkers();
    _connectAndListen();
    _staleTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_lastTelemetryTime != null && mounted) {
        final secondsSinceLast = DateTime.now().difference(_lastTelemetryTime!).inSeconds;
        if (secondsSinceLast > 15 && !_isDataStale) {
          setState(() => _isDataStale = true);
        }
      }
    });
  }
  
  Future<void> _initMarkers() async {
    String? vehicleNumber;
    try {
      final firestore = ref.read(firestoreProvider);
      final sessionDoc = await firestore.collection('daily_sessions').doc(widget.sessionId).get();
      if (sessionDoc.exists) {
        vehicleNumber = sessionDoc.data()?['vehicle_number'] as String?;
        if (vehicleNumber == null || vehicleNumber.isEmpty) {
          final driverUid = sessionDoc.data()?['driver_uid'] as String?;
          if (driverUid != null) {
            final driverDoc = await firestore.collection('users').doc(driverUid).get();
            if (driverDoc.exists) {
              vehicleNumber = driverDoc.data()?['vehicle_number'] as String?;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching vehicle number for marker: $e');
    }

    _vanMarker = await MarkerGenerator.createDriverVanMarker(vehicleNumber: vehicleNumber);
    if (widget.student.homeLocation != null) {
      _homeMarkerCache = await MarkerGenerator.createStudentMarker(widget.student.name, Colors.blue);
    }
    _updateMapMarkers();
  }

  Future<void> _connectAndListen() async {
    final success = await _mqttService.connect('parent_${widget.student.studentId}');
    if (success && mounted) {
      setState(() => _isConnected = true);
      _mqttService.subscribeToTrip(widget.sessionId);
    }
  }

  @override
  void dispose() {
    _staleTimer?.cancel();
    _mqttService.disconnect();
    _mapController?.dispose();
    super.dispose();
  }
  
  void _updateMapMarkers() {
    final Set<Marker> newMarkers = {};
    
    // 1. Draw Home Marker
    if (widget.student.homeLocation != null && _homeMarkerCache != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('home_marker'),
        position: LatLng(widget.student.homeLocation!.latitude, widget.student.homeLocation!.longitude),
        icon: _homeMarkerCache!,
      ));
    }
    
    // 2. Draw Van Marker
    if (_currentVanPosition != null && _vanMarker != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('van_marker'),
        position: _currentVanPosition!,
        icon: _vanMarker!,
        zIndexInt: 100,
        anchor: const Offset(0.5, 0.5),
      ));
    }
    
    setState(() {
      _markers = newMarkers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('${widget.student.name}\'s Live Location'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. Google Map Layer
          StreamBuilder<Map<String, dynamic>>(
            stream: _mqttService.telemetryStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final data = snapshot.data!;
                final lat = data['latitude'] as double;
                final lng = data['longitude'] as double;
                final speed = data['speed'] as double;

                _currentVanPosition = LatLng(lat, lng);
                _currentSpeedKmh = speed * 3.6;
                _lastTelemetryTime = DateTime.now();
                if (_isDataStale) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _isDataStale = false);
                  });
                }

                // Native Distance Calculation
                if (widget.student.homeLocation != null) {
                  _distanceInMeters = Geolocator.distanceBetween(
                    lat, lng, 
                    widget.student.homeLocation!.latitude, 
                    widget.student.homeLocation!.longitude
                  );
                }

                // Smoothly animate camera
                if (_mapController != null && _autoCenter) {
                  _isAnimating = true;
                  _mapController!.animateCamera(CameraUpdate.newLatLng(_currentVanPosition!)).then((_) {
                    if (mounted) _isAnimating = false;
                  });
                }

                // Ensure markers are repainted asynchronously
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _updateMapMarkers();
                });
              }

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: widget.student.homeLocation != null 
                      ? LatLng(widget.student.homeLocation!.latitude, widget.student.homeLocation!.longitude)
                      : const LatLng(0, 0),
                  zoom: 15,
                ),
                markers: _markers,
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_currentVanPosition != null) {
                    _isAnimating = true;
                    _mapController!.moveCamera(CameraUpdate.newLatLng(_currentVanPosition!)).then((_) {
                      if (mounted) _isAnimating = false;
                    });
                  }
                },
                onCameraMoveStarted: () {
                  if (!_isAnimating && _autoCenter) {
                    if (mounted) setState(() => _autoCenter = false);
                  }
                },
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
              );
            },
          ),
          
          // 2. Auto-Center FAB
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'auto_center_fab',
              backgroundColor: _autoCenter ? AppTheme.primaryGold : AppTheme.surface,
              foregroundColor: _autoCenter ? Colors.white : AppTheme.textSecondary,
              onPressed: () {
                setState(() => _autoCenter = true);
                if (_currentVanPosition != null && _mapController != null) {
                  _isAnimating = true;
                  _mapController!.animateCamera(CameraUpdate.newLatLng(_currentVanPosition!)).then((_) {
                    if (mounted) _isAnimating = false;
                  });
                }
              },
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // 3. Glassmorphism Info Overlay
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        !_isConnected 
                          ? Icons.wifi_off_rounded 
                          : (_isDataStale ? Icons.warning_rounded : Icons.wifi_tethering_rounded),
                        color: !_isConnected || _isDataStale ? AppTheme.warningOrange : AppTheme.successGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          !_isConnected 
                            ? 'Connecting...' 
                            : (_isDataStale ? 'Driver location unavailable. They may be offline.' : 'Live Telemetry Active'),
                          style: TextStyle(
                            color: !_isConnected || _isDataStale ? AppTheme.warningOrange : AppTheme.successGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric(
                        Icons.speed_rounded, 
                        'Speed', 
                        '${_currentSpeedKmh.toStringAsFixed(1)} km/h'
                      ),
                      Container(width: 1, height: 40, color: AppTheme.border),
                      _buildMetric(
                        Icons.route_rounded, 
                        'Distance', 
                        _distanceInMeters != null 
                            ? (_distanceInMeters! > 1000 
                                ? '${(_distanceInMeters! / 1000).toStringAsFixed(1)} km' 
                                : '${_distanceInMeters!.toStringAsFixed(0)} m')
                            : 'N/A'
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(IconData icon, String label, String value) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}