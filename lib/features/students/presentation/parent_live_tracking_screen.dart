import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_pick/features/students/data/student_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/mqtt_service.dart';

class ParentLiveTrackingScreen extends ConsumerStatefulWidget {
  final StudentModel student;

  const ParentLiveTrackingScreen({super.key, required this.student});

  @override
  ConsumerState<ParentLiveTrackingScreen> createState() => _ParentLiveTrackingScreenState();
}

class _ParentLiveTrackingScreenState extends ConsumerState<ParentLiveTrackingScreen> {
  final MqttService _mqttService = MqttService();
  bool _isConnected = false;

  // 🛑 HARDCODED FOR TESTING: 
  // Replace this with the active session ID from your database later!
  // I grabbed this from your driver terminal logs.
  final String _testSessionId = '+';

  void initState() {
    super.initState();
    _connectAndListen();
  }

  Future<void> _connectAndListen() async {
    // 1. Connect to EMQX as the parent
    final success = await _mqttService.connect('parent_${widget.student.studentId}');
    
    if (success && mounted) {
      setState(() => _isConnected = true);
      // 2. Tune into the driver's specific radio channel
      _mqttService.subscribeToTrip(_testSessionId);
    }
  }

  @override
  void dispose() {
    // Cleanly hang up when the parent closes the map
    _mqttService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('${widget.student.name}\'s Live Location'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status Indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isConnected ? AppTheme.successGreen.withValues(alpha: 0.1) : AppTheme.warningOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isConnected ? AppTheme.successGreen : AppTheme.warningOrange),
              ),
              child: Row(
                children: [
                  Icon(
                    _isConnected ? Icons.wifi_tethering_rounded : Icons.wifi_off_rounded,
                    color: _isConnected ? AppTheme.successGreen : AppTheme.warningOrange,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isConnected ? 'Connected to Live Server' : 'Connecting to Server...',
                    style: TextStyle(
                      color: _isConnected ? AppTheme.successGreen : AppTheme.warningOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // Live Data Listener
            Expanded(
              child: StreamBuilder<Map<String, dynamic>>(
                stream: _mqttService.telemetryStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppTheme.primaryGold),
                          SizedBox(height: 16),
                          Text('Waiting for van to send GPS data...', style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppTheme.errorRed)));
                  }

                  if (snapshot.hasData) {
                    final data = snapshot.data!;
                    final lat = data['latitude'] as double;
                    final lng = data['longitude'] as double;
                    final speed = data['speed'] as double;

                    // Convert m/s to km/h for readability
                    final speedKmh = (speed * 3.6).toStringAsFixed(1);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 64, color: AppTheme.primaryGold),
                        const SizedBox(height: 24),
                        _buildDataRow('Latitude', lat.toStringAsFixed(5)),
                        const SizedBox(height: 16),
                        _buildDataRow('Longitude', lng.toStringAsFixed(5)),
                        const SizedBox(height: 16),
                        _buildDataRow('Speed', '$speedKmh km/h'),
                      ],
                    );
                  }

                  return const Center(child: Text('No data available yet.'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}