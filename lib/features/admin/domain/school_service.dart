import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/school_model.dart';

final schoolServiceProvider = Provider((ref) => SchoolService());

final schoolsStreamProvider = StreamProvider<List<SchoolModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('schools')
      .snapshots()
      .map((snap) {
        final schools = snap.docs.map((doc) => SchoolModel.fromJson(doc.data(), doc.id)).toList();
        schools.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return schools;
      });
});

final activeSchoolsProvider = Provider<AsyncValue<List<SchoolModel>>>((ref) {
  final asyncSchools = ref.watch(schoolsStreamProvider);
  return asyncSchools.whenData((schools) => schools.where((s) => s.isActive).toList());
});

class SchoolService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addSchool({required String name, required GeoPoint location}) async {
    final docRef = _firestore.collection('schools').doc();
    final school = SchoolModel(
      schoolId: docRef.id,
      name: name,
      location: location,
      isActive: true,
      createdAt: DateTime.now(),
    );
    await docRef.set(school.toJson());
  }

  Future<void> updateSchool({required String schoolId, required String name, required GeoPoint location}) async {
    await _firestore.collection('schools').doc(schoolId).update({
      'name': name,
      'location': location,
    });
  }

  Future<void> toggleSchoolStatus(String schoolId, bool isActive) async {
    await _firestore.collection('schools').doc(schoolId).update({
      'is_active': isActive,
    });
  }
}
