/// СВД — Система Вычисления Шансов на Грант
/// Использует верифицированные данные МОН РК 2026 года.
///
/// Источники:
/// - gov.kz (приказ МОН РК)
/// - nur.kz, newtimes.kz (сводки)
///
/// Макс. балл ЕНТ: 140 (120 заданий)
/// Основное ЕНТ: 16 мая — 5 июля 2026
/// Подача на грант: 13-20 июля 2026
/// Результаты: до 10 августа 2026
class GrantChanceService {
  // Singleton
  static final GrantChanceService _instance = GrantChanceService._internal();
  factory GrantChanceService() => _instance;
  GrantChanceService._internal();

  // ═══════════════════════════════════════════
  //  ВЕРИФИЦИРОВАННЫЕ ДАННЫЕ 2026
  // ═══════════════════════════════════════════

  /// Максимальный балл ЕНТ 2026
  static const int maxEntScore = 140;

  /// Минимальные пороговые баллы для участия в конкурсе на грант
  static const int thresholdNationalUni = 65;
  static const int thresholdRegularUni = 50;

  /// Пороги по областям образования
  static const int thresholdPedagogy = 75;
  static const int thresholdLaw = 75;
  static const int thresholdMedicine = 70;
  static const int thresholdAgriculture = 60;
  static const int thresholdVeterinary = 60;

  /// Категории специальностей → порог
  static const Map<MajorCategory, int> categoryThresholds = {
    MajorCategory.it: 50, // общий порог
    MajorCategory.engineering: 50,
    MajorCategory.business: 50,
    MajorCategory.pedagogy: 75,
    MajorCategory.law: 75,
    MajorCategory.medicine: 70,
    MajorCategory.agriculture: 60,
    MajorCategory.arts: 50,
    MajorCategory.sciences: 50,
    MajorCategory.other: 50,
  };

  /// Национальные вузы (повышенный порог = 65)
  /// ID-шки соответствуют sampleUniversities в lib/data/universities.dart
  static const Set<String> nationalUniversities = {
    '1', // Назарбаев Университеті
    '2', // Astana IT University
    '3', // ЕНУ Гумилева
    '4', // Әл-Фараби ҚазҰУ
    '5', // Сатбаев Университеті
    '6', // Абай ҚазҰПУ
    '7', // KBTU
    '11', // Әуезов университеті (региональный ирі ЖОО)
  };

  // ═══════════════════════════════════════════
  //  РАСЧЁТ ШАНСОВ
  // ═══════════════════════════════════════════

  /// Рассчитать шанс на грант
  GrantChanceResult calculate({
    required int? entScore,
    required String universityId,
    MajorCategory majorCategory = MajorCategory.other,
    double? gpa,
    double? ieltsScore,
    List<String> achievements = const [],
    int? mathScore,
    String? userCity,
    String? universityCity,
  }) {
    // Если нет балла ЕНТ — не можем рассчитать
    if (entScore == null || entScore <= 0) {
      return GrantChanceResult(
        chancePercent: 0,
        riskLevel: RiskLevel.unknown,
        verdict: 'Укажите балл ЕНТ для расчёта',
        details: [],
        recommendations: ['Заполните балл ЕНТ в профиле'],
        entThreshold: _getThreshold(universityId, majorCategory),
        dataYear: '2026',
      );
    }

    final int threshold = _getThreshold(universityId, majorCategory);
    final bool isNational = nationalUniversities.contains(universityId);

    final List<String> details = [];
    final List<String> recommendations = [];

    // ── 1. Базовый расчёт (60% веса) ──
    double baseChance;
    if (entScore < threshold) {
      // Ниже порога — шанс очень низкий
      final deficit = threshold - entScore;
      baseChance = (entScore / threshold * 30).clamp(0, 30);
      details.add(
        '❌ ЕНТ $entScore — ниже порога $threshold на $deficit баллов',
      );
      recommendations.add(
        'Повысить ЕНТ минимум до $threshold (сейчас не хватает $deficit баллов)',
      );
    } else {
      // Выше или равен порогу
      final surplus = entScore - threshold;
      baseChance = 40 + (surplus / (maxEntScore - threshold) * 40).clamp(0, 40);
      if (surplus >= 30) {
        details.add(
          '✅ ЕНТ $entScore — превышает порог на $surplus баллов (отлично!)',
        );
      } else if (surplus >= 15) {
        details.add(
          '✅ ЕНТ $entScore — выше порога на $surplus (хороший запас)',
        );
      } else {
        details.add(
          '⚠️ ЕНТ $entScore — выше порога на $surplus (минимальный запас)',
        );
        recommendations.add(
          'Желательно набрать ещё ${15 - surplus} баллов для уверенного прохождения',
        );
      }
    }

    // ── 2. Модификатор для нац. вуза ──
    if (isNational && entScore < thresholdNationalUni) {
      baseChance *= 0.5;
      details.add(
        '⚠️ Для нац. вуза порог $thresholdNationalUni (у вас $entScore)',
      );
      recommendations.add(
        'Для этого вуза необходимо минимум $thresholdNationalUni баллов',
      );
    }

    // ── 3. Бонус GPA (+8%) ──
    double gpaBonus = 0;
    if (gpa != null && gpa > 0) {
      if (gpa >= 3.8) {
        gpaBonus = 8;
        details.add('✅ GPA $gpa — отличный (бонус +${gpaBonus.toInt()}%)');
      } else if (gpa >= 3.5) {
        gpaBonus = 5;
        details.add('✅ GPA $gpa — хороший (бонус +${gpaBonus.toInt()}%)');
      } else if (gpa >= 3.0) {
        gpaBonus = 2;
        details.add('➖ GPA $gpa — средний (бонус +${gpaBonus.toInt()}%)');
      } else {
        details.add('⚠️ GPA $gpa — низкий');
        recommendations.add(
          'Улучшить GPA до 3.5+ для конкурентного преимущества',
        );
      }
    }

    // ── 4. Бонус IELTS (+5%) ──
    double ieltsBonus = 0;
    if (ieltsScore != null && ieltsScore > 0) {
      if (ieltsScore >= 7.0) {
        ieltsBonus = 5;
        details.add(
          '✅ IELTS $ieltsScore — отлично (бонус +${ieltsBonus.toInt()}%)',
        );
      } else if (ieltsScore >= 6.5) {
        ieltsBonus = 3;
        details.add(
          '✅ IELTS $ieltsScore — хорошо (бонус +${ieltsBonus.toInt()}%)',
        );
      } else if (ieltsScore >= 5.5) {
        ieltsBonus = 1;
        details.add('➖ IELTS $ieltsScore — базовый');
      } else {
        details.add('⚠️ IELTS $ieltsScore — ниже минимума для многих программ');
        recommendations.add(
          'Подтянуть IELTS до 6.0+ для расширения возможностей',
        );
      }
    }

    // ── 5. Бонус достижений (до +15%) ──
    double achievementBonus = 0;
    if (achievements.isNotEmpty) {
      for (final ach in achievements) {
        final lowerAch = ach.toLowerCase();
        if (lowerAch.contains('олимпиад') ||
            lowerAch.contains('olympiad') ||
            lowerAch.contains('алтын белгі') ||
            lowerAch.contains('altyn belgi')) {
          achievementBonus += 5;
          details.add('✅ Победитель олимпиады / Алтын белгі (+5%)');
        } else if (lowerAch.contains('волонтер') ||
            lowerAch.contains('volunteering')) {
          achievementBonus += 3;
          details.add('✅ Волонтёрская деятельность (+3%)');
        } else if (lowerAch.contains('спорт') ||
            lowerAch.contains('sport') ||
            lowerAch.contains('соревнован')) {
          achievementBonus += 3;
          details.add('✅ Спортивные достижения (+3%)');
        } else {
          achievementBonus += 2;
        }
      }

      achievementBonus = achievementBonus.clamp(0, 15);

      if (achievementBonus > 0 &&
          !details.any(
            (d) =>
                d.contains('олимпиад') ||
                d.contains('Волонтёрская') ||
                d.contains('Спортивные'),
          )) {
        details.add(
          '✅ Учтены профильные достижения (+${achievementBonus.toInt()}%)',
        );
      }
    } else {
      recommendations.add(
        'Добавьте достижения (олимпиады, волонтёрство, спорт) для повышения шансов',
      );
    }

    // ── 6. Региональный модификатор (Квоты) ──
    double regionModifier = 0;
    if (userCity != null && userCity.isNotEmpty) {
      final String lowerCity = userCity.toLowerCase();
      // Проверка на сельскую местность по ключевым словам
      final bool isRural =
          lowerCity.contains('ауыл') ||
          lowerCity.contains('село') ||
          lowerCity.contains('район') ||
          lowerCity.contains('а. ') ||
          lowerCity.contains('пос.');
      if (isRural) {
        regionModifier = 5;
        details.add('✅ Применена сельская квота (+5%)');
      } else if (universityCity != null &&
          universityCity.isNotEmpty &&
          lowerCity != universityCity.toLowerCase()) {
        // Упоминание о мобильности, но не дает прямого % к шансам
        details.add(
          'ℹ️ Иногородний студент (возможны целевые квоты или Серпін)',
        );
      }
    }

    // ── Итого ──
    final double totalChance =
        (baseChance + gpaBonus + ieltsBonus + achievementBonus + regionModifier)
            .clamp(0, 98);
    final int chancePercent = totalChance.round();

    // Определение уровня риска
    final RiskLevel riskLevel;
    final String verdict;

    if (entScore < threshold) {
      riskLevel = RiskLevel.critical;
      verdict = 'Балл ЕНТ ниже порога. Грант маловероятен без повышения балла.';
    } else if (chancePercent >= 75) {
      riskLevel = RiskLevel.low;
      verdict = 'Отличные шансы на грант! Продолжайте подготовку.';
    } else if (chancePercent >= 50) {
      riskLevel = RiskLevel.medium;
      verdict = 'Хорошие шансы. Подтяните слабые стороны для уверенности.';
    } else if (chancePercent >= 30) {
      riskLevel = RiskLevel.high;
      verdict =
          'Шансы есть, но конкуренция высокая. Усиленная подготовка нужна.';
    } else {
      riskLevel = RiskLevel.critical;
      verdict =
          'Шансы низкие. Рассмотрите альтернативные вузы или повысьте баллы.';
    }

    return GrantChanceResult(
      chancePercent: chancePercent,
      riskLevel: riskLevel,
      verdict: verdict,
      details: details,
      recommendations: recommendations,
      entThreshold: threshold,
      dataYear: '2026',
    );
  }

  /// Определить порог с учётом категории и вуза
  int _getThreshold(String universityId, MajorCategory category) {
    final bool isNational = nationalUniversities.contains(universityId);

    // Берём порог по категории специальности
    final int categoryThreshold =
        categoryThresholds[category] ?? thresholdRegularUni;

    // Для нац. вузов берём максимум из порогов
    if (isNational) {
      return categoryThreshold > thresholdNationalUni
          ? categoryThreshold
          : thresholdNationalUni;
    }

    return categoryThreshold;
  }

  /// Определить категорию специальности по строке
  MajorCategory detectCategory(String major) {
    final lower = major.toLowerCase();

    if (_matchesAny(lower, [
      'it',
      'информац',
      'информатик',
      'программ',
      'computer',
      'software',
      'кибер',
      'digital',
      'data',
      'вычислит',
      // 🇰🇿 Казахские ключевые слова
      'компьютерлік',
      'бағдарламалық',
      'ақпараттық',
      'жасанды интеллект',
      'киберқауіпсіздік',
      'smart',
      'big data',
    ])) {
      return MajorCategory.it;
    }
    if (_matchesAny(lower, [
      'инженер',
      'engineer',
      'строител',
      'архитект',
      'энерг',
      'механик',
      'электр',
      'нефт',
      'горн',
      // 🇰🇿
      'инженерия',
      'тау-кен',
      'мұнай',
      'робототехника',
      'сәулет',
      'металлургия',
      'құрылыс',
      'көлік',
    ])) {
      return MajorCategory.engineering;
    }
    if (_matchesAny(lower, [
      'бизнес',
      'экономик',
      'финанс',
      'менеджмент',
      'маркетинг',
      'бухгалтер',
      'аудит',
      'business',
      // 🇰🇿
      'қаржы',
      'экономика',
    ])) {
      return MajorCategory.business;
    }
    if (_matchesAny(lower, [
      'педагог',
      'учител',
      'образован',
      'дошкольн',
      'воспит',
      // 🇰🇿
      'педагогика',
      'филология',
      'тарих',
      'шет тілдер',
    ])) {
      return MajorCategory.pedagogy;
    }
    if (_matchesAny(lower, [
      'юрид',
      'прав',
      'law',
      'юриспруд',
      // 🇰🇿
      'заң',
      'құқық',
    ])) {
      return MajorCategory.law;
    }
    if (_matchesAny(lower, [
      'медицин',
      'врач',
      'стоматол',
      'фармацевт',
      'хирург',
      'педиатр',
      'сестрин',
      'здравоохранен',
      // 🇰🇿
      'медицина',
      'фармация',
      'мейірбике',
      'денсаулық',
    ])) {
      return MajorCategory.medicine;
    }
    if (_matchesAny(lower, [
      'сельск',
      'агро',
      'ветерин',
      'зоотехн',
      'агроном',
      'лесн',
    ])) {
      return MajorCategory.agriculture;
    }
    if (_matchesAny(lower, [
      'искусств',
      'дизайн',
      'музык',
      'театр',
      'кино',
      'хореограф',
      // 🇰🇿
      'өнер',
    ])) {
      return MajorCategory.arts;
    }
    if (_matchesAny(lower, [
      'математик',
      'физик',
      'химия',
      'биолог',
      'географ',
      'геолог',
      // 🇰🇿
      'математика',
      'физика',
      'биология',
      'табиғат',
    ])) {
      return MajorCategory.sciences;
    }

    return MajorCategory.other;
  }

  bool _matchesAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }
}

// ═══════════════════════════════════════════
//  МОДЕЛИ
// ═══════════════════════════════════════════

/// Результат расчёта СВД
class GrantChanceResult {
  final int chancePercent;
  final RiskLevel riskLevel;
  final String verdict;
  final List<String> details;
  final List<String> recommendations;
  final int entThreshold;
  final String dataYear;

  const GrantChanceResult({
    required this.chancePercent,
    required this.riskLevel,
    required this.verdict,
    required this.details,
    required this.recommendations,
    required this.entThreshold,
    required this.dataYear,
  });

  /// Конвертировать в JSON для передачи AI
  Map<String, dynamic> toJson() {
    return {
      'chancePercent': chancePercent,
      'riskLevel': riskLevel.name,
      'verdict': verdict,
      'details': details,
      'recommendations': recommendations,
      'entThreshold': entThreshold,
      'dataYear': dataYear,
    };
  }
}

/// Уровень риска
enum RiskLevel {
  low, // < 25% риск (> 75% шанс)
  medium, // 25-50% риск
  high, // 50-70% риск
  critical, // > 70% риск
  unknown, // данных недостаточно
}

/// Категория специальности
enum MajorCategory {
  it,
  engineering,
  business,
  pedagogy,
  law,
  medicine,
  agriculture,
  arts,
  sciences,
  other,
}

/// Расширение для отображения
extension RiskLevelExtension on RiskLevel {
  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return 'Низкий';
      case RiskLevel.medium:
        return 'Средний';
      case RiskLevel.high:
        return 'Высокий';
      case RiskLevel.critical:
        return 'Критический';
      case RiskLevel.unknown:
        return 'Не определён';
    }
  }

  String get emoji {
    switch (this) {
      case RiskLevel.low:
        return '🟢';
      case RiskLevel.medium:
        return '🟡';
      case RiskLevel.high:
        return '🟠';
      case RiskLevel.critical:
        return '🔴';
      case RiskLevel.unknown:
        return '⚪';
    }
  }
}

extension MajorCategoryExtension on MajorCategory {
  String get displayName {
    switch (this) {
      case MajorCategory.it:
        return 'IT и цифровые технологии';
      case MajorCategory.engineering:
        return 'Инженерия';
      case MajorCategory.business:
        return 'Бизнес и экономика';
      case MajorCategory.pedagogy:
        return 'Педагогика';
      case MajorCategory.law:
        return 'Право';
      case MajorCategory.medicine:
        return 'Медицина';
      case MajorCategory.agriculture:
        return 'Сельское хозяйство';
      case MajorCategory.arts:
        return 'Искусство и дизайн';
      case MajorCategory.sciences:
        return 'Естественные науки';
      case MajorCategory.other:
        return 'Другое';
    }
  }
}
