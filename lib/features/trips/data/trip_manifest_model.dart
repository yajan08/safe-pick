import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class TripManifestModel {
  final String studentId;
  final String schoolId;
  final String name;
  final String schoolName;
  final int stopOrder;
  final String status; // 'At Home' | 'In Van' | 'At School'
  final GeoPoint? homeLocation;

  const TripManifestModel({
    required this.studentId,
    required this.schoolId,
    required this.name,
    this.schoolName = '',
    required this.stopOrder,
    required this.status,
    this.homeLocation,
  });

  /// Factory constructor to create a TripManifestModel from a Map
  factory TripManifestModel.fromJson(Map<String, dynamic> json, String id) {
    return TripManifestModel(
      studentId: id,
      schoolId: json['school_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      schoolName: json['school_name'] as String? ?? '',
      stopOrder: json['stop_order'] as int? ?? 0,
      status: json['status'] as String? ?? 'At Home',
      homeLocation: json['home_location'] as GeoPoint?,
    );
  }

  /// Converts the TripManifestModel instance into a Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'school_id': schoolId,
      'name': name,
      'school_name': schoolName,
      'stop_order': stopOrder,
      'status': status,
      'home_location': homeLocation,
    };
  }

  /// Creates a copy of this model but with given fields replaced
  TripManifestModel copyWith({
    String? studentId,
    String? schoolId,
    String? name,
    String? schoolName,
    int? stopOrder,
    String? status,
    GeoPoint? homeLocation,
  }) {
    return TripManifestModel(
      studentId: studentId ?? this.studentId,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      schoolName: schoolName ?? this.schoolName,
      stopOrder: stopOrder ?? this.stopOrder,
      status: status ?? this.status,
      homeLocation: homeLocation ?? this.homeLocation,
    );
  }

  @override
  String toString() {
    return 'TripManifestModel(studentId: $studentId, schoolId: $schoolId, name: $name, schoolName: $schoolName, stopOrder: $stopOrder, status: $status)';
  }
}
