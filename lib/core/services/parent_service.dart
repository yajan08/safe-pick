import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

final parentServiceProvider = Provider<ParentService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return ParentService(firestore, auth.currentUser?.uid);
});

class ParentService {
  final FirebaseFirestore _firestore;
  final String? _parentUid;

  ParentService(this._firestore, this._parentUid);

  /// Performs a complete deletion of a student profile and removes references from the parent's children array.
  Future<void> deleteChild(String studentId) async {
    final parentUid = _parentUid;
    if (parentUid == null) {
      throw 'Parent user must be authenticated to delete a student.';
    }

    final batch = _firestore.batch();

    // 1. Delete the actual student document
    final studentRef = _firestore.collection('students').doc(studentId);
    batch.delete(studentRef);

    // 2. Remove the student ID reference from the parent's children array
    final parentRef = _firestore.collection('users').doc(parentUid);
    batch.update(parentRef, {
      'children': FieldValue.arrayRemove([studentId]),
    });

    await batch.commit();
  }
}
