import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/university.dart';
import '../services/university_service.dart';
import '../data/ent_specialties_2026.dart';

final untScoreProvider = StateProvider<int>((ref) => 50);

/// 🎯 Направление ЕНТ: 'physMath' или 'humanities'
final subjectTypeProvider = StateProvider<String?>((ref) => null);

/// 🎯 Выбранный профильный предмет
final selectedSubjectProvider = StateProvider<String?>((ref) => null);

/// 🎯 Выбранная специальность (ГОП)
final selectedSpecialtyProvider = StateProvider<EntSpecialty?>((ref) => null);

final universitiesProvider = FutureProvider<List<University>>((ref) async {
  final service = UniversityService();
  return await service.getAllUniversities();
});
