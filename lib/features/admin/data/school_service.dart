import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'school_model.dart';

final schoolServiceProvider = Provider<SchoolService>((ref) {
  return SchoolService();
});

final allSchoolsStreamProvider = StreamProvider<List<SchoolModel>>((ref) {
  final service = ref.watch(schoolServiceProvider);
  return service.streamAllSchools();
});

final activeSchoolsStreamProvider = StreamProvider<List<SchoolModel>>((ref) {
  final service = ref.watch(schoolServiceProvider);
  return service.streamActiveSchools();
});

class SchoolService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream all schools (for Admin panel)
  Stream<List<SchoolModel>> streamAllSchools() {
    return _firestore
        .collection('schools')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SchoolModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Stream only active schools (for Parents selecting a school)
  Stream<List<SchoolModel>> streamActiveSchools() {
    return _firestore
        .collection('schools')
        .where('is_active', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SchoolModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Create a new school
  Future<void> addSchool(SchoolModel school) async {
    final docRef = _firestore.collection('schools').doc();
    final newSchool = school.copyWith(
      schoolId: docRef.id,
      createdAt: DateTime.now(),
    );
    await docRef.set(newSchool.toJson());
  }

  /// Update an existing school
  Future<void> updateSchool(SchoolModel school) async {
    await _firestore
        .collection('schools')
        .doc(school.schoolId)
        .update(school.toJson());
  }

  /// Toggle school active status
  Future<void> toggleSchoolStatus(String schoolId, bool isActive) async {
    await _firestore
        .collection('schools')
        .doc(schoolId)
        .update({'is_active': isActive});
  }
}
