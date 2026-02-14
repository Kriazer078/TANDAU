import 'dart:io';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../models/university.dart';

class FirebaseService {
  late FirestoreApi _firestoreApi;
  final String _projectId;

  FirebaseService(this._projectId);

  Future<void> init() async {
    // Path to your service account key file.
    // Ensure you download this from Firebase Console: Project Settings -> Service Accounts -> Generate new private key
    final serviceAccountPath =
        Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'] ??
            'service_account.json';

    if (!File(serviceAccountPath).existsSync()) {
      // print(
      //     'Warning: Service account file not found at $serviceAccountPath. Using default application credentials if available.');
      // Fallback to default creds or error handling
      var client = await clientViaApplicationDefaultCredentials(
          scopes: [FirestoreApi.datastoreScope]);
      _firestoreApi = FirestoreApi(client);
    } else {
      final accountCredentials = ServiceAccountCredentials.fromJson(
          await File(serviceAccountPath).readAsString());

      final client = await clientViaServiceAccount(
          accountCredentials, [FirestoreApi.datastoreScope]);
      _firestoreApi = FirestoreApi(client);
    }
  }

  Future<List<University>> getUniversities() async {
    final parent = 'projects/$_projectId/databases/(default)/documents';

    try {
      // List documents in 'universities' collection
      final response = await _firestoreApi.projects.databases.documents
          .list(parent, 'universities', pageSize: 100);

      if (response.documents == null) return [];

      return response.documents!.map((doc) {
        final fields = doc.fields!;
        final id = doc.name!.split('/').last;

        // Helper to extract value from Firestore Value object
        dynamic getValue(Value v) {
          if (v.stringValue != null) return v.stringValue;
          if (v.integerValue != null) return int.tryParse(v.integerValue!) ?? 0;
          if (v.doubleValue != null) return v.doubleValue;
          if (v.booleanValue != null) return v.booleanValue;
          if (v.arrayValue != null) {
            return v.arrayValue!.values?.map((e) => getValue(e)).toList() ?? [];
          }
          return null; // Handle mapValue, timestampValue as needed
        }

        Map<String, dynamic> json = {};
        fields.forEach((key, value) {
          json[key] = getValue(value);
        });

        // Handle some field name mapping if necessary, or rely on model.
        // Ensure array conversion
        if (json['subjects'] is! List) json['subjects'] = [];

        return University.fromJson(json, id);
      }).toList();
    } catch (e) {
      // stderr.writeln('Error fetching universities: $e');
      return [];
    }
  }
}
