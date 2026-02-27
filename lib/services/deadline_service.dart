import 'package:flutter/material.dart';

/// Дедлайны поступления 2026
/// Локальный сервис — не требует бэкенда
class DeadlineService {
  static final DeadlineService _instance = DeadlineService._internal();
  factory DeadlineService() => _instance;
  DeadlineService._internal();

  /// Все ключевые дедлайны 2026
  final List<AdmissionDeadline> _deadlines = [
    AdmissionDeadline(
      id: 'ent_start',
      title: 'Начало ЕНТ',
      description: 'Основной период ЕНТ 2026 начинается',
      date: DateTime(2026, 5, 16),
      category: DeadlineCategory.ent,
      icon: Icons.edit_note_rounded,
      iconGradient: [Color(0xFF6366F1), Color(0xFF818CF8)],
    ),
    AdmissionDeadline(
      id: 'ent_end',
      title: 'Последний день ЕНТ',
      description: 'Завершение основного периода ЕНТ',
      date: DateTime(2026, 7, 7),
      category: DeadlineCategory.ent,
      icon: Icons.timer_outlined,
      iconGradient: [Color(0xFFEF4444), Color(0xFFF87171)],
    ),
    AdmissionDeadline(
      id: 'grant_application_start',
      title: 'Начало подачи на грант',
      description: 'Открытие приёма заявлений на образовательные гранты',
      date: DateTime(2026, 7, 13),
      category: DeadlineCategory.grant,
      icon: Icons.school_rounded,
      iconGradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    ),
    AdmissionDeadline(
      id: 'grant_application_end',
      title: 'Дедлайн подачи на грант',
      description: 'Последний день подачи заявлений через e-edu.kz',
      date: DateTime(2026, 7, 20),
      category: DeadlineCategory.grant,
      icon: Icons.warning_amber_rounded,
      iconGradient: [Color(0xFFDC2626), Color(0xFFEF4444)],
      isUrgent: true,
    ),
    AdmissionDeadline(
      id: 'grant_results',
      title: 'Результаты грантов',
      description: 'Объявление результатов конкурса на гранты',
      date: DateTime(2026, 8, 10),
      category: DeadlineCategory.grant,
      icon: Icons.emoji_events_rounded,
      iconGradient: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    ),
    AdmissionDeadline(
      id: 'enrollment_start',
      title: 'Начало зачисления',
      description: 'Зачисление студентов в вузы',
      date: DateTime(2026, 8, 15),
      category: DeadlineCategory.enrollment,
      icon: Icons.assignment_turned_in_rounded,
      iconGradient: [Color(0xFF10B981), Color(0xFF34D399)],
    ),
    AdmissionDeadline(
      id: 'semester_start',
      title: 'Начало учебного года',
      description: 'Первый день занятий',
      date: DateTime(2026, 9, 1),
      category: DeadlineCategory.enrollment,
      icon: Icons.auto_stories_rounded,
      iconGradient: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
    ),
  ];

  /// Получить все будущие дедлайны
  List<AdmissionDeadline> getUpcomingDeadlines() {
    final now = DateTime.now();
    return _deadlines.where((d) => d.date.isAfter(now)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Получить ближайший дедлайн
  AdmissionDeadline? getNextDeadline() {
    final upcoming = getUpcomingDeadlines();
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  /// Получить дедлайны в указанном диапазоне дней
  List<AdmissionDeadline> getDeadlinesWithin({int days = 30}) {
    final now = DateTime.now();
    final limit = now.add(Duration(days: days));
    return _deadlines
        .where((d) => d.date.isAfter(now) && d.date.isBefore(limit))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Получить дни до конкретного дедлайна
  int daysUntil(String deadlineId) {
    try {
      final deadline = _deadlines.firstWhere((d) => d.id == deadlineId);
      return deadline.date.difference(DateTime.now()).inDays;
    } catch (_) {
      return -1;
    }
  }

  /// Все дедлайны (включая прошедшие)
  List<AdmissionDeadline> get allDeadlines => List.unmodifiable(_deadlines);
}

/// Модель дедлайна
class AdmissionDeadline {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DeadlineCategory category;
  final IconData icon;
  final List<Color> iconGradient;
  final bool isUrgent;

  const AdmissionDeadline({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.category,
    this.icon = Icons.calendar_today_rounded,
    this.iconGradient = const [Color(0xFF6366F1), Color(0xFF818CF8)],
    this.isUrgent = false,
  });

  /// Дней до дедлайна
  int get daysLeft => date.difference(DateTime.now()).inDays;

  /// Прошёл ли дедлайн
  bool get isPast => DateTime.now().isAfter(date);

  /// Срочный (< 7 дней)
  bool get isSoon => !isPast && daysLeft <= 7;

  /// Формат даты
  String get formattedDate {
    final months = [
      '',
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  /// Строка обратного отсчёта
  String get countdownText {
    if (isPast) return 'Завершено';
    final days = daysLeft;
    if (days == 0) return 'Сегодня!';
    if (days == 1) return 'Завтра!';
    if (days < 7) return '$days дней';
    if (days < 30) return '${(days / 7).floor()} нед.';
    return '${(days / 30).floor()} мес.';
  }
}

/// Категория дедлайна
enum DeadlineCategory { ent, grant, enrollment }
