import '../models/profession.dart';
import '../models/university.dart';
import '../models/fintech_analysis.dart';
import '../models/roi_models.dart';
import 'dart:math';

// ─────────────────────────────────────────
// 📦 Результат расчёта ROI
// ─────────────────────────────────────────

enum RoiRating {
  excellent, // < 12 мес
  good, // 12–24 мес
  average, // 24–48 мес
  poor, // 48+ мес
}

extension RoiRatingExt on RoiRating {
  String get emoji {
    switch (this) {
      case RoiRating.excellent:
        return '✅';
      case RoiRating.good:
        return '👍';
      case RoiRating.average:
        return '⚠️';
      case RoiRating.poor:
        return '🔴';
    }
  }

  String get label {
    switch (this) {
      case RoiRating.excellent:
        return 'Отличный ROI — быстрая окупаемость';
      case RoiRating.good:
        return 'Хороший выбор';
      case RoiRating.average:
        return 'Средняя окупаемость';
      case RoiRating.poor:
        return 'Долгая окупаемость — подумай';
    }
  }
}

class RoiResult {
  /// Общая стоимость обучения (0 при гранте)
  final int totalTuition;

  /// Стартовая зарплата в месяц
  final int monthlySalary;

  /// Месяцев до окупаемости (0 при гранте)
  final int paybackMonths;

  /// Целых лет до окупаемости
  final int paybackYears;

  /// Остаток месяцев после полных лет
  final int remainingMonths;

  /// Количество лет для расчёта прибыли
  final int calculatedYears;

  /// Чистая прибыль за выбранное количество лет работы
  final int calculatedProfit;

  /// Оценка ROI (только для платного)
  final RoiRating rating;

  /// Сколько сэкономит грант (полная стоимость обучения)
  final int grantSavings;

  /// Платное или грант
  final bool isGrant;

  /// Готовность отработать грант 3 года
  final bool willWorkOff;

  /// Является ли долгом (если не готов отработать грант)
  final bool isDebt;

  /// Суммарная стипендия за все годы учебы
  final int totalScholarship;

  /// Престиж-бонус к зарплате (%)
  final double prestigeBonus;

  const RoiResult({
    required this.totalTuition,
    required this.monthlySalary,
    required this.paybackMonths,
    required this.paybackYears,
    required this.remainingMonths,
    required this.calculatedYears,
    required this.calculatedProfit,
    required this.rating,
    required this.grantSavings,
    required this.isGrant,
    required this.totalScholarship,
    this.prestigeBonus = 0,
    this.willWorkOff = true,
    this.isDebt = false,
  });
}

// ─────────────────────────────────────────
// 🧮 Сервис расчёта ROI
// ─────────────────────────────────────────

class RoiCalculatorService {
  // Singleton
  static final RoiCalculatorService _instance =
      RoiCalculatorService._internal();
  factory RoiCalculatorService() => _instance;
  RoiCalculatorService._internal();

  RoiResult calculate({
    required Profession profession,
    required bool isGrant,
    University? university,
    int yearsToCalculate = 10,
    bool willWorkOffGrant = true,
    bool isRuralQuota = false,
    bool isPedagogicalOrMedical = false,
    bool includeLivingCosts = false,
    bool isHonorStudent = false,
    bool worksWhileStudying = false,
  }) {
    // 1. Определение престижности ВУЗа (multiplier)
    double prestigeMultiplier = 1.0;
    if (university != null) {
      final name = university.name.toLowerCase();
      // Топ-вузы РК по востребованности и зарплатам выпускников
      if (name.contains('astu') || // Astana IT
          name.contains('aitu') ||
          name.contains('кбту') || 
          name.contains('kbtu') ||
          name.contains('назарбаев') || 
          name.contains('nazarbayev') ||
          name.contains('satbayev') ||
          name.contains('kiimep') ||
          name.contains('кимеп')) {
        prestigeMultiplier = 1.25; // +25% к старту
      }
    }

    int salary = (profession.startSalary * prestigeMultiplier).round();

    // 2. Расчет стипендии (Stipend)
    int totalScholarship = 0;
    if (isGrant && willWorkOffGrant) {
      double monthlyStipend = 47135; // Базовая (2024)
      if (isPedagogicalOrMedical) {
        monthlyStipend = 75600; // Повышенная для пед/мед
      }
      if (isHonorStudent) {
        monthlyStipend *= 1.15; // +15% за "отлично"
      }
      totalScholarship = (monthlyStipend * 12 * profession.studyYears).round();
    }

    // 3. Доход во время учебы (Student Income)
    int studentIncome = 0;
    if (worksWhileStudying) {
      // Предполагаем работу на полставки (0.5 от Junior salary) на 3 и 4 курсах
      studentIncome = (salary * 0.5 * 12 * 2).round();
    }

    // 4. Специфика отработки
    int initialSalary = salary;
    if (isGrant && willWorkOffGrant) {
       if (isPedagogicalOrMedical) {
         initialSalary = 250000; // Реальный старт в гос. секторе
       } else if (isRuralQuota) {
         initialSalary = (salary * 0.85).round();
       }
    }
    
    final int baseTuitionYear = (university != null && university.maxTuitionValue > 0)
        ? university.maxTuitionValue.toInt()
        : profession.tuitionPerYear;

    int fullTuition = baseTuitionYear * profession.studyYears;
    
    if (includeLivingCosts) {
      final livingCostPerYear = 120000 * 12; // Инфляция учтена 
      fullTuition += (livingCostPerYear * profession.studyYears);
    }
    
    final bool isDebt = isGrant && !willWorkOffGrant;
    // Чистые расходы = Стоимость - Стипендия - Доход во время учебы
    int tuition = (isGrant && willWorkOffGrant) ? fullTuition - (baseTuitionYear * profession.studyYears) : fullTuition;
    tuition = (tuition - totalScholarship - studentIncome);
    if (tuition < 0) tuition = 0;

    // В окупаемость идет 40% 
    final int monthlySavings = (initialSalary * 0.40).round();

    final int paybackMonths =
        (monthlySavings > 0 && tuition > 0) ? (tuition / monthlySavings).ceil() : 0;

    final int paybackYears = paybackMonths ~/ 12;
    final int remainingMonths = paybackMonths % 12;

    // Расчет прибыли с учетом КАРЬЕРНОГО РОСТА
    int profit = 0;
    for (int y = 1; y <= yearsToCalculate; y++) {
      double growthFactor = 1.0;
      if (y > 2) growthFactor = 1.4; // Middle
      if (y > 5) growthFactor = 2.0; // Senior
      
      int currentSalary = (y <= 3 && isGrant && willWorkOffGrant) 
          ? initialSalary 
          : (salary * growthFactor).round();
      
      profit += (currentSalary * 12);
    }
    profit -= tuition;

    final RoiRating rating = _calcRating(paybackMonths, isGrant, willWorkOffGrant);

    return RoiResult(
      totalTuition: tuition,
      monthlySalary: initialSalary,
      paybackMonths: paybackMonths,
      paybackYears: paybackYears,
      remainingMonths: remainingMonths,
      calculatedYears: yearsToCalculate,
      calculatedProfit: profit,
      rating: rating,
      grantSavings: fullTuition, 
      isGrant: isGrant,
      totalScholarship: totalScholarship,
      prestigeBonus: prestigeMultiplier - 1.0,
      willWorkOff: willWorkOffGrant,
      isDebt: isDebt,
    );
  }

  /// 📊 Генерирует данные для графика (проекция капитала по годам)
  List<double> getYearlyData({
    required Profession profession,
    required bool isGrant,
    University? university,
    bool willWorkOffGrant = true,
  }) {
    List<double> data = [0]; // Год 0 (начало)
    
    final result = calculate(
      profession: profession,
      isGrant: isGrant,
      university: university,
      willWorkOffGrant: willWorkOffGrant,
      yearsToCalculate: 10,
    );

    double currentCapital = -result.totalTuition.toDouble();
    data.add(currentCapital);

    // Предположим фазовый рост за 10 лет
    for (int y = 1; y <= 10; y++) {
      double growthFactor = 1.0;
      if (y > 2) growthFactor = 1.4;
      if (y > 5) growthFactor = 2.0;
      
      int yearSalary = (result.monthlySalary * growthFactor * 12).round();
      currentCapital += yearSalary;
      data.add(currentCapital);
    }
    
    return data;
  }

  /// 💎 Продвинутый FinTech анализ образовательной инвестиции
  FinTechAnalysis calculateFinTechPortfolio({
    required Profession profession,
    required University university,
    required bool isGrant,
    double discountRate = 0.14, // Ставка дисконтирования (депозит в РК)
    double inflationRate = 0.10, // Инфляция в РК
    bool willWorkOff = true,
    bool isHonorStudent = false,
  }) {
    // 1. Параметры престижа
    double prestigeMultiplier = 1.0;
    final name = university.name.toLowerCase();
    if (name.contains('astu') || name.contains('aitu') || name.contains('кбту') || 
        name.contains('kbtu') || name.contains('назарбаев') || name.contains('nazarbayev') ||
        name.contains('satbayev') || name.contains('kiimep') || name.contains('кимеп')) {
      prestigeMultiplier = 1.25;
    }

    final int studyYears = profession.studyYears;
    final int workYears = 10;
    final int annualTuition = university.maxTuitionValue.toInt() > 0 
        ? university.maxTuitionValue.toInt() 
        : profession.tuitionPerYear;
    
    // 2. Упущенная выгода (Opportunity Cost)
    double oppCost = 0;
    if (!isGrant) {
      for (int i = 0; i < studyYears; i++) {
        oppCost += annualTuition * pow(1 + discountRate, studyYears - i);
      }
    }
    final int totalInvested = isGrant ? 0 : annualTuition * studyYears;
    final int finalOppCost = (oppCost - totalInvested).round();

    // 3. Расчёт NPV и богатства с учетом КАРЬЕРНОГО РОСТА
    double npvValue = isGrant ? 0 : -totalInvested.toDouble();
    int totalTaxes = 0;
    int lastNetSalary = 0;
    int totalWealth = 0;

    // Добавляем стипендию в "богатство" (как приток денег)
    if (isGrant && willWorkOff) {
      double monthlyStipend = (isHonorStudent ? 47135 * 1.15 : 47135);
      totalWealth += (monthlyStipend * 12 * studyYears).round();
    }

    for (int year = 1; year <= workYears; year++) {
      // Рост зарплаты (фазовый)
      double growthFactor = 1.0;
      if (year > 2) growthFactor = 1.4;
      if (year > 5) growthFactor = 2.0;

      double grossSalaryYearly = (profession.startSalary * prestigeMultiplier * 12 * growthFactor).toDouble();
      
      double taxesYearly = grossSalaryYearly * 0.21;
      double netSalaryYearly = grossSalaryYearly - taxesYearly;
      
      totalTaxes += taxesYearly.round();
      lastNetSalary = (netSalaryYearly / 12).round();
      totalWealth += netSalaryYearly.round();

      npvValue += netSalaryYearly / pow(1 + discountRate, year + studyYears);
    }

    double efficiency = totalInvested > 0 ? ((totalWealth / totalInvested) - 1) / 10 : 1.0;

    return FinTechAnalysis(
      professionName: profession.name,
      universityName: university.name,
      npv: npvValue.round(),
      opportunityCost: finalOppCost,
      monthlyRealIncome: lastNetSalary,
      totalWealthAt10Years: totalWealth - totalInvested,
      investmentReturnRate: efficiency,
      totalTaxesPaid: totalTaxes,
    );
  }

  /// 🔬 FinTech-анализ ROI для нового UI (roi_screen.dart)
  FinTechResult calculateFinTech({
    required Profession profession,
    required University university,
    required bool isGrant,
    required int yearsToCalculate,
    required bool includeLivingCosts,
    required bool isHonorStudent,
    required bool worksWhileStudying,
  }) {
    final int studyYears = profession.studyYears;
    final int tuitionPerYear = profession.tuitionPerYear;
    final int totalTuition = isGrant ? 0 : (tuitionPerYear * studyYears);

    final int livingPerYear = includeLivingCosts ? 1440000 : 0;
    final int totalLiving = livingPerYear * studyYears;
    final int totalInvestment = totalTuition + totalLiving;

    int monthlySalary = profession.startSalary;
    if (isHonorStudent) {
      monthlySalary = (monthlySalary * 1.15).toInt();
    }

    final int studyIncome = worksWhileStudying
        ? ((monthlySalary * 0.3).toInt() * 12 * studyYears)
        : 0;

    final List<double> yearlyBalance = [];
    double cumulativeBalance = -totalInvestment.toDouble() + studyIncome;
    double currentAnnualSalary = monthlySalary * 12.0;
    const double salaryGrowthRate = 0.08;

    for (int year = 0; year < yearsToCalculate; year++) {
      if (year < studyYears) {
        final double yearExpenses =
            (isGrant ? 0.0 : tuitionPerYear.toDouble()) + livingPerYear;
        final double yearIncome =
            worksWhileStudying ? (monthlySalary * 0.3) * 12 : 0;
        cumulativeBalance += yearIncome - yearExpenses;
      } else {
        cumulativeBalance += currentAnnualSalary;
        currentAnnualSalary *= (1 + salaryGrowthRate);
      }
      yearlyBalance.add(cumulativeBalance);
    }

    final double netProfit = cumulativeBalance;
    final double roi =
        totalInvestment > 0 ? (netProfit / totalInvestment) * 100 : 0;

    int paybackYears = 0;
    for (int i = 0; i < yearlyBalance.length; i++) {
      if (yearlyBalance[i] >= 0) {
        paybackYears = i + 1;
        break;
      }
    }
    final String paybackLabel =
        paybackYears > 0 ? '$paybackYears лет' : '>$yearsToCalculate лет';

    final int monthlyFreeCash =
        (currentAnnualSalary / 12).toInt() -
        (includeLivingCosts ? 120000 : 0);

    double score = 0.5;
    if (roi > 300) {
      score = 1.0;
    } else if (roi > 200) {
      score = 0.85;
    } else if (roi > 100) {
      score = 0.7;
    } else if (roi > 50) {
      score = 0.55;
    } else if (roi > 0) {
      score = 0.4;
    } else {
      score = 0.2;
    }

    return FinTechResult(
      score: score,
      paybackLabel: paybackLabel,
      netProfit: netProfit.toInt(),
      roi: roi,
      monthlyFreeCash: monthlyFreeCash,
      yearlyBalance: yearlyBalance,
    );
  }

  /// Список профессий для ROI-калькулятора
  List<Profession> getProfessions() {
    return const [
      Profession(id: 'it', name: 'IT-специалист', nameKz: 'IT маманы', startSalary: 350000, tuitionPerYear: 1200000, studyYears: 4, emoji: '💻'),
      Profession(id: 'doctor', name: 'Врач', nameKz: 'Дәрігер', startSalary: 250000, tuitionPerYear: 1500000, studyYears: 6, emoji: '🩺'),
      Profession(id: 'lawyer', name: 'Юрист', nameKz: 'Заңгер', startSalary: 200000, tuitionPerYear: 1000000, studyYears: 4, emoji: '⚖️'),
      Profession(id: 'engineer', name: 'Инженер', nameKz: 'Инженер', startSalary: 280000, tuitionPerYear: 900000, studyYears: 4, emoji: '🔧'),
      Profession(id: 'economist', name: 'Экономист', nameKz: 'Экономист', startSalary: 220000, tuitionPerYear: 800000, studyYears: 4, emoji: '📊'),
      Profession(id: 'teacher', name: 'Педагог', nameKz: 'Педагог', startSalary: 180000, tuitionPerYear: 600000, studyYears: 4, emoji: '📚'),
      Profession(id: 'designer', name: 'Дизайнер', nameKz: 'Дизайнер', startSalary: 250000, tuitionPerYear: 850000, studyYears: 4, emoji: '🎨'),
      Profession(id: 'finance', name: 'Финансист', nameKz: 'Қаржыгер', startSalary: 300000, tuitionPerYear: 1100000, studyYears: 4, emoji: '💵'),
    ];
  }

  /// Список университетов для ROI-калькулятора
  List<University> getUniversities() {
    return [
      University(id: 'narxoz', name: 'Narxoz University', city: 'Алматы', logoUrl: '', imageUrls: [], majors: ['Экономика', 'IT', 'Финансы'], passingScore: 80, tuitionRange: '1 200 000 - 2 000 000 ₸', hasDormitory: true, hasGrants: true, description: '', requirements: [], applicationDeadline: '', address: '', website: '', studentCount: 8000),
      University(id: 'kbtu', name: 'КБТУ', city: 'Алматы', logoUrl: '', imageUrls: [], majors: ['IT', 'Инженерия', 'Бизнес'], passingScore: 90, tuitionRange: '1 500 000 - 2 500 000 ₸', hasDormitory: true, hasGrants: true, description: '', requirements: [], applicationDeadline: '', address: '', website: '', studentCount: 5000),
      University(id: 'kaznu', name: 'КазНУ им. аль-Фараби', city: 'Алматы', logoUrl: '', imageUrls: [], majors: ['Все направления'], passingScore: 75, tuitionRange: '800 000 - 1 500 000 ₸', hasDormitory: true, hasGrants: true, description: '', requirements: [], applicationDeadline: '', address: '', website: '', studentCount: 20000),
      University(id: 'enu', name: 'ЕНУ им. Гумилёва', city: 'Астана', logoUrl: '', imageUrls: [], majors: ['Все направления'], passingScore: 70, tuitionRange: '700 000 - 1 200 000 ₸', hasDormitory: true, hasGrants: true, description: '', requirements: [], applicationDeadline: '', address: '', website: '', studentCount: 15000),
      University(id: 'sdu', name: 'SDU University', city: 'Алматы', logoUrl: '', imageUrls: [], majors: ['IT', 'Бизнес', 'Право'], passingScore: 85, tuitionRange: '1 300 000 - 2 200 000 ₸', hasDormitory: true, hasGrants: true, description: '', requirements: [], applicationDeadline: '', address: '', website: '', studentCount: 6000),
    ];
  }

  RoiRating _calcRating(int months, bool isGrant, bool willWorkOff) {
    if (isGrant && willWorkOff && months == 0) return RoiRating.excellent;
    if (months < 36) return RoiRating.excellent; // до 3 лет
    if (months < 60) return RoiRating.good;      // до 5 лет
    if (months < 96) return RoiRating.average;   // до 8 лет
    return RoiRating.poor;                       // более 8 лет
  }

  /// Форматирует число в читаемый вид: 1 200 000 ₸
  static String formatMoney(int amount) {
    final String s = amount.toString();
    final StringBuffer buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('\u00A0'); // неразрывный пробел
      buf.write(s[i]);
      count++;
    }
    return '${buf.toString().split('').reversed.join()} ₸';
  }
}
