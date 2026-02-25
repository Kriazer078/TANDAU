// ignore_for_file: avoid_print
// One-time script to add contactPhone and email to ALL universities.
// Run from project root: flutter run -t scripts/update_university_contacts.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tandau/firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final FirebaseFirestore db = FirebaseFirestore.instance;

  final Map<String, Map<String, String>> updates = {
    // ── Астана ──
    '1': {'contactPhone': '+7 (7172) 70 90 22', 'email': 'nu@nu.edu.kz'},
    '2': {
      'contactPhone': '+7 (7172) 64 57 10',
      'email': 'info@astanait.edu.kz',
    },
    '3': {'contactPhone': '+7 (7172) 70 95 00', 'email': 'info@enu.kz'},
    // ── Алматы ──
    '4': {'contactPhone': '+7 (727) 377 33 33', 'email': 'info@kaznu.edu.kz'},
    '5': {
      'contactPhone': '+7 (727) 292 60 25',
      'email': 'info@satbayev.university',
    },
    '6': {'contactPhone': '+7 (727) 221 85 14', 'email': 'info@kaznpu.kz'},
    '7': {'contactPhone': '+7 (727) 357 42 42', 'email': 'info@kbtu.kz'},
    '8': {'contactPhone': '+7 (727) 377 11 11', 'email': 'info@narxoz.kz'},
    // ── Шымкент ──
    '9': {
      // ОҚМА — Южно-Казахстанская медицинская академия
      'contactPhone': '+7 (7252) 39-57-57',
      'email': 'medacadem@rambler.ru',
    },
    '10': {
      // ОҚМПУ — Педагогический университет
      'contactPhone': '+7 (7252) 21-40-06',
      'email': 'info@okmpu.kz',
    },
    '11': {
      // Ауэзов — М.О. Ауэзов атындағы ОҚУ
      'contactPhone': '+7 (7252) 21-08-94',
      'email': 'pk_ukgu@mail.ru',
    },
    '12': {
      // Мирас университеті
      'contactPhone': '+7 (7252) 33-77-77',
      'email': 'info@miras.edu.kz',
    },
    '13': {
      // Шымкент университеті
      'contactPhone': '+7 (7252) 55-58-61',
      'email': 'shu2050@mail.ru',
    },
    '14': {
      // CAIU — Орталық Азия инновациялық университеті
      'contactPhone': '+7 (7252) 37-12-37',
      'email': 'ukgi2002@mail.ru',
    },
    '15': {
      // Халықтар достығы университеті
      'contactPhone': '+7 (7252) 95-25-21',
      'email': 'info@kipudn.kz',
    },
    '16': {
      // Ж. Тәшенев атындағы университет
      'contactPhone': '+7 (776) 104-70-70',
      'email': 'info@tashenev.edu.kz',
    },
  };

  final WriteBatch batch = db.batch();
  for (final MapEntry<String, Map<String, String>> entry in updates.entries) {
    final DocumentReference ref = db.collection('universities').doc(entry.key);
    batch.update(ref, entry.value);
  }

  await batch.commit();
  print('✅ Updated ${updates.length} universities with contactPhone + email');
}
