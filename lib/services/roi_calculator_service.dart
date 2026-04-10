import '../models/profession.dart';
import '../models/university.dart';

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

  /// Рассчитать ROI для выбранной профессии и типа обучения.
  ///
  /// [profession] — выбранная профессия с данными о зарплате и стоимости
  /// [isGrant]   — true если пользователь учится на гранте
  /// [university] — опционально выбранный университет для точной стоимости (берем maxTuitionValue)
  /// [yearsToCalculate] — за сколько лет считать прибыль (по умолчанию 10)
  /// [willWorkOffGrant] — готов ли отработать 3 года
  /// [isRuralQuota] — поступает ли по сельской квоте
  /// [isPedagogicalOrMedical] — является ли профессия мед/пед
  /// [includeLivingCosts] — учитывать ли расходы на проживание во время учебы
  RoiResult calculate({
    required Profession profession,
    required bool isGrant,
    University? university,
    int yearsToCalculate = 10,
    bool willWorkOffGrant = true,
    bool isRuralQuota = false,
    bool isPedagogicalOrMedical = false,
    bool includeLivingCosts = false,
  }) {
    int salary = profession.startSalary;

    // Учёт специфики государственной отработки в первые 3 года (мес: 1..36)
    int initialSalary = salary;
    if (isGrant && willWorkOffGrant) {
       if (isPedagogicalOrMedical) {
         // Фиксированная гос. зарплата специалиста без категории
         initialSalary = 200000; 
       } else if (isRuralQuota) {
         // Зарплата в селе часто ниже городской на 20-25%
         initialSalary = (salary * 0.8).round();
       }
    }
    
    // Если университет выбран и у него указана стоимость, берем её за год, иначе среднюю по профессии
    final int baseTuitionYear = (university != null && university.maxTuitionValue > 0)
        ? university.maxTuitionValue.toInt()
        : profession.tuitionPerYear;

    int fullTuition = baseTuitionYear * profession.studyYears;
    
    // Оценочные расходы на жизнь: общага/комната, питание, транспорт (возьмем скромно 100 000 тг/мес)
    if (includeLivingCosts) {
      final livingCostPerYear = 100000 * 12;
      fullTuition += (livingCostPerYear * profession.studyYears);
    }
    
    // Если на гранте, но не отработает - обязан вернуть всю сумму (долг)
    final bool isDebt = isGrant && !willWorkOffGrant; // долг за само обучение
    final int tuition = (isGrant && willWorkOffGrant) ? (includeLivingCosts ? 100000 * 12 * profession.studyYears : 0) : fullTuition;

    // В реальности на окупаемость идет не вся зарплата, а только "свободные деньги".
    // Возьмем оптимистичные 35% от зарплаты как Сбережения на окупаемость.
    final int monthlySavings = (initialSalary * 0.35).round();

    // Защита от деления на ноль
    final int paybackMonths =
        (monthlySavings > 0 && tuition > 0) ? (tuition / monthlySavings).ceil() : 0;

    final int paybackYears = paybackMonths ~/ 12;
    final int remainingMonths = paybackMonths % 12;

    // Прибыль за n лет = (стартовая_зп * 36) + (маркет_зп * (лет - 3)) - стоимость
    // (Для простоты предполагаем, что если отработка есть, первые 3 года зп может быть ниже)
    int profit = 0;
    if (yearsToCalculate <= 3 && isGrant && willWorkOffGrant) {
       profit = initialSalary * 12 * yearsToCalculate - tuition;
    } else if (isGrant && willWorkOffGrant) {
       profit = (initialSalary * 12 * 3) + (salary * 12 * (yearsToCalculate - 3)) - tuition;
    } else {
       profit = salary * 12 * yearsToCalculate - tuition;
    }

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
      willWorkOff: willWorkOffGrant,
      isDebt: isDebt,
    );
  }

  RoiRating _calcRating(int months, bool isGrant, bool willWorkOff) {
    if (isGrant && willWorkOff && months == 0) return RoiRating.excellent;
    // Так как теперь считаем через 35% от з/п, сроки выросли в ~3 раза
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
