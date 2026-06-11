import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class StudentRideLogModel {
  final String logId;
  final String sessionId;
  final String tripId;
  final String tripName;
  final String tripType;
  final String driverName;
  final String vehicleNumber;
  final String date;
  final DateTime? boardedAt;
  final DateTime? alightedAt;
  final String status;

  const StudentRideLogModel({
    required this.logId,
    required this.sessionId,
    required this.tripId,
    required this.tripName,
    required this.tripType,
    required this.driverName,
    required this.vehicleNumber,
    required this.date,
    this.boardedAt,
    this.alightedAt,
    required this.status,
  });

  factory StudentRideLogModel.fromJson(Map<String, dynamic> json, String id) {
    DateTime? parseOptionalDate(dynamic raw) {
      if (raw == null) return null;
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw);
      try {
        return (raw as dynamic).toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }

    return StudentRideLogModel(
      logId: id,
      sessionId: json['session_id'] as String? ?? '',
      tripId: json['trip_id'] as String? ?? '',
      tripName: json['trip_name'] as String? ?? '',
      tripType: json['trip_type'] as String? ?? 'Morning',
      driverName: json['driver_name'] as String? ?? '',
      vehicleNumber: json['vehicle_number'] as String? ?? '',
      date: json['date'] as String? ?? '',
      boardedAt: parseOptionalDate(json['boarded_at']),
      alightedAt: parseOptionalDate(json['alighted_at']),
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'trip_id': tripId,
      'trip_name': tripName,
      'trip_type': tripType,
      'driver_name': driverName,
      'vehicle_number': vehicleNumber,
      'date': date,
      if (boardedAt != null) 'boarded_at': Timestamp.fromDate(boardedAt!),
      if (alightedAt != null) 'alighted_at': Timestamp.fromDate(alightedAt!),
      'status': status,
    };
  }

  StudentRideLogModel copyWith({
    String? logId,
    String? sessionId,
    String? tripId,
    String? tripName,
    String? tripType,
    String? driverName,
    String? vehicleNumber,
    String? date,
    DateTime? boardedAt,
    DateTime? alightedAt,
    String? status,
  }) {
    return StudentRideLogModel(
      logId: logId ?? this.logId,
      sessionId: sessionId ?? this.sessionId,
      tripId: tripId ?? this.tripId,
      tripName: tripName ?? this.tripName,
      tripType: tripType ?? this.tripType,
      driverName: driverName ?? this.driverName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      date: date ?? this.date,
      boardedAt: boardedAt ?? this.boardedAt,
      alightedAt: alightedAt ?? this.alightedAt,
      status: status ?? this.status,
    );
  }
}
