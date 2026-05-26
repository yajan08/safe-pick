import 'package:flutter/foundation.dart';

@immutable
class UserModel {
  final String uid;
  final String role; // 'parent' | 'driver' | 'admin'
  final String name;
  final String phone;
  final String status; // 'active' | 'suspended' | 'pending'
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.role,
    required this.name,
    required this.phone,
    required this.status,
    required this.createdAt,
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
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: parsedDate,
    );
  }

  /// Converts the UserModel instance into a Map suitable for Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'role': role,
      'name': name,
      'phone': phone,
      'status': status,
      'created_at': createdAt.toIso8601String(), // In production Firestore, this is typically stored as a native Timestamp. We serialize to string or handle it in the repository.
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
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
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
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(uid, role, name, phone, status, createdAt);
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, role: $role, name: $name, phone: $phone, status: $status, createdAt: $createdAt)';
  }
}
