import 'package:cloud_firestore/cloud_firestore.dart';

/// 🧭 Модель результата карьерного теста (Голланд RIASEC / Климов ДДО)
///
/// Хранится в Firestore: users/{uid}/careerTests/{testId}
/// Краткий код кешируется в UserModel (hollandCode, klimovType)
class CareerTestResult {
  final String id;
  final String testType; // 'holland' | 'klimov'
  final Map<String, int> scores; // {'R': 8, 'I': 5, ...}
  final String topCode; // 'RIA' (Голланд) или 'техника' (Климов)
  final List<String> recommendedGops; // ['B057', 'B058', ...]
  final DateTime completedAt;

  const CareerTestResult({
    required this.id,
    required this.testType,
    required this.scores,
    required this.topCode,
    required this.recommendedGops,
    required this.completedAt,
  });

  /// Конвертация в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'testType': testType,
      'scores': scores,
      'topCode': topCode,
      'recommendedGops': recommendedGops,
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }

  /// Создание из Map (Firestore)
  factory CareerTestResult.fromMap(Map<String, dynamic> map) {
    return CareerTestResult(
      id: map['id'] ?? '',
      testType: map['testType'] ?? 'holland',
      scores: Map<String, int>.from(map['scores'] ?? {}),
      topCode: map['topCode'] ?? '',
      recommendedGops: List<String>.from(map['recommendedGops'] ?? []),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Название типа на русском (для RIASEC)
  static const Map<String, String> riasecNamesRu = {
    'R': 'Реалистичный',
    'I': 'Исследовательский',
    'A': 'Артистичный',
    'S': 'Социальный',
    'E': 'Предприимчивый',
    'C': 'Конвенциональный',
  };

  /// Описания типов RIASEC
  static const Map<String, String> riasecDescriptions = {
    'R': 'Предпочитаешь работу руками, с техникой и инструментами. '
        'Тебе нравится создавать что-то осязаемое и решать практические задачи.',
    'I': 'Любишь анализировать, исследовать и разбираться в сложных вопросах. '
        'Тебе интересна наука и понимание того, как устроен мир.',
    'A': 'Творческая личность — тебе важна свобода самовыражения. '
        'Тебя привлекают искусство, дизайн и нестандартные решения.',
    'S': 'Люди — твоя сильная сторона. Тебе нравится помогать, учить и '
        'заботиться о других. Общение заряжает тебя энергией.',
    'E': 'Лидер по натуре — тебе нравится управлять, убеждать и организовывать. '
        'Бизнес и предпринимательство — твоя стихия.',
    'C': 'Ты ценишь порядок, точность и системный подход. '
        'Работа с данными, документами и цифрами тебе по душе.',
  };

  /// Emoji для типов RIASEC
  static const Map<String, String> riasecEmojis = {
    'R': '🔧',
    'I': '🔬',
    'A': '🎨',
    'S': '🤝',
    'E': '📈',
    'C': '📊',
  };

  /// Цвета для типов RIASEC (hex)
  static const Map<String, int> riasecColors = {
    'R': 0xFF4CAF50, // Зелёный
    'I': 0xFF2196F3, // Синий
    'A': 0xFFE91E63, // Розовый
    'S': 0xFFFF9800, // Оранжевый
    'E': 0xFF9C27B0, // Фиолетовый
    'C': 0xFF607D8B, // Серо-синий
  };

  /// Название типа на русском (для Климова)
  static const Map<String, String> klimovNamesRu = {
    'nature': 'Природа',
    'tech': 'Техника',
    'human': 'Человек',
    'signs': 'Знаковая система',
    'art': 'Художественный образ',
  };

  /// Описания типов Климова
  static const Map<String, String> klimovDescriptions = {
    'nature': 'Тебе нравится изучать и работать с животными, растениями, '
        'микроорганизмами и другими биологическими объектами.',
    'tech': 'Тебя привлекают машины, механизмы, приборы, материалы и '
        'различные виды энергии. Сфера инженерии и ИТ.',
    'human': 'Твоя сильная сторона — взаимодействие с людьми. '
        'Воспитание, обучение, управление, медицина или обслуживание.',
    'signs': 'Тебе легко дается работа с цифрами, текстами, кодами, '
        'чертежами и картами. Это мир вычислений и аналитики.',
    'art': 'Твоя стихия — это творчество, искусство, дизайн, музыка, '
        'литература и актерское мастерство.',
  };

  /// Emoji для типов Климова
  static const Map<String, String> klimovEmojis = {
    'nature': '🌿',
    'tech': '⚙️',
    'human': '🤝',
    'signs': '🔢',
    'art': '🎨',
  };

  /// Цвета для типов Климова
  static const Map<String, int> klimovColors = {
    'nature': 0xFF4CAF50,
    'tech': 0xFF607D8B,
    'human': 0xFFFF9800,
    'signs': 0xFF2196F3,
    'art': 0xFFE91E63,
  };
}
