import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'shared_map_widget.dart';

class ParentMapScreen extends StatefulWidget {
  final String driverUid;
  const ParentMapScreen({super.key, required this.driverUid});

  @override
  State<ParentMapScreen> createState() => _ParentMapScreenState();
}

class _ParentMapScreenState extends State<ParentMapScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  LatLng? _driverPos;

  @override
  void initState() {
    super.initState();
    _sub = _firestore.collection('users').doc(widget.driverUid).snapshots().listen((snap) {
      final data = snap.data();
      if (data != null && data['current_location'] is GeoPoint) {
        final gp = data['current_location'] as GeoPoint;
        setState(() {
          _driverPos = LatLng(gp.latitude, gp.longitude);
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parent Map')),
      body: SafeArea(
        child: SharedMapWidget(
          center: _driverPos,
          driverPosition: _driverPos,
          showDriverMarker: true,
        ),
      ),
    );
  }
}
