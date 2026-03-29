import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/university.dart';
import '../services/university_service.dart';
import '../data/ent_specialties_2026.dart';
import '../services/grant_chance_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

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

/// 👤 Провайдер текущего пользователя из AuthService (реактивный)
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final auth = AuthService();
  // Используем Stream, так как в AuthService есть подписка на Firestore
  // Но если хотим просто слушать ValueNotifier:
  final controller = StreamController<UserModel?>();
  void listener() => controller.add(auth.currentUser.value);
  auth.currentUser.addListener(listener);
  controller.add(auth.currentUser.value);
  
  ref.onDispose(() {
    auth.currentUser.removeListener(listener);
    controller.close();
  });
  
  return controller.stream;
});

/// 📊 Модель результата для списка
class GrantResultItem {
  final University university;
  final GrantChanceResult chanceResult;

  GrantResultItem({
    required this.university,
    required this.chanceResult,
  });
}

/// 🎯 Провайдер вычисленных шансов
/// Автоматически пересчитывает при изменении входных данных
final computedGrantResultsProvider =
    Provider.family<AsyncValue<List<GrantResultItem>>, EntSpecialty?>((ref, specialty) {
  final universitiesAsync = ref.watch(universitiesProvider);
  final userAsync = ref.watch(currentUserProvider);
  final entScore = ref.watch(untScoreProvider);
  
  // Комбинируем два асинхронных источника
  return universitiesAsync.when(
    data: (universities) => userAsync.when(
      data: (user) {
        if (universities.isEmpty) return const AsyncData([]);

        final chanceService = GrantChanceService();
        final List<GrantResultItem> results = [];

        for (final uni in universities) {
          GrantChanceResult chance;
          if (specialty != null) {
            chance = chanceService.calculateBySpecialty(
              entScore: entScore,
              minPassingScore: specialty.predictedMin2026,
              grantQuota: specialty.grantQuota2025,
              trendName: specialty.trend.name,
              universityId: uni.id,
              universityPassingScore: uni.passingScore,
              gpa: user?.gpa,
              ieltsScore: user?.ieltsScore,
              achievements: user?.achievements ?? [],
              hasDisability: user?.hasDisability ?? false,
              isOrphan: user?.isOrphan ?? false,
              isRural: user?.isRural ?? false,
            );
          } else {
            final cat = uni.majors.isNotEmpty
                ? chanceService.detectCategory(uni.majors.first)
                : MajorCategory.other;
            chance = chanceService.calculate(
              entScore: entScore,
              universityId: uni.id,
              universityPassingScore: uni.passingScore,
              majorCategory: cat,
              gpa: user?.gpa,
              ieltsScore: user?.ieltsScore,
              achievements: user?.achievements ?? [],
              userCity: user?.city,
              universityCity: uni.city,
            );
          }
          results.add(GrantResultItem(university: uni, chanceResult: chance));
        }

        // Сортировка по убыванию шанса
        results.sort((a, b) => 
          b.chanceResult.chancePercent.compareTo(a.chanceResult.chancePercent));

        return AsyncData(results);
      },
      loading: () => const AsyncLoading<List<GrantResultItem>>(),
      error: (e, st) => AsyncError<List<GrantResultItem>>(e, st),
    ),
    loading: () => const AsyncLoading<List<GrantResultItem>>(),
    error: (e, st) => AsyncError<List<GrantResultItem>>(e, st),
  );
});
