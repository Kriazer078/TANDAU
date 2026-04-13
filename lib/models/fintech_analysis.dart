/// 📈 Результат глубокого финансового анализа (FinTech модуль)
class FinTechAnalysis {
  /// Профессия и вуз
  final String professionName;
  final String universityName;

  /// NPV (Net Present Value) — Чистая приведенная стоимость диплома.
  /// Показывает ценность образования в сегодняшних деньгах с учетом инфляции и дисконтирования.
  final int npv;

  /// Opportunity Cost (Упущенная выгода).
  /// Сколько бы заработал студент, если бы вложил стоимость обучения в депозит или S&P 500.
  final int opportunityCost;

  /// Реальный располагаемый доход после налогов (Net) и инфляции.
  final int monthlyRealIncome;

  /// Прогнозируемый капитал через 10 лет работы.
  final int totalWealthAt10Years;

  /// Эффективность инвестиции (аналог IRR).
  /// Показывает, под какой "годовой процент" вы вкладываете деньги в это образование.
  final double investmentReturnRate;

  /// Общая сумма налогов, которую выпускник выплатит государству за 10 лет (Impact).
  final int totalTaxesPaid;

  const FinTechAnalysis({
    required this.professionName,
    required this.universityName,
    required this.npv,
    required this.opportunityCost,
    required this.monthlyRealIncome,
    required this.totalWealthAt10Years,
    required this.investmentReturnRate,
    required this.totalTaxesPaid,
  });

  /// Грейд финансовой привлекательности (FinTech Grade)
  String get financialGrade {
    if (investmentReturnRate > 0.40) return 'AAA'; // Очень высокая отдача
    if (investmentReturnRate > 0.25) return 'AA';
    if (investmentReturnRate > 0.15) return 'A';
    if (investmentReturnRate > 0.10) return 'B';
    return 'C'; // Ниже доходности депозита
  }

  String get gradeDescription {
    switch (financialGrade) {
      case 'AAA':
        return 'Исключительная доходность. Инвестиция в разы лучше депозита.';
      case 'AA':
        return 'Высокая эффективность. Отличный выбор для капитала.';
      case 'A':
        return 'Хорошая доходность, стабильное вложение.';
      case 'B':
        return 'Умеренная ликвидность. Доходность на уровне инфляции.';
      case 'C':
        return 'Низкая финансовая эффективность. Подумай об альтернативах.';
      default:
        return '';
    }
  }
}
