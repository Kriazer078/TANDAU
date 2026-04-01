import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/universities.dart';

/// One-time script to upload all 16 universities to Firestore.
/// Call [uploadAllUniversities] from anywhere (e.g. admin panel).
/// After successful upload, this file can be deleted.
class FirestoreUploadScript {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload all universities from [sampleUniversities] to Firestore.
  /// Overwrites existing documents with the same ID.
  static Future<bool> uploadAllUniversities() async {
    try {
      debugPrint(
        '🚀 Starting upload of ${universitiesList.length} universities...',
      );

      final WriteBatch batch = _firestore.batch();

      for (final university in universitiesList) {
        final DocumentReference docRef =
            _firestore.collection('universities').doc(university.id);

        batch.set(docRef, {
          'id': university.id,
          'name': university.name,
          'city': university.city,
          'logoUrl': university.logoUrl,
          'imageUrls': university.imageUrls,
          'majors': university.majors,
          'passingScore': university.passingScore,
          'tuitionRange': university.tuitionRange,
          'hasDormitory': university.hasDormitory,
          'hasGrants': university.hasGrants,
          'description': university.description,
          'requirements': university.requirements,
          'applicationDeadline': university.applicationDeadline,
          'address': university.address,
          'website': university.website,
          'rating': university.rating,
          'studentCount': university.studentCount,
          'likesCount': 0,
          'reviewsCount': 0,
          'averageRating': 0.0,
        });

        debugPrint('  📌 Prepared: ${university.name} (${university.city})');
      }

      await batch.commit();
      debugPrint(
        '✅ Successfully uploaded ${universitiesList.length} universities!',
      );
      return true;
    } catch (e, stack) {
      debugPrint('❌ Error uploading universities: $e');
      debugPrint('Stack: $stack');
      return false;
    }
  }
}
