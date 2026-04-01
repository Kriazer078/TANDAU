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
library;

// ═══════════════════════════════════════════
//  ENUMS & MODELS
// ═══════════════════════════════════════════

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

/// Официальные профильные комбинации ЕНТ (МОН РК)
enum EntSubjectPair {
  mathPhysics,
  mathInformatics,
  mathGeography,
  bioChemistry,
  bioGeography,
  geographyHistory,
  historyLaw,
  languageLiterature,
  creativeExams, // Творческий (Искусство/Архитектура)
  other,
}

/// Социальные квоты МОН РК
enum SocialQuota {
  none,
  rural, // Сельская (35%)
  orphan, // Сироты (1%)
  disability, // Инвалидность 1-2 группа (1%)
  largeFamily, // Многодетные (5%)
  singleParent, // Неполная семья (1%)
  disabledChildFamily, // Воспитывающие ребёнка-инвалида (1%)
}

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

// ═══════════════════════════════════════════
//  EXTENSIONS
// ═══════════════════════════════════════════

extension RiskLevelExtension on RiskLevel {
  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return 'Высокие шансы (Низкий риск)';
      case RiskLevel.medium:
        return 'Средние шансы';
      case RiskLevel.high:
        return 'Слабые шансы (Высокий риск)';
      case RiskLevel.critical:
        return 'Критический риск';
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

extension EntSubjectPairExtension on EntSubjectPair {
  String get displayName {
    switch (this) {
      case EntSubjectPair.mathPhysics:
        return 'Математика + Физика';
      case EntSubjectPair.mathInformatics:
        return 'Математика + Информатика';
      case EntSubjectPair.mathGeography:
        return 'Математика + География';
      case EntSubjectPair.bioChemistry:
        return 'Биология + Химия';
      case EntSubjectPair.bioGeography:
        return 'Биология + География';
      case EntSubjectPair.geographyHistory:
        return 'География + Всемирная история';
      case EntSubjectPair.historyLaw:
        return 'Всемирная история + Основы права';
      case EntSubjectPair.languageLiterature:
        return 'Каз/Рус язык + Литература';
      case EntSubjectPair.creativeExams:
        return 'Творческие экзамены';
      case EntSubjectPair.other:
        return 'Другая комбинация';
    }
  }
}

// ═══════════════════════════════════════════
//  СЕРВИС
// ═══════════════════════════════════════════

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

  /// Пороги по областям образования (МОН РК)
  static const int thresholdPedagogy = 75;
  static const int thresholdLaw = 75;
  static const int thresholdMedicine = 70;
  static const int thresholdAgriculture = 60;
  static const int thresholdVeterinary = 60;

  /// Минимальный балл по КАЖДОМУ предмету ЕНТ (правило МОН РК)
  static const int minPerSubjectScore = 5;

  /// Категории специальностей → порог
  static const Map<MajorCategory, int> categoryThresholds = {
    MajorCategory.it: 50,
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
  static const Set<String> nationalUniversities = {
    'uni_001', // Назарбаев Университет
    'uni_012', // Astana IT University (AITU)
    'uni_003', // ЕНУ им. Гумилева
    'uni_002', // КазНУ им. Аль-Фараби
    'uni_006', // Сатбаев Университет (КазНИТУ)
    'uni_013', // КазНПУ им. Абая
    'uni_004', // КБТУ
    'uni_023', // ЮКУ им. Ауэзова
  };

  /// Вузы с собственным приёмом (не через ЕНТ)
  static const Set<String> separateAdmissionUniversities = {
    'uni_001', // Назарбаев Университет
  };

  /// Допустимые комбинации предметов ЕНТ для каждой категории (ГОП)
  static const Map<MajorCategory, Set<EntSubjectPair>>
      allowedSubjectPairs = {
    MajorCategory.it: {
      EntSubjectPair.mathPhysics,
      EntSubjectPair.mathInformatics,
    },
    MajorCategory.engineering: {
      EntSubjectPair.mathPhysics,
      EntSubjectPair.mathInformatics,
      EntSubjectPair.mathGeography,
    },
    MajorCategory.business: {
      EntSubjectPair.mathGeography,
      EntSubjectPair.geographyHistory,
    },
    MajorCategory.pedagogy: {
      EntSubjectPair.mathPhysics,
      EntSubjectPair.mathInformatics,
      EntSubjectPair.bioChemistry,
      EntSubjectPair.bioGeography,
      EntSubjectPair.geographyHistory,
      EntSubjectPair.historyLaw,
      EntSubjectPair.languageLiterature,
    },
    MajorCategory.law: {
      EntSubjectPair.historyLaw,
    },
    MajorCategory.medicine: {
      EntSubjectPair.bioChemistry,
    },
    MajorCategory.agriculture: {
      EntSubjectPair.bioChemistry,
      EntSubjectPair.bioGeography,
      EntSubjectPair.mathPhysics,
    },
    MajorCategory.arts: {
      EntSubjectPair.creativeExams,
    },
    MajorCategory.sciences: {
      EntSubjectPair.mathPhysics,
      EntSubjectPair.bioChemistry,
      EntSubjectPair.bioGeography,
      EntSubjectPair.mathGeography,
    },
    MajorCategory.other: {
      EntSubjectPair.other,
      EntSubjectPair.mathPhysics,
      EntSubjectPair.mathInformatics,
      EntSubjectPair.mathGeography,
      EntSubjectPair.bioChemistry,
      EntSubjectPair.bioGeography,
      EntSubjectPair.geographyHistory,
      EntSubjectPair.historyLaw,
      EntSubjectPair.languageLiterature,
      EntSubjectPair.creativeExams,
    },
  };

  /// Категории, требующие специальный экзамен (помимо ЕНТ)
  static const Set<MajorCategory> categoriesRequiringSpecialExam = {
    MajorCategory.medicine, // медико-биологический
    MajorCategory.pedagogy, // психометрический
    MajorCategory.arts, // творческий экзамен
  };

  // ═══════════════════════════════════════════
  //  ВАЛИДАЦИЯ КОМБИНАЦИИ ПРЕДМЕТОВ
  // ═══════════════════════════════════════════

  /// Проверка, подходит ли выбранная пара предметов к ГОП.
  /// Возвращает `null` если всё ОК, или строку с ошибкой.
  String? validateSubjectPair(
    MajorCategory category,
    EntSubjectPair pair,
  ) {
    final Set<EntSubjectPair>? allowed = allowedSubjectPairs[category];
    if (allowed == null) return null; // нет ограничений

    if (!allowed.contains(pair)) {
      final String allowedNames =
          allowed.map((e) => e.displayName).join(', ');
      return 'Для "${category.displayName}" допустимы только: $allowedNames. '
          'Выбрано: ${pair.displayName}. Подача документов невозможна.';
    }
    return null;
  }

  // ═══════════════════════════════════════════
  //  РАСЧЁТ ШАНСОВ (основной)
  // ═══════════════════════════════════════════

  /// Рассчитать шанс на грант
  GrantChanceResult calculate({
    required int? entScore,
    required String universityId,
    MajorCategory majorCategory = MajorCategory.other,
    int universityPassingScore = 0,
    double? gpa,
    double? ieltsScore,
    List<String> achievements = const [],
    int? mathScore,
    String? userCity,
    String? universityCity,
    // 🔥 Новые параметры из плана
    EntSubjectPair? subjectPair,
    bool hasGrants = true,
    bool hasMilitaryDepartment = true,
    bool specialExamPassed = false,
    bool isRural = false,
    List<int>? perSubjectScores,
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

    // 🏛️ Вузы с собственным приёмом (не через ЕНТ)
    if (separateAdmissionUniversities.contains(universityId)) {
      return GrantChanceResult(
        chancePercent: 0,
        riskLevel: RiskLevel.unknown,
        verdict: 'Этот вуз проводит собственный конкурс (не через ЕНТ)',
        details: [
          '🏛️ Назарбаев Университет принимает по собственным экзаменам',
          'ℹ️ Балл ЕНТ не используется для поступления в этот вуз',
          '📋 Подайте заявку напрямую через сайт вуза',
        ],
        recommendations: [
          'Посетите nu.edu.kz для информации о приёме',
          'Рассмотрите другие национальные вузы для грантового конкурса',
        ],
        entThreshold: 0,
        dataYear: '2026',
      );
    }

    // 🔥 Проверка: у вуза нет государственных грантов
    if (!hasGrants) {
      return GrantChanceResult(
        chancePercent: 0,
        riskLevel: RiskLevel.unknown,
        verdict:
            'Данный вуз не участвует в конкурсе на государственные гранты',
        details: [
          '🚫 Этот вуз не имеет лицензии на распределение гос. грантов',
          'ℹ️ Обучение возможно только на платной основе',
        ],
        recommendations: [
          'Рассмотрите вузы, участвующие в грантовом конкурсе МОН РК',
          'Уточните стоимость обучения на сайте вуза',
        ],
        entThreshold: 0,
        dataYear: '2026',
      );
    }

    // 🔥 Проверка комбинации предметов ЕНТ
    if (subjectPair != null) {
      final String? pairError =
          validateSubjectPair(majorCategory, subjectPair);
      if (pairError != null) {
        return GrantChanceResult(
          chancePercent: 0,
          riskLevel: RiskLevel.critical,
          verdict: 'Неверная комбинация предметов ЕНТ',
          details: ['❌ $pairError'],
          recommendations: [
            'Выберите допустимую комбинацию предметов для данной '
                'специальности',
          ],
          entThreshold: _getThreshold(universityId, majorCategory),
          dataYear: '2026',
        );
      }
    }

    // 🔥 Проверка минимума по каждому предмету (не менее 5 баллов)
    if (perSubjectScores != null && perSubjectScores.isNotEmpty) {
      for (int i = 0; i < perSubjectScores.length; i++) {
        if (perSubjectScores[i] < minPerSubjectScore) {
          return GrantChanceResult(
            chancePercent: 0,
            riskLevel: RiskLevel.critical,
            verdict: 'Один из предметов ЕНТ ниже минимума ($minPerSubjectScore)',
            details: [
              '❌ Балл по предмету ${i + 1}: ${perSubjectScores[i]}. '
                  'Минимум — $minPerSubjectScore по каждому предмету.',
              '⛔ По правилам МОН РК, при балле ниже $minPerSubjectScore '
                  'по любому предмету результат ЕНТ аннулируется.',
            ],
            recommendations: [
              'Необходимо набрать минимум $minPerSubjectScore баллов '
                  'по каждому предмету ЕНТ',
            ],
            entThreshold: _getThreshold(universityId, majorCategory),
            dataYear: '2026',
          );
        }
      }
    }

    // 🔥 Проверка специального экзамена (медицина, педагогика, творчество)
    if (categoriesRequiringSpecialExam.contains(majorCategory) &&
        !specialExamPassed) {
      final String examName;
      switch (majorCategory) {
        case MajorCategory.medicine:
          examName = 'медико-биологический';
        case MajorCategory.pedagogy:
          examName = 'психометрический';
        case MajorCategory.arts:
          examName = 'творческий';
        default:
          examName = 'специальный';
      }
      return GrantChanceResult(
        chancePercent: 0,
        riskLevel: RiskLevel.critical,
        verdict: 'Не сдан обязательный $examName экзамен',
        details: [
          '❌ Для "${majorCategory.displayName}" обязателен $examName экзамен',
          '⛔ Без сдачи этого экзамена подача документов невозможна',
        ],
        recommendations: [
          'Зарегистрируйтесь и сдайте $examName экзамен',
        ],
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

    final int targetScore =
        universityPassingScore > 0 ? universityPassingScore : threshold;

    if (entScore < threshold) {
      baseChance = 0;
      details.add(
        '❌ ЕНТ $entScore — ниже порога ($threshold). '
        'Грантқа қатысу мүмкін емес.',
      );
      final int deficit = threshold - entScore;
      recommendations.add(
        'Шекті баллдан өту үшін кемінде $deficit балл қосу керек.',
      );
    } else if (entScore < targetScore) {
      final int deficit = targetScore - entScore;
      final double ratio = entScore / targetScore;
      final double nonLinearRatio = ratio * ratio * ratio * ratio * ratio;
      baseChance = (nonLinearRatio * 35).clamp(0, 35);
      details.add(
        '⚠️ ЕНТ $entScore — порогтан жоғары, бірақ орташа ұпайдан '
        'төмен ($targetScore).',
      );
      recommendations.add(
        'Грантқа түсу үшін шамамен $deficit балл жетіспейді.',
      );
    } else {
      final int surplus = entScore - targetScore;
      final int maxPossibleSurplus =
          (maxEntScore - targetScore).clamp(1, 140);
      baseChance =
          40 + (surplus / maxPossibleSurplus * 45).clamp(0.0, 45.0);

      if (surplus >= 20) {
        details.add(
          '✅ ЕНТ $entScore — орташа ұпайдан жоғары ($targetScore). '
          'Грантқа түсу мүмкіндігі өте жоғары!',
        );
      } else if (surplus >= 5) {
        details.add(
          '✅ ЕНТ $entScore — орташа ұпайдан сәл жоғары ($targetScore).',
        );
      } else {
        details.add(
          '⚠️ ЕНТ $entScore — орташа ұпаймен ($targetScore) бірдей. '
          'Конкуренцияға байланысты.',
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
        details.add('✅ GPA $gpa — отличный (+${gpaBonus.toInt()}%)');
      } else if (gpa >= 3.5) {
        gpaBonus = 5;
        details.add('✅ GPA $gpa — хороший (+${gpaBonus.toInt()}%)');
      } else if (gpa >= 3.0) {
        gpaBonus = 2;
        details.add('➖ GPA $gpa — средний (+${gpaBonus.toInt()}%)');
      } else {
        details.add('⚠️ GPA $gpa — низкий');
        recommendations.add('Улучшить GPA до 3.5+ для преимущества');
      }
    }

    // ── 4. Бонус IELTS (+5%) ──
    double ieltsBonus = 0;
    if (ieltsScore != null && ieltsScore > 0) {
      if (ieltsScore >= 7.0) {
        ieltsBonus = 5;
        details.add('✅ IELTS $ieltsScore — отлично (+${ieltsBonus.toInt()}%)');
      } else if (ieltsScore >= 6.5) {
        ieltsBonus = 3;
        details.add('✅ IELTS $ieltsScore — хорошо (+${ieltsBonus.toInt()}%)');
      } else if (ieltsScore >= 5.5) {
        ieltsBonus = 1;
        details.add('➖ IELTS $ieltsScore — базовый');
      } else {
        details.add('⚠️ IELTS $ieltsScore — ниже минимума');
        recommendations.add('Подтянуть IELTS до 6.0+');
      }
    }

    // ── 5. Бонус достижений (до +15%) ──
    double achievementBonus = 0;
    if (achievements.isNotEmpty) {
      for (final ach in achievements) {
        final String lowerAch = ach.toLowerCase();
        if (lowerAch.contains('олимпиад') ||
            lowerAch.contains('olympiad') ||
            lowerAch.contains('алтын белгі') ||
            lowerAch.contains('altyn belgi')) {
          achievementBonus += 5;
          details.add('✅ Олимпиада / Алтын белгі (+5%)');
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
    } else {
      recommendations.add(
        'Добавьте достижения (олимпиады, волонтёрство, спорт)',
      );
    }

    // ── 6. Региональный модификатор ──
    double regionModifier = 0;
    if (isRural) {
      regionModifier = 5;
      details.add('✅ Сельская квота (+5%)');
    } else if (userCity != null && userCity.isNotEmpty) {
      final String lowerCity = userCity.toLowerCase();
      final bool cityIsRural = lowerCity.contains('ауыл') ||
          lowerCity.contains('село') ||
          lowerCity.contains('район') ||
          lowerCity.contains('а. ') ||
          lowerCity.contains('пос.');
      if (cityIsRural) {
        regionModifier = 5;
        details.add('✅ Сельская квота (+5%)');
      } else if (universityCity != null &&
          universityCity.isNotEmpty &&
          lowerCity != universityCity.toLowerCase()) {
        details.add('ℹ️ Иногородний студент (возможны целевые квоты)');
      }
    }

    // 🔥 Творческие специальности — отдельная формула
    if (majorCategory == MajorCategory.arts &&
        subjectPair == EntSubjectPair.creativeExams) {
      details.add(
        'ℹ️ Для творческих специальностей ЕНТ включает только '
        'Историю Казахстана и Грамотность чтения + 2 творческих экзамена',
      );
      // Творческие: базовый шанс ограничен субъективностью экзамена
      baseChance = (baseChance * 0.85).clamp(0, 75);
    }

    // ── Итого ──
    double totalChance = 0.0;
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

    // 🔥 Предупреждение о военной кафедре
    if (!hasMilitaryDepartment) {
      recommendations.add(
        '⚠️ В данном вузе отсутствует военная кафедра. '
        'Учитывайте это при выборе.',
      );
    }

    // Определение уровня риска
    final RiskLevel riskLevel;
    final String verdict;

    if (entScore < threshold) {
      riskLevel = RiskLevel.critical;
      verdict = 'Балл ЕНТ ниже порога. Грант невозможен без повышения балла.';
    } else if (chancePercent >= 75) {
      riskLevel = RiskLevel.low;
      verdict = 'Отличные шансы на грант! Продолжайте подготовку.';
    } else if (chancePercent >= 50) {
      riskLevel = RiskLevel.medium;
      verdict = 'Хорошие шансы. Подтяните слабые стороны.';
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
    final int categoryThreshold =
        categoryThresholds[category] ?? thresholdRegularUni;

    if (isNational) {
      return categoryThreshold > thresholdNationalUni
          ? categoryThreshold
          : thresholdNationalUni;
    }

    return categoryThreshold;
  }

  /// Определить категорию специальности по строке
  MajorCategory detectCategory(String major) {
    final String lower = major.toLowerCase();

    if (_matchesAny(lower, [
      'it', 'информац', 'информатик', 'программ', 'computer',
      'software', 'кибер', 'digital', 'data', 'вычислит',
      'компьютерлік', 'бағдарламалық', 'ақпараттық',
      'жасанды интеллект', 'киберқауіпсіздік', 'smart', 'big data',
    ])) {
      return MajorCategory.it;
    }
    if (_matchesAny(lower, [
      'инженер', 'engineer', 'строител', 'архитект', 'энерг',
      'механик', 'электр', 'нефт', 'горн', 'инженерия',
      'тау-кен', 'мұнай', 'робототехника', 'сәулет',
      'металлургия', 'құрылыс', 'көлік',
    ])) {
      return MajorCategory.engineering;
    }
    if (_matchesAny(lower, [
      'бизнес', 'экономик', 'финанс', 'менеджмент', 'маркетинг',
      'бухгалтер', 'аудит', 'business', 'қаржы', 'экономика',
    ])) {
      return MajorCategory.business;
    }
    if (_matchesAny(lower, [
      'педагог', 'учител', 'образован', 'дошкольн', 'воспит',
      'педагогика', 'филология', 'тарих', 'шет тілдер',
    ])) {
      return MajorCategory.pedagogy;
    }
    if (_matchesAny(lower, [
      'юрид', 'прав', 'law', 'юриспруд', 'заң', 'құқық',
    ])) {
      return MajorCategory.law;
    }
    if (_matchesAny(lower, [
      'медицин', 'врач', 'стоматол', 'фармацевт', 'хирург',
      'педиатр', 'сестрин', 'здравоохранен', 'медицина',
      'фармация', 'мейірбике', 'денсаулық',
    ])) {
      return MajorCategory.medicine;
    }
    if (_matchesAny(lower, [
      'сельск', 'агро', 'ветерин', 'зоотехн', 'агроном', 'лесн',
    ])) {
      return MajorCategory.agriculture;
    }
    if (_matchesAny(lower, [
      'искусств', 'дизайн', 'музык', 'театр', 'кино',
      'хореограф', 'өнер',
    ])) {
      return MajorCategory.arts;
    }
    if (_matchesAny(lower, [
      'математик', 'физик', 'химия', 'биолог', 'географ',
      'геолог', 'математика', 'физика', 'биология', 'табиғат',
    ])) {
      return MajorCategory.sciences;
    }

    return MajorCategory.other;
  }

  bool _matchesAny(String text, List<String> keywords) {
    for (final String kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  // ═══════════════════════════════════════════
  //  РАСЧЁТ ПО СПЕЦИАЛЬНОСТИ (ГОП)
  // ═══════════════════════════════════════════

  /// Рассчитать шанс на грант по конкретной специальности (ГОП).
  /// Использует реальные проходные баллы и квоты МОН РК 2025/2026.
  GrantChanceResult calculateBySpecialty({
    required int entScore,
    required int minPassingScore,
    required int grantQuota,
    required String trendName, // 'rising' | 'stable' | 'falling'
    String universityId = '',
    int? universityPassingScore,
    double? gpa,
    double? ieltsScore,
    List<String> achievements = const [],
    bool hasDisability = false,
    bool isOrphan = false,
    bool isRural = false,
    bool isLargeFamily = false,
    // 🔥 Новые параметры
    EntSubjectPair? subjectPair,
    MajorCategory majorCategory = MajorCategory.other,
    bool hasGrants = true,
    bool hasMilitaryDepartment = true,
    bool specialExamPassed = false,
    List<int>? perSubjectScores,
  }) {
    final List<String> details = [];
    final List<String> recommendations = [];

    // 🔥 Проверка лицензии на гранты
    if (!hasGrants) {
      return GrantChanceResult(
        chancePercent: 0,
        riskLevel: RiskLevel.unknown,
        verdict:
            'Данный вуз не участвует в конкурсе на государственные гранты',
        details: [
          '🚫 Этот вуз не имеет лицензии на распределение гос. грантов',
        ],
        recommendations: [
          'Рассмотрите вузы, участвующие в грантовом конкурсе МОН РК',
        ],
        entThreshold: minPassingScore,
        dataYear: '2025/2026',
      );
    }

    // 🔥 Проверка комбинации предметов
    if (subjectPair != null) {
      final String? pairError =
          validateSubjectPair(majorCategory, subjectPair);
      if (pairError != null) {
        return GrantChanceResult(
          chancePercent: 0,
          riskLevel: RiskLevel.critical,
          verdict: 'Неверная комбинация предметов ЕНТ для этой специальности',
          details: ['❌ $pairError'],
          recommendations: [
            'Выберите допустимую комбинацию предметов',
          ],
          entThreshold: minPassingScore,
          dataYear: '2025/2026',
        );
      }
    }

    // 🔥 Проверка минимума по каждому предмету
    if (perSubjectScores != null && perSubjectScores.isNotEmpty) {
      for (int i = 0; i < perSubjectScores.length; i++) {
        if (perSubjectScores[i] < minPerSubjectScore) {
          return GrantChanceResult(
            chancePercent: 0,
            riskLevel: RiskLevel.critical,
            verdict: 'Один из предметов ниже минимума ($minPerSubjectScore)',
            details: [
              '❌ Предмет ${i + 1}: ${perSubjectScores[i]} балл(ов). '
                  'Минимум — $minPerSubjectScore.',
            ],
            recommendations: [
              'Набрать минимум $minPerSubjectScore по каждому предмету',
            ],
            entThreshold: minPassingScore,
            dataYear: '2025/2026',
          );
        }
      }
    }

    // 🔥 Проверка специального экзамена
    if (categoriesRequiringSpecialExam.contains(majorCategory) &&
        !specialExamPassed) {
      final String examName;
      switch (majorCategory) {
        case MajorCategory.medicine:
          examName = 'медико-биологический';
        case MajorCategory.pedagogy:
          examName = 'психометрический';
        case MajorCategory.arts:
          examName = 'творческий';
        default:
          examName = 'специальный';
      }
      return GrantChanceResult(
        chancePercent: 0,
        riskLevel: RiskLevel.critical,
        verdict: 'Не сдан обязательный $examName экзамен',
        details: [
          '❌ Для "${majorCategory.displayName}" необходим $examName экзамен',
        ],
        recommendations: [
          'Зарегистрируйтесь и сдайте $examName экзамен',
        ],
        entThreshold: minPassingScore,
        dataYear: '2025/2026',
      );
    }

    // 1. Проверка порога
    final bool isNational = nationalUniversities.contains(universityId);
    int threshold = isNational
        ? (thresholdNationalUni > 50 ? thresholdNationalUni : 50)
        : thresholdRegularUni;

    // Порог по категории специальности
    final int catThreshold =
        categoryThresholds[majorCategory] ?? thresholdRegularUni;
    if (catThreshold > threshold) {
      threshold = catThreshold;
    }

    if (universityPassingScore != null && universityPassingScore > threshold) {
      threshold = universityPassingScore;
    }

    if (entScore < threshold) {
      details.add(
        '⛔ Балл ЕНТ ($entScore) ниже минимального порога ($threshold)',
      );
      return GrantChanceResult(
        chancePercent: 0,
        riskLevel: RiskLevel.critical,
        verdict: 'Балл ЕНТ ниже проходного порога. Грант невозможен.',
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
        '✅ Балл ($entScore) на $scoreDiff+ выше проходного '
        '($minPassingScore)',
      );
    } else if (scoreDiff >= 8) {
      baseChance = 68;
      details.add(
        '✅ Балл ($entScore) на $scoreDiff выше проходного '
        '($minPassingScore)',
      );
    } else if (scoreDiff >= 3) {
      baseChance = 50;
      details.add(
        '⚠️ Балл ($entScore) чуть выше проходного ($minPassingScore)',
      );
    } else if (scoreDiff >= 0) {
      baseChance = 35;
      details.add(
        '⚠️ Балл ($entScore) на границе с проходным ($minPassingScore)',
      );
    } else {
      // Ниже проходного по ГОП
      baseChance = 10;
      details.add(
        '❌ Балл ($entScore) ниже среднего проходного ($minPassingScore)',
      );
      recommendations.add(
        'Поднимите балл ЕНТ на ${minPassingScore - entScore} для '
        'конкурентного шанса',
      );
    }

    // 3. Модификатор тренда
    if (trendName == 'rising') {
      baseChance -= 5;
      details.add('📈 Конкуренция растёт — шансы чуть ниже');
    } else if (trendName == 'falling') {
      baseChance += 5;
      details.add('📉 Конкуренция снижается — шансы выше');
    }

    // 4. Модификатор квот
    if (grantQuota > 0) {
      if (grantQuota >= 5000) {
        baseChance += 5;
        details.add('📊 Большая квота грантов ($grantQuota мест)');
      } else if (grantQuota <= 500) {
        baseChance -= 5;
        details.add('📊 Малая квота грантов ($grantQuota мест)');
      }
    }

    // 5. Внутренний порог вуза
    if (universityPassingScore != null &&
        universityPassingScore > minPassingScore) {
      final int diff = universityPassingScore - minPassingScore;
      if (diff > 0) {
        final double penalty = (diff * 0.4).clamp(0, 15);
        baseChance -= penalty;
        details.add(
          '🏢 Внутренний порог вуза высокий — повышенная конкуренция',
        );
      }
    }

    // 6. Бонусы за дополнительные показатели
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

    // 7. Квоты (СУСН, сельская, инвалидность, многодетные)
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
    if (isLargeFamily) {
      bonus += 6;
      details.add('👨‍👩‍👧‍👦 Квота для многодетных семей — бонус +6%');
    }

    // 🔥 Предупреждение о военной кафедре
    if (!hasMilitaryDepartment) {
      recommendations.add(
        '⚠️ В данном вузе отсутствует военная кафедра',
      );
    }

    // 8. Итого
    final double totalChance = (baseChance + bonus).clamp(0, 98);
    final int chancePercent = totalChance.round();

    // 9. Вердикт
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
