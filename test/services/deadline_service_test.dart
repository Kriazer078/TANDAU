import 'package:flutter_test/flutter_test.dart';
import 'package:tandau/services/deadline_service.dart';

void main() {
  group('AdmissionDeadline Model', () {
    test('daysLeft calculates correctly based on future dates', () {
      // Adding 1 hour to prevent truncation down to 9 due to milliseconds difference
      final futureDate = DateTime.now().add(const Duration(days: 10, hours: 1));
      final deadline = AdmissionDeadline(
        id: 'test_future',
        title: 'Future Deadline',
        description: 'Testing days left',
        date: futureDate,
        category: DeadlineCategory.ent,
      );

      expect(deadline.daysLeft, 10);
      expect(deadline.isPast, isFalse);
      expect(deadline.isSoon, isFalse); // > 7 days is not soon
    });

    test('isPast is true for past dates', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      final deadline = AdmissionDeadline(
        id: 'test_past',
        title: 'Past Deadline',
        description: 'Testing past deadline',
        date: pastDate,
        category: DeadlineCategory.ent,
      );

      expect(deadline.isPast, isTrue);
      expect(deadline.getCountdownText(null), 'Завершено');
    });

    test('countdownText formats correctly based on time left', () {
      // Adding 1 hour to prevent truncation down to 0
      final tomorrow = DateTime.now().add(const Duration(days: 1, hours: 1));
      final deadline = AdmissionDeadline(
        id: 'test_tomorrow',
        title: 'Tomorrow Deadline',
        description: 'Testing countdown formatting',
        date: tomorrow,
        category: DeadlineCategory.grant,
      );

      expect(deadline.getCountdownText(null), 'Завтра!');
      expect(deadline.isSoon, isTrue);
    });
  });

  group('DeadlineService Singleton', () {
    late DeadlineService service;

    setUp(() {
      service = DeadlineService();
    });

    test('Service initializes correctly and has all defaults', () {
      expect(service.allDeadlines, isNotEmpty);
      expect(service.allDeadlines.length, 7);
    });

    test('daysUntil returns correct value or -1 for unknown', () {
      expect(service.daysUntil('unknown_id'), -1);

      final entEndDays = service.daysUntil('ent_end');
      expect(entEndDays, isNotNull);
    });
  });
}
