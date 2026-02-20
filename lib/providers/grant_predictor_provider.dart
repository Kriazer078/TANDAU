import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/university.dart';
import '../services/university_service.dart';

final untScoreProvider = StateProvider<int>((ref) => 50);

final universitiesProvider = FutureProvider<List<University>>((ref) async {
  final service = UniversityService();
  return await service.getAllUniversities();
});
