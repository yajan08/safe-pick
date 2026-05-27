import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class TripModel {
  final String tripId;
  final String driverUid;
  final String tripName;
  final String tripType; // 'pickup' | 'dropoff'
  final List<String> schoolIds;
  final String status; // 'active' | 'inactive' | 'completed'
  final String estimatedDuration; // e.g. "45 mins"
  final DateTime? lastCompletedDate;

  const TripModel({
    required this.tripId,
    required this.driverUid,
    required this.tripName,
    required this.tripType,
    required this.schoolIds,
    required this.status,
    required this.estimatedDuration,
    this.lastCompletedDate,
  });

  /// Factory constructor to create a TripModel from a Map
  factory TripModel.fromJson(Map<String, dynamic> json, String id) {
    final rawDate = json['last_completed_date'];
    DateTime? parsedDate;
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate);
    }
    return TripModel(
      tripId: id,
      driverUid: json['driver_uid'] as String? ?? '',
      tripName: json['trip_name'] as String? ?? '',
      tripType: json['trip_type'] as String? ?? 'pickup',
      schoolIds: List<String>.from(json['school_ids'] as List? ?? const []),
      status: json['status'] as String? ?? 'inactive',
      estimatedDuration: json['estimated_duration'] as String? ?? '45 mins',
      lastCompletedDate: parsedDate,
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
      'last_completed_date': lastCompletedDate != null ? Timestamp.fromDate(lastCompletedDate!) : null,
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
    DateTime? lastCompletedDate,
  }) {
    return TripModel(
      tripId: tripId ?? this.tripId,
      driverUid: driverUid ?? this.driverUid,
      tripName: tripName ?? this.tripName,
      tripType: tripType ?? this.tripType,
      schoolIds: schoolIds ?? this.schoolIds,
      status: status ?? this.status,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
    );
  }

  @override
  String toString() {
    return 'TripModel(tripId: $tripId, driverUid: $driverUid, tripName: $tripName, tripType: $tripType, status: $status, estimatedDuration: $estimatedDuration, lastCompletedDate: $lastCompletedDate)';
  }
}
