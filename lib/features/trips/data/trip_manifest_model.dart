import 'package:flutter/foundation.dart';

@immutable
class TripManifestModel {
  final String studentId;
  final String schoolId;
  final String name;
  final int stopOrder;
  final String status; // 'active' | 'absent' | 'skipped'
  final String expectedTime; // e.g. "07:30 AM"

  const TripManifestModel({
    required this.studentId,
    required this.schoolId,
    required this.name,
    required this.stopOrder,
    required this.status,
    required this.expectedTime,
  });

  /// Factory constructor to create a TripManifestModel from a Map
  factory TripManifestModel.fromJson(Map<String, dynamic> json, String id) {
    return TripManifestModel(
      studentId: id,
      schoolId: json['school_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      stopOrder: json['stop_order'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      expectedTime: json['expected_time'] as String? ?? '07:30 AM',
    );
  }

  /// Converts the TripManifestModel instance into a Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'school_id': schoolId,
      'name': name,
      'stop_order': stopOrder,
      'status': status,
      'expected_time': expectedTime,
    };
  }

  /// Creates a copy of this model but with given fields replaced
  TripManifestModel copyWith({
    String? studentId,
    String? schoolId,
    String? name,
    int? stopOrder,
    String? status,
    String? expectedTime,
  }) {
    return TripManifestModel(
      studentId: studentId ?? this.studentId,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      stopOrder: stopOrder ?? this.stopOrder,
      status: status ?? this.status,
      expectedTime: expectedTime ?? this.expectedTime,
    );
  }

  @override
  String toString() {
    return 'TripManifestModel(studentId: $studentId, schoolId: $schoolId, name: $name, stopOrder: $stopOrder, status: $status)';
  }
}
