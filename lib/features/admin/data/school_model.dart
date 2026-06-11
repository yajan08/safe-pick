import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class SchoolModel {
  final String schoolId;
  final String name;
  final GeoPoint location;
  final bool isActive;
  final DateTime? createdAt;

  const SchoolModel({
    required this.schoolId,
    required this.name,
    required this.location,
    required this.isActive,
    this.createdAt,
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json, String id) {
    DateTime? parsedDate;
    final rawCreatedAt = json['created_at'];
    if (rawCreatedAt is Timestamp) {
      parsedDate = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedDate = DateTime.tryParse(rawCreatedAt);
    }

    return SchoolModel(
      schoolId: id,
      name: json['name'] as String? ?? 'Unnamed School',
      location: json['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'is_active': isActive,
      if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!),
    };
  }

  SchoolModel copyWith({
    String? schoolId,
    String? name,
    GeoPoint? location,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return SchoolModel(
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'SchoolModel(schoolId: $schoolId, name: $name, isActive: $isActive, location: [${location.latitude}, ${location.longitude}])';
  }
}
