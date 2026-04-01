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

/// 🎯 Выбранная пара профильных предметов (напр. 'Математика + Физика')
final selectedSubjectPairProvider = StateProvider<String?>((ref) => null);

/// 🎯 Выбранная специальность (ГОП)
final selectedSpecialtyProvider = StateProvider<EntSpecialty?>((ref) => null);

final universitiesProvider = FutureProvider<List<University>>((ref) async {
  final service = UniversityService();
  return await service.getAllUniversities();
});

/// 👤 Провайдер текущего пользователя из AuthService (реактивный)
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final auth = AuthService();
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

// ═══════════════════════════════════════════
// 🔄 Маппинг String → EntSubjectPair
// ═══════════════════════════════════════════

/// Конвертирует пару предметов пользователя в enum EntSubjectPair
EntSubjectPair? parseSubjectPair(String? subject1, String? subject2) {
  if (subject1 == null) return null;
  final s1 = subject1.toLowerCase();
  final s2 = (subject2 ?? '').toLowerCase();

  if (s1.contains('математ') && s2.contains('физик')) {
    return EntSubjectPair.mathPhysics;
  }
  if (s1.contains('математ') && s2.contains('информат')) {
    return EntSubjectPair.mathInformatics;
  }
  if (s1.contains('математ') && s2.contains('географ')) {
    return EntSubjectPair.mathGeography;
  }
  if (s1.contains('биолог') && s2.contains('хими')) {
    return EntSubjectPair.bioChemistry;
  }
  if (s1.contains('биолог') && s2.contains('географ')) {
    return EntSubjectPair.bioGeography;
  }
  if (s1.contains('географ') && s2.contains('истори')) {
    return EntSubjectPair.geographyHistory;
  }
  if (s1.contains('истори') && s2.contains('право')) {
    return EntSubjectPair.historyLaw;
  }
  if (s1.contains('язык') || s1.contains('литератур')) {
    return EntSubjectPair.languageLiterature;
  }
  if (s1.contains('творчес') || s1.contains('рисов')) {
    return EntSubjectPair.creativeExams;
  }
  return EntSubjectPair.other;
}

/// 🎯 Провайдер вычисленных шансов (АСИНХРОННЫЙ)
/// Автоматически пересчитывает при изменении входных данных
final computedGrantResultsProvider =
    FutureProvider.family<List<GrantResultItem>, EntSpecialty?>(
        (ref, specialty) async {
  final universities = await ref.watch(universitiesProvider.future);
  final user = AuthService().currentUser.value;
  final entScore = ref.watch(untScoreProvider);

  if (universities.isEmpty) return [];

  // ⚡ Даем Flutter время завершить анимацию навигации
  await Future.delayed(const Duration(milliseconds: 400));

  final chanceService = GrantChanceService();
  final List<GrantResultItem> results = [];

  // Маппим пару предметов пользователя
  final EntSubjectPair? subjectPair = parseSubjectPair(
    user?.entSubject1,
    user?.entSubject2,
  );

  for (int i = 0; i < universities.length; i++) {
    final uni = universities[i];

    // Периодически отдаем ресурсы главному изоляту
    if (i > 0 && i % 15 == 0) {
      await Future.delayed(Duration.zero);
    }

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
        hasGrants: uni.hasGrants,
        hasMilitaryDepartment: uni.hasMilitaryDepartment,
        specialExamPassed: user?.specialExamPassed ?? false,
        subjectPair: subjectPair,
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
        hasGrants: uni.hasGrants,
        hasMilitaryDepartment: uni.hasMilitaryDepartment,
        specialExamPassed: user?.specialExamPassed ?? false,
        isRural: user?.isRural ?? false,
        subjectPair: subjectPair,
      );
    }
    results.add(GrantResultItem(university: uni, chanceResult: chance));
  }

  // Сортировка по убыванию шанса
  results.sort((a, b) =>
      b.chanceResult.chancePercent.compareTo(a.chanceResult.chancePercent));

  return results;
});
