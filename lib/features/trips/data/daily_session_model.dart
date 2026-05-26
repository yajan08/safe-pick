import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class DailySessionModel {
  final String sessionId;
  final String tripId;
  final String driverUid;
  final String date;
  final String status; // 'not_started' | 'in_progress' | 'paused' | 'completed'
  final String mqttTopicId;
  final DateTime startTime;
  final DateTime? endTime;

  const DailySessionModel({
    required this.sessionId,
    required this.tripId,
    required this.driverUid,
    required this.date,
    required this.status,
    required this.mqttTopicId,
    required this.startTime,
    this.endTime,
  });

  factory DailySessionModel.fromJson(Map<String, dynamic> json, String id) {
    DateTime parseDate(dynamic raw) {
      if (raw == null) return DateTime.now();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
      try {
        return (raw as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

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

    return DailySessionModel(
      sessionId: id,
      tripId: json['trip_id'] as String? ?? '',
      driverUid: json['driver_uid'] as String? ?? '',
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? 'not_started',
      mqttTopicId: json['mqtt_topic_id'] as String? ?? '',
      startTime: parseDate(json['start_time']),
      endTime: parseOptionalDate(json['end_time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'driver_uid': driverUid,
      'date': date,
      'status': status,
      'mqtt_topic_id': mqttTopicId,
      'start_time': Timestamp.fromDate(startTime),
      if (endTime != null) 'end_time': Timestamp.fromDate(endTime!),
    };
  }

  DailySessionModel copyWith({
    String? sessionId,
    String? tripId,
    String? driverUid,
    String? date,
    String? status,
    String? mqttTopicId,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return DailySessionModel(
      sessionId: sessionId ?? this.sessionId,
      tripId: tripId ?? this.tripId,
      driverUid: driverUid ?? this.driverUid,
      date: date ?? this.date,
      status: status ?? this.status,
      mqttTopicId: mqttTopicId ?? this.mqttTopicId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
