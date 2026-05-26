
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/telemetry_consumer.dart';
import '../../../core/services/mqtt_service.dart';
import '../../students/data/student_model.dart';

/// Full-screen live tracking map for the parent.
///
/// Shows:
///  • Driver's van location — updates live via MQTT telemetry
///  • Child's home marker (static)
class LiveTrackingMapScreen extends ConsumerStatefulWidget {
  final StudentModel student;
  final String sessionId;

  const LiveTrackingMapScreen({
    super.key,
    required this.student,
    required this.sessionId,
  });

  @override
  ConsumerState<LiveTrackingMapScreen> createState() =>
      _LiveTrackingMapScreenState();
}

class _LiveTrackingMapScreenState
    extends ConsumerState<LiveTrackingMapScreen> {
  final MapController _mapController = MapController();
  bool _followDriver = true; // Auto-pan to driver on each update

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final telemetryAsync = ref.watch(parentTelemetryProvider(widget.sessionId));

    // Child's home position (may be null if not captured)
    final homeGeo = widget.student.homeLocation;
    final homeLatLng = homeGeo != null
        ? LatLng(homeGeo.latitude, homeGeo.longitude)
        : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              '${widget.student.name}\'s Trip',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Live Tracking',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppTheme.successGreen, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _followDriver ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
              color: _followDriver ? AppTheme.primaryGold : AppTheme.textMuted,
            ),
            tooltip: _followDriver ? 'Auto-follow ON' : 'Auto-follow OFF',
            onPressed: () => setState(() => _followDriver = !_followDriver),
          ),
        ],
      ),
      body: telemetryAsync.when(
        data: (payload) {
          // Pan to driver as telemetry comes in (if auto-follow enabled)
          if (payload != null && _followDriver) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _mapController.move(
                  LatLng(payload.latitude, payload.longitude),
                  15,
                );
              }
            });
          }

          return _buildMap(theme, payload, homeLatLng);
        },
        loading: () => _buildMap(theme, null, homeLatLng),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
                  color: AppTheme.errorRed, size: 56),
              const SizedBox(height: 16),
              Text('Live signal error',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(e.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap(ThemeData theme, TelemetryPayload? payload, LatLng? homeLatLng) {
    // Determine the initial center: prefer driver, then home, then Mumbai default
    LatLng initialCenter;
    if (payload != null) {
      initialCenter = LatLng(payload.latitude, payload.longitude);
    } else if (homeLatLng != null) {
      initialCenter = homeLatLng;
    } else {
      initialCenter = const LatLng(19.0760, 72.8777);
    }

    final List<Marker> markers = [];

    // Child's home marker
    if (homeLatLng != null) {
      markers.add(
        Marker(
          point: homeLatLng,
          width: 64,
          height: 72,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.successGreen.withValues(alpha: 0.4),
                        blurRadius: 6),
                  ],
                ),
                child: Text(
                  widget.student.name.split(' ').first,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.home_rounded, color: AppTheme.successGreen, size: 30),
            ],
          ),
        ),
      );
    }

    // Driver van marker (live)
    if (payload != null) {
      markers.add(
        Marker(
          point: LatLng(payload.latitude, payload.longitude),
          width: 72,
          height: 80,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.primaryGold.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1),
                  ],
                ),
                child: Text(
                  '${(payload.speed * 3.6).toStringAsFixed(0)} km/h',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.directions_bus_rounded,
                  color: AppTheme.primaryGold, size: 32),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onPositionChanged: (pos, hasGesture) {
              // User dragged map — disable auto-follow
              if (hasGesture && _followDriver) {
                setState(() => _followDriver = false);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.safepick.app',
              maxZoom: 19,
            ),
            MarkerLayer(markers: markers),
          ],
        ),

        // Top: Connecting / Waiting overlay when no payload yet
        if (payload == null)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Waiting for driver signal…',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ).animate().fadeIn(),
          ),

        // Bottom: Info card
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: _buildInfoCard(theme, payload),
        ),
      ],
    );
  }

  Widget _buildInfoCard(ThemeData theme, TelemetryPayload? payload) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          // Driver pin legend
          const Icon(Icons.directions_bus_rounded,
              color: AppTheme.primaryGold, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payload != null ? 'Van is moving' : 'Waiting for signal',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (payload != null)
                  Text(
                    '${payload.latitude.toStringAsFixed(5)}, ${payload.longitude.toStringAsFixed(5)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: AppTheme.textMuted),
                  ),
              ],
            ),
          ),
          // Home legend
          const Icon(Icons.home_rounded,
              color: AppTheme.successGreen, size: 28),
          const SizedBox(width: 4),
          Text('Home',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppTheme.successGreen)),
        ],
      ),
    );
  }
}
