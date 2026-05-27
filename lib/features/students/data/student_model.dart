import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class StudentModel {
  final String studentId;
  final String parentUid;
  final String schoolId;
  final String name;
  final String grade;
  final GeoPoint? homeLocation;
  final String status; // 'active' | 'inactive'
  final String schoolName;
  final String note;
  final String lastAttendanceStatus; // 'At Home' | 'In Van' | 'At School' | 'Absent'
  final Map<String, dynamic> stats; // e.g. {'total_trips': 0, 'attendance_rate': 1.0}
  final String? estimatedArrival;

  const StudentModel({
    required this.studentId,
    required this.parentUid,
    required this.schoolId,
    required this.name,
    required this.grade,
    this.homeLocation,
    required this.status,
    this.schoolName = '',
    this.note = '',
    this.lastAttendanceStatus = 'At Home',
    required this.stats,
    this.estimatedArrival,
  });

  /// Factory constructor to create a StudentModel from a Map
  factory StudentModel.fromJson(Map<String, dynamic> json, String id) {
    return StudentModel(
      studentId: id,
      parentUid: json['parent_uid'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      homeLocation: json['home_location'] as GeoPoint?,
      status: json['status'] as String? ?? 'active',
      schoolName: json['school_name'] as String? ?? '',
      note: json['note'] as String? ?? '',
      lastAttendanceStatus: json['last_attendance_status'] as String? ?? 'At Home',
      stats: json['stats'] as Map<String, dynamic>? ?? const {},
      estimatedArrival: json['estimated_arrival'] as String?,
    );
  }

  /// Converts the StudentModel instance into a Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'parent_uid': parentUid,
      'school_id': schoolId,
      'name': name,
      'grade': grade,
      'home_location': homeLocation,
      'status': status,
      'school_name': schoolName,
      'note': note,
      'last_attendance_status': lastAttendanceStatus,
      'stats': stats,
      'estimated_arrival': estimatedArrival,
    };
  }

  /// Creates a copy of this StudentModel but with given fields replaced
  StudentModel copyWith({
    String? studentId,
    String? parentUid,
    String? schoolId,
    String? name,
    String? grade,
    GeoPoint? homeLocation,
    String? status,
    String? schoolName,
    String? note,
    String? lastAttendanceStatus,
    Map<String, dynamic>? stats,
    String? estimatedArrival,
  }) {
    return StudentModel(
      studentId: studentId ?? this.studentId,
      parentUid: parentUid ?? this.parentUid,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      homeLocation: homeLocation ?? this.homeLocation,
      status: status ?? this.status,
      schoolName: schoolName ?? this.schoolName,
      note: note ?? this.note,
      lastAttendanceStatus: lastAttendanceStatus ?? this.lastAttendanceStatus,
      stats: stats ?? this.stats,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
    );
  }

  @override
  String toString() {
    return 'StudentModel(studentId: $studentId, name: $name, schoolName: $schoolName, status: $status, lastAttendanceStatus: $lastAttendanceStatus, estimatedArrival: $estimatedArrival)';
  }
}
