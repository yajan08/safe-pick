import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../data/trip_service.dart';
import '../data/trip_manifest_model.dart';

/// Full-screen map for the driver showing:
///  • Home-pin markers for every student on the manifest
///  • Driver's own real-time GPS location (blue dot + label)
class TripMapScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String tripName;

  const TripMapScreen({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  ConsumerState<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends ConsumerState<TripMapScreen> {
  final MapController _mapController = MapController();
  Position? _driverPosition;
  StreamSubscription<Position>? _positionSub;
  bool _locationError = false;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    // Request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      if (mounted) setState(() => _locationError = true);
      return;
    }

    // Get immediate last-known position first for fast initial paint
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && mounted) {
        setState(() => _driverPosition = last);
        _mapController.move(LatLng(last.latitude, last.longitude), 14);
      }
    } catch (_) {}

    // Stream live updates
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((pos) {
      if (mounted) {
        setState(() => _driverPosition = pos);
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manifestAsync = ref.watch(manifestWithLocationsProvider(widget.tripId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              widget.tripName,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Student Stops & Live Location',
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_driverPosition != null)
            IconButton(
              icon: const Icon(Icons.my_location_rounded, color: AppTheme.primaryGold),
              tooltip: 'Center on my location',
              onPressed: () => _mapController.move(
                LatLng(_driverPosition!.latitude, _driverPosition!.longitude),
                15,
              ),
            ),
        ],
      ),
      body: manifestAsync.when(
        data: (manifest) => _buildMap(context, theme, manifest),
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load map', style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.errorRed)),
              const SizedBox(height: 8),
              Text(e.toString(), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap(BuildContext context, ThemeData theme, List<TripManifestModel> manifest) {
    // Build the home-pin markers
    final homeMarkers = manifest
        .where((s) => s.homeLocation != null)
        .map((s) => _buildHomeMarker(s))
        .toList();

    // Determine initial center — prefer driver location, else first student home
    LatLng initialCenter;
    double initialZoom = 13;

    if (_driverPosition != null) {
      initialCenter = LatLng(_driverPosition!.latitude, _driverPosition!.longitude);
    } else if (homeMarkers.isNotEmpty && manifest.first.homeLocation != null) {
      final loc = manifest.first.homeLocation!;
      initialCenter = LatLng(loc.latitude, loc.longitude);
    } else {
      // Fallback: Mumbai
      initialCenter = const LatLng(19.0760, 72.8777);
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // OSM tile layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.safepick.app',
              maxZoom: 19,
            ),

            // Student home-pin markers
            MarkerLayer(markers: homeMarkers),

            // Driver live location
            if (_driverPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_driverPosition!.latitude, _driverPosition!.longitude),
                    width: 60,
                    height: 70,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1),
                            ],
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Icon(Icons.directions_bus_rounded, color: Colors.blue.shade700, size: 28),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Legend card
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: _buildLegend(theme, manifest),
        ),

        // Location error banner
        if (_locationError)
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_off, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Location permission denied. Enable in Settings.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Marker _buildHomeMarker(TripManifestModel student) {
    final loc = student.homeLocation!;
    // Colour: green=dropped, gold=onboarded, grey=pending, red=absent
    Color pinColor;
    switch (student.status.toLowerCase()) {
      case 'onboarded':
        pinColor = AppTheme.primaryGold;
        break;
      case 'dropped':
        pinColor = AppTheme.successGreen;
        break;
      case 'absent':
        pinColor = AppTheme.errorRed;
        break;
      default:
        pinColor = Colors.grey.shade600;
    }

    return Marker(
      point: LatLng(loc.latitude, loc.longitude),
      width: 60,
      height: 70,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: pinColor,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(color: pinColor.withValues(alpha: 0.4), blurRadius: 4),
              ],
            ),
            child: Text(
              student.name.split(' ').first,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.home_rounded, color: pinColor, size: 28),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme, List<TripManifestModel> manifest) {
    final withLoc = manifest.where((s) => s.homeLocation != null).length;
    final total = manifest.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.background.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Student Stops ($withLoc/$total with GPS)',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _legendChip(theme, Colors.grey.shade600, 'Pending'),
              _legendChip(theme, AppTheme.primaryGold, 'In Van'),
              _legendChip(theme, AppTheme.successGreen, 'Dropped'),
              _legendChip(theme, AppTheme.errorRed, 'Absent'),
              _legendChip(theme, Colors.blue.shade700, 'Driver'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendChip(ThemeData theme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
      ],
    );
  }
}
