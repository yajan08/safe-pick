import 'package:flutter/foundation.dart';

@immutable
class TripModel {
  final String tripId;
  final String driverUid;
  final String tripName;
  final String tripType; // 'pickup' | 'dropoff'
  final List<String> schoolIds;
  final String status; // 'active' | 'inactive' | 'completed'
  final String estimatedDuration; // e.g. "45 mins"
  final String approxStartTime; // e.g. "07:30 AM"

  const TripModel({
    required this.tripId,
    required this.driverUid,
    required this.tripName,
    required this.tripType,
    required this.schoolIds,
    required this.status,
    required this.estimatedDuration,
    this.approxStartTime = '',
  });

  /// Factory constructor to create a TripModel from a Map
  factory TripModel.fromJson(Map<String, dynamic> json, String id) {
    return TripModel(
      tripId: id,
      driverUid: json['driver_uid'] as String? ?? '',
      tripName: json['trip_name'] as String? ?? '',
      tripType: json['trip_type'] as String? ?? 'pickup',
      schoolIds: List<String>.from(json['school_ids'] as List? ?? const []),
      status: json['status'] as String? ?? 'inactive',
      estimatedDuration: json['estimated_duration'] as String? ?? '45 mins',
      approxStartTime: json['approx_start_time'] as String? ?? '',
    );
  }

  /// Converts the TripModel instance into a Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'driver_uid': driverUid,
      'trip_name': tripName,
      'trip_type': tripType,
      'school_ids': schoolIds,
      'status': status,
      'estimated_duration': estimatedDuration,
      'approx_start_time': approxStartTime,
    };
  }

  /// Creates a copy of this TripModel but with given fields replaced
  TripModel copyWith({
    String? tripId,
    String? driverUid,
    String? tripName,
    String? tripType,
    List<String>? schoolIds,
    String? status,
    String? estimatedDuration,
    String? approxStartTime,
  }) {
    return TripModel(
      tripId: tripId ?? this.tripId,
      driverUid: driverUid ?? this.driverUid,
      tripName: tripName ?? this.tripName,
      tripType: tripType ?? this.tripType,
      schoolIds: schoolIds ?? this.schoolIds,
      status: status ?? this.status,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      approxStartTime: approxStartTime ?? this.approxStartTime,
    );
  }

  @override
  String toString() {
    return 'TripModel(tripId: $tripId, driverUid: $driverUid, tripName: $tripName, tripType: $tripType, status: $status, approxStartTime: $approxStartTime, estimatedDuration: $estimatedDuration)';
  }
}
