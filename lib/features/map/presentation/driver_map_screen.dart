import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/map_service.dart';
import 'shared_map_widget.dart';

class DriverMapScreen extends StatefulWidget {
  const DriverMapScreen({super.key});

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  final MapService _mapService = MapService();
  StreamSubscription<Position>? _publishSub;
  StreamSubscription<Position>? _posSub;
  LatLng? _current;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final permission = await _mapService.requestPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        _publishSub = _mapService.startPublishingLocation(uid);
        _posSub = _mapService.positionStream().listen((pos) {
          setState(() {
            _current = LatLng(pos.latitude, pos.longitude);
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _publishSub?.cancel();
    _posSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Map')),
      body: SafeArea(
        child: SharedMapWidget(
          center: _current,
          driverPosition: _current,
          showDriverMarker: true,
        ),
      ),
    );
  }
}
