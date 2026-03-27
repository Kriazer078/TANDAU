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
    int universityPassingScore =
        0, // 🔥 Новое поле для реального проходного балла
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

    // 🔥 NEW: Use targetScore instead of threshold to be more realistic
    final int targetScore =
        universityPassingScore > 0 ? universityPassingScore : threshold;

    if (entScore < threshold) {
      // Ниже строгого МОН порога — шанса нет (по закону нельзя подать)
      final deficit = threshold - entScore;
      baseChance = 0;
      details.add(
        '❌ ЕНТ $entScore — төмен шекті балл ($threshold). Грантқа қатысу мүмкін емес.',
      );
      recommendations.add(
        'Шекті баллдан өту үшін кемінде $deficit балл қосу керек.',
      );
    } else if (entScore < targetScore) {
      // Выше порога МОН, но ниже реального проходного
      final deficit = targetScore - entScore;

      // Делаем штраф нелинейным, чтобы шансы сильнее отличались при нехватке баллов
      final double ratio = entScore / targetScore;
      final double nonLinearRatio =
          ratio * ratio * ratio * ratio * ratio; // x^5 (более крутой штраф)

      // Макс база для тех, кто не дотянул до среднего = 35%
      baseChance = (nonLinearRatio * 35).clamp(0, 35);

      details.add(
        '⚠️ ЕНТ $entScore шекті баллдан өткен, бірақ осы университеттің орташа ұпайынан төмен ($targetScore).',
      );
      recommendations.add(
        'Грантқа түсу үшін шамамен $deficit балл жетіспейді.',
      );
    } else {
      // Выше реального проходного балла вуза
      final surplus = entScore - targetScore;
      // В диапазоне от targetScore до maxEntScore (140)
      final maxPossibleSurplus = (maxEntScore - targetScore).clamp(1, 140);

      // Даем от 40 до 85 шанса, чтобы в сумме могло доходить до ~98%
      baseChance = 40 + (surplus / maxPossibleSurplus * 45).clamp(0, 45);

      if (surplus >= 20) {
        details.add(
          '✅ ЕНТ $entScore — орташа ұпайдан жоғары ($targetScore). Грантқа түсу мүмкіндігі өте жоғары!',
        );
      } else if (surplus >= 5) {
        details.add(
          '✅ ЕНТ $entScore — орташа ұпайдан сәл жоғары ($targetScore). Жақсы мүмкіндік.',
        );
      } else {
        details.add(
          '⚠️ ЕНТ $entScore — орташа ұпаймен ($targetScore) бірдей. Конкуренцияға байланысты.',
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
      final bool isRural = lowerCity.contains('ауыл') ||
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
    double totalChance = 0.0;

    // Если по закону ниже порога — шанс строго 0 (и бонусы не работают)
    // Либо дадим символические 1-2%, чтобы график не был совсем пустым?
    // Оставим 0, чтобы не вводить в заблуждение
    if (entScore < threshold) {
      totalChance = 0;
    } else {
      totalChance = (baseChance +
              gpaBonus +
              ieltsBonus +
              achievementBonus +
              regionModifier)
          .clamp(0, 98);
    }

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

  // ═══════════════════════════════════════════
  //  РАСЧЁТ ПО СПЕЦИАЛЬНОСТИ (ГОП)
  // ═══════════════════════════════════════════

  /// Рассчитать шанс на грант по конкретной специальности (ГОП).
  /// Использует реальные проходные баллы и квоты МОН РК 2025.
  GrantChanceResult calculateBySpecialty({
    required int entScore,
    required int minPassingScore, // Проходной балл по ГОП
    required int grantQuota,      // Кол-во грантов по ГОП
    required String trendName,    // 'rising' | 'stable' | 'falling'
    String universityId = '',
    double? gpa,
    double? ieltsScore,
    List<String> achievements = const [],
    bool hasDisability = false,
    bool isOrphan = false,
    bool isRural = false,
  }) {
    final List<String> details = [];
    final List<String> recommendations = [];

    // 1. Проверка порога
    final bool isNational = nationalUniversities.contains(universityId);
    final int threshold = isNational
        ? (thresholdNationalUni > 50 ? thresholdNationalUni : 50)
        : thresholdRegularUni;

    if (entScore < threshold) {
      details.add(
        '⛔ Балл ЕНТ ($entScore) ниже минимального порога ($threshold)',
      );
      return GrantChanceResult(
        chancePercent: 0,
        riskLevel: RiskLevel.critical,
        verdict: 'Балл ЕНТ ниже порога. Грант невозможен.',
        details: details,
        recommendations: [
          'Поднимите балл ЕНТ минимум до $threshold',
        ],
        entThreshold: threshold,
        dataYear: '2025/2026',
      );
    }

    // 2. Базовый шанс — насколько балл выше проходного
    double baseChance;
    final int scoreDiff = entScore - minPassingScore;

    if (scoreDiff >= 15) {
      baseChance = 85;
      details.add(
        '✅ Балл ($entScore) на $scoreDiff+ выше проходного ($minPassingScore)',
      );
    } else if (scoreDiff >= 8) {
      baseChance = 68;
      details.add(
        '✅ Балл ($entScore) на $scoreDiff выше проходного ($minPassingScore)',
      );
    } else if (scoreDiff >= 3) {
      baseChance = 50;
      details.add(
        '⚠️ Балл ($entScore) чуть выше проходного ($minPassingScore)',
      );
    } else if (scoreDiff >= 0) {
      baseChance = 35;
      details.add(
        '⚠️ Балл ($entScore) на грани проходного ($minPassingScore)',
      );
      recommendations.add(
        'Постарайтесь набрать на 5-10 баллов больше для уверенности',
      );
    } else {
      // Below passing
      baseChance = 12;
      details.add(
        '⛔ Балл ($entScore) ниже проходного ($minPassingScore) на ${-scoreDiff}',
      );
      recommendations.add(
        'Необходимо поднять балл минимум до $minPassingScore',
      );
    }

    // 3. Коррекция по тренду
    if (trendName == 'rising') {
      baseChance -= 5;
      details.add('📈 Конкурс растёт — шанс чуть ниже');
    } else if (trendName == 'falling') {
      baseChance += 5;
      details.add('📉 Конкурс падает — шанс чуть выше');
    }

    // 4. Коррекция по квоте грантов
    if (grantQuota > 5000) {
      baseChance += 5;
      details.add(
        '🎓 Большая квота грантов ($grantQuota мест) — шанс выше',
      );
    } else if (grantQuota < 1000) {
      baseChance -= 5;
      details.add(
        '🎓 Маленькая квота грантов ($grantQuota мест) — высокая конкуренция',
      );
    }

    // 5. Бонусы за дополнительные показатели
    double bonus = 0;

    if (gpa != null && gpa >= 3.5) {
      bonus += 3;
      details.add('📊 GPA $gpa — бонус +3%');
    }

    if (ieltsScore != null && ieltsScore >= 6.0) {
      bonus += 4;
      details.add('🌍 IELTS $ieltsScore — бонус +4%');
    }

    if (achievements.isNotEmpty) {
      final int achievementBonus = (achievements.length * 2).clamp(0, 6);
      bonus += achievementBonus;
      details.add(
        '🏆 ${achievements.length} достижений — бонус +$achievementBonus%',
      );
    }

    // 6. Квоты (СУСН, сельская, инвалидность)
    if (hasDisability) {
      bonus += 12;
      details.add('♿ Квота для лиц с инвалидностью — бонус +12%');
    }
    if (isOrphan) {
      bonus += 10;
      details.add('👤 Квота СУСН (сироты) — бонус +10%');
    }
    if (isRural) {
      bonus += 8;
      details.add('🏡 Сельская квота — бонус +8%');
    }

    // 7. Итого
    final double totalChance = (baseChance + bonus).clamp(0, 98);
    final int chancePercent = totalChance.round();

    // 8. Вердикт
    final RiskLevel riskLevel;
    final String verdict;

    if (chancePercent >= 75) {
      riskLevel = RiskLevel.low;
      verdict = 'Отличные шансы на грант! Продолжайте подготовку.';
    } else if (chancePercent >= 50) {
      riskLevel = RiskLevel.medium;
      verdict = 'Хорошие шансы. Подтяните слабые стороны.';
    } else if (chancePercent >= 30) {
      riskLevel = RiskLevel.high;
      verdict = 'Шансы есть, но конкуренция высокая.';
      recommendations.add('Рассмотрите менее конкурентные специальности');
    } else {
      riskLevel = RiskLevel.critical;
      verdict = 'Шансы низкие. Рассмотрите альтернативы.';
      recommendations.add(
        'Подумайте о смежных специальностях с более низким порогом',
      );
    }

    return GrantChanceResult(
      chancePercent: chancePercent,
      riskLevel: riskLevel,
      verdict: verdict,
      details: details,
      recommendations: recommendations,
      entThreshold: minPassingScore,
      dataYear: '2025/2026',
    );
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
