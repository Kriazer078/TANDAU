/// 🎓 Модель профессии для ROI-калькулятора
class Profession {
  final String id;
  final String name; // Русское название
  final String nameKz; // Казахское название
  final int startSalary; // Стартовая зарплата в тг/мес
  final int tuitionPerYear; // Стоимость обучения за год в тг
  final int studyYears; // Продолжительность обучения (лет)
  final String emoji; // Эмодзи для UI

  const Profession({
    required this.id,
    required this.name,
    required this.nameKz,
    required this.startSalary,
    required this.tuitionPerYear,
    required this.studyYears,
    required this.emoji,
  });

  /// Общая стоимость обучения
  int get totalTuition => tuitionPerYear * studyYears;

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Profession && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
