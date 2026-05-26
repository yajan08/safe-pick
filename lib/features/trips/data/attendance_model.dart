import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class AttendanceModel {
  final String studentId;
  final String status; // 'pending' | 'onboarded' | 'dropped' | 'absent'
  final DateTime? boardedAt;
  final DateTime? alightedAt;

  const AttendanceModel({
    required this.studentId,
    required this.status,
    this.boardedAt,
    this.alightedAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json, String id) {
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

    return AttendanceModel(
      studentId: id,
      status: json['status'] as String? ?? 'pending',
      boardedAt: parseOptionalDate(json['boarded_at']),
      alightedAt: parseOptionalDate(json['alighted_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      if (boardedAt != null) 'boarded_at': Timestamp.fromDate(boardedAt!),
      if (alightedAt != null) 'alighted_at': Timestamp.fromDate(alightedAt!),
    };
  }

  AttendanceModel copyWith({
    String? studentId,
    String? status,
    DateTime? boardedAt,
    DateTime? alightedAt,
  }) {
    return AttendanceModel(
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      boardedAt: boardedAt ?? this.boardedAt,
      alightedAt: alightedAt ?? this.alightedAt,
    );
  }
}
