import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class UserModel {
  final String uid;
  final String role; // 'parent' | 'driver' | 'admin'
  final String name;
  final String phone;
  final String status; // 'active' | 'suspended' | 'pending'
  final DateTime createdAt;
  final String? managedSchoolId;
  final String gender;
  final String? vehicleNumber; // Only for drivers
  final List<String> vehicleNumbers;

  const UserModel({
    required this.uid,
    required this.role,
    required this.name,
    required this.phone,
    required this.status,
    required this.createdAt,
    this.managedSchoolId,
    this.gender = '',
    this.vehicleNumber,
    this.vehicleNumbers = const [],
  });

  /// Factory constructor to create a UserModel from a Map (e.g. Firestore document snapshot)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle created_at parsing since Firestore returns Timestamps, but we might receive string/ISO format too.
    DateTime parsedDate;
    final dynamic rawCreatedAt = json['created_at'];
    if (rawCreatedAt == null) {
      parsedDate = DateTime.now();
    } else if (rawCreatedAt is DateTime) {
      parsedDate = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      parsedDate = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      // Typically a Firestore Timestamp (has a toDate() method)
      try {
        parsedDate = (rawCreatedAt as dynamic).toDate() as DateTime;
      } catch (_) {
        parsedDate = DateTime.now();
      }
    }

    return UserModel(
      uid: json['uid'] as String? ?? '',
      role: json['role'] as String? ?? 'parent',
      name: json['name'] as String? ?? 'Unknown User',
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: parsedDate,
      managedSchoolId: json['managed_school_id'] as String?,
      gender: json['gender'] as String? ?? '',
      vehicleNumber: _parsePrimaryVehicleNumber(json),
      vehicleNumbers: _parseVehicleNumbers(json),
    );
  }

  static List<String> _parseVehicleNumbers(Map<String, dynamic> json) {
    final rawVehicleNumbers = json['vehicle_numbers'];
    if (rawVehicleNumbers is List) {
      return rawVehicleNumbers
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toList();
    }

    final legacyVehicleNumber = json['vehicle_number'] as String?;
    if (legacyVehicleNumber != null && legacyVehicleNumber.trim().isNotEmpty) {
      return [legacyVehicleNumber.trim()];
    }

    return const [];
  }

  static String? _parsePrimaryVehicleNumber(Map<String, dynamic> json) {
    final legacyVehicleNumber = json['vehicle_number'] as String?;
    if (legacyVehicleNumber != null && legacyVehicleNumber.trim().isNotEmpty) {
      return legacyVehicleNumber.trim();
    }

    final vehicleNumbers = _parseVehicleNumbers(json);
    if (vehicleNumbers.isNotEmpty) {
      return vehicleNumbers.first;
    }

    return null;
  }

  /// Converts the UserModel instance into a Map suitable for Firestore
  Map<String, dynamic> toJson() {
    final primaryVehicleNumber = vehicleNumbers.isNotEmpty
        ? vehicleNumbers.first
        : vehicleNumber?.trim();

    return {
      'uid': uid,
      'role': role,
      'name': name,
      'phone': phone,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
      'gender': gender,
      if (managedSchoolId != null) 'managed_school_id': managedSchoolId,
      if (vehicleNumbers.isNotEmpty) 'vehicle_numbers': vehicleNumbers,
      if (primaryVehicleNumber != null && primaryVehicleNumber.isNotEmpty) 'vehicle_number': primaryVehicleNumber,
    };
  }

  /// Creates a copy of this UserModel but with the given fields replaced with the new values.
  UserModel copyWith({
    String? uid,
    String? role,
    String? name,
    String? phone,
    String? status,
    DateTime? createdAt,
    String? managedSchoolId,
    String? gender,
    String? vehicleNumber,
    List<String>? vehicleNumbers,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      managedSchoolId: managedSchoolId ?? this.managedSchoolId,
      gender: gender ?? this.gender,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleNumbers: vehicleNumbers ?? this.vehicleNumbers,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.role == role &&
        other.name == name &&
        other.phone == phone &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.managedSchoolId == managedSchoolId &&
        other.gender == gender &&
        other.vehicleNumber == vehicleNumber &&
        listEquals(other.vehicleNumbers, vehicleNumbers);
  }

  @override
  int get hashCode {
    return Object.hash(uid, role, name, phone, status, createdAt, managedSchoolId, gender, vehicleNumber, Object.hashAll(vehicleNumbers));
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, role: $role, name: $name, phone: $phone, status: $status, createdAt: $createdAt, managedSchoolId: $managedSchoolId, gender: $gender, vehicleNumber: $vehicleNumber, vehicleNumbers: $vehicleNumbers)';
  }
}
