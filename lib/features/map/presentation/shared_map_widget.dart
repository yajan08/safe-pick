import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SharedMapWidget extends StatelessWidget {
  final LatLng? center;
  final LatLng? driverPosition;
  final LatLng? childPosition;
  final bool showDriverMarker;

  const SharedMapWidget({
    super.key,
    this.center,
    this.driverPosition,
    this.childPosition,
    this.showDriverMarker = true,
  });

  @override
  Widget build(BuildContext context) {
    final initialCenter = center ?? driverPosition ?? childPosition ?? LatLng(21.1458, 79.0882);

    final markers = <Marker>[];
    if (childPosition != null) {
      markers.add(Marker(
        width: 40,
        height: 40,
        point: childPosition!,
        // new API uses `child` instead of `builder`
        child: const Icon(Icons.person, color: Colors.blue, size: 32),
      ));
    }
    if (showDriverMarker && driverPosition != null) {
      markers.add(Marker(
        width: 40,
        height: 40,
        point: driverPosition!,
        child: const Icon(Icons.local_taxi, color: Colors.red, size: 32),
      ));
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.safe_pick',
        ),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
      ],
    );
  }
}
