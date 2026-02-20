import 'package:flutter_test/flutter_test.dart';
import 'package:tandau/services/grant_chance_service.dart';

void main() {
  group('GrantChanceService.calculate()', () {
    final service = GrantChanceService();

    // ──────────────────────────────────────────────
    // 1. Граничные значения ЕНТ
    // ──────────────────────────────────────────────
    group('ENT score boundaries', () {
      test('ENT = null → RiskLevel.unknown, chancePercent = 0', () {
        final result = service.calculate(entScore: null, universityId: 'kbtu');
        expect(result.chancePercent, equals(0));
        expect(result.riskLevel, equals(RiskLevel.unknown));
      });

      test('ENT = 0 → RiskLevel.unknown, chancePercent = 0', () {
        final result = service.calculate(entScore: 0, universityId: 'kbtu');
        expect(result.chancePercent, equals(0));
        expect(result.riskLevel, equals(RiskLevel.unknown));
      });

      test('ENT = 140 (max) → chancePercent > 80', () {
        final result = service.calculate(
          entScore: 140,
          universityId: 'kbtu',
          majorCategory: MajorCategory.it,
        );
        expect(result.chancePercent, greaterThanOrEqualTo(80));
      });

      test('ENT below threshold → chancePercent < 40', () {
        // Any common university threshold is well above 30
        final result = service.calculate(
          entScore: 30,
          universityId: 'kbtu',
          majorCategory: MajorCategory.it,
        );
        expect(result.chancePercent, lessThan(40));
      });

      test('ENT above threshold → chancePercent >= 40', () {
        const highScore = 120;
        final result = service.calculate(
          entScore: highScore,
          universityId: 'generic_uni',
          majorCategory: MajorCategory.other,
        );
        expect(result.chancePercent, greaterThanOrEqualTo(40));
      });
    });

    // ──────────────────────────────────────────────
    // 2. Бонусы GPA
    // ──────────────────────────────────────────────
    group('GPA bonus', () {
      test('GPA >= 3.8 adds bonus vs no GPA', () {
        final withoutGpa = service.calculate(
          entScore: 100,
          universityId: 'generic_uni',
        );
        final withGpa = service.calculate(
          entScore: 100,
          universityId: 'generic_uni',
          gpa: 3.9,
        );
        expect(withGpa.chancePercent, greaterThan(withoutGpa.chancePercent));
      });

      test('GPA null is handled without throwing', () {
        expect(
          () => service.calculate(
            entScore: 100,
            universityId: 'generic_uni',
            gpa: null,
          ),
          returnsNormally,
        );
      });
    });

    // ──────────────────────────────────────────────
    // 3. Бонус IELTS
    // ──────────────────────────────────────────────
    group('IELTS bonus', () {
      test('IELTS >= 7.0 adds bonus vs no IELTS', () {
        final withoutIelts = service.calculate(
          entScore: 100,
          universityId: 'generic_uni',
        );
        final withIelts = service.calculate(
          entScore: 100,
          universityId: 'generic_uni',
          ieltsScore: 7.5,
        );
        expect(
          withIelts.chancePercent,
          greaterThan(withoutIelts.chancePercent),
        );
      });

      test('IELTS null is handled without throwing', () {
        expect(
          () => service.calculate(
            entScore: 100,
            universityId: 'generic_uni',
            ieltsScore: null,
          ),
          returnsNormally,
        );
      });
    });

    // ──────────────────────────────────────────────
    // 4. Бонус достижений
    // ──────────────────────────────────────────────
    group('Achievements bonus', () {
      test('5 achievements add bonus vs empty list', () {
        final withoutAch = service.calculate(
          entScore: 100,
          universityId: 'generic_uni',
        );
        final withAch = service.calculate(
          entScore: 100,
          universityId: 'generic_uni',
          achievements: [
            'Олимпиада 1',
            'Олимпиада 2',
            'Хакатон',
            'Волонтёр',
            'Спорт',
          ],
        );
        expect(withAch.chancePercent, greaterThan(withoutAch.chancePercent));
      });

      test('10+ achievements are capped (max 10% bonus)', () {
        final with10 = service.calculate(
          entScore: 100,
          universityId: 'generic_uni',
          achievements: List.generate(10, (i) => 'Achievement $i'),
        );
        final with20 = service.calculate(
          entScore: 100,
          universityId: 'generic_uni',
          achievements: List.generate(20, (i) => 'Achievement $i'),
        );
        // Same result because bonus is capped
        expect(with10.chancePercent, equals(with20.chancePercent));
      });
    });

    // ──────────────────────────────────────────────
    // 5. Целостность результата
    // ──────────────────────────────────────────────
    group('Result integrity', () {
      test('chancePercent always between 0 and 100', () {
        final scores = [0, 1, 50, 100, 120, 140];
        for (final score in scores) {
          final result = service.calculate(
            entScore: score,
            universityId: 'generic_uni',
          );
          expect(
            result.chancePercent,
            inInclusiveRange(0, 100),
            reason: 'Failed for ENT=$score',
          );
        }
      });

      test('result always has non-empty verdict', () {
        final result = service.calculate(
          entScore: 100,
          universityId: 'generic_uni',
        );
        expect(result.verdict, isNotEmpty);
      });

      test('result.dataYear is "2025"', () {
        final result = service.calculate(
          entScore: 100,
          universityId: 'generic_uni',
        );
        expect(result.dataYear, equals('2025'));
      });
    });

    // ──────────────────────────────────────────────
    // 6. detectCategory
    // ──────────────────────────────────────────────
    group('detectCategory()', () {
      test('"Информатика" → MajorCategory.it', () {
        expect(service.detectCategory('Информатика'), equals(MajorCategory.it));
      });

      test('"Медицина" → MajorCategory.medicine', () {
        expect(
          service.detectCategory('Медицина'),
          equals(MajorCategory.medicine),
        );
      });

      test('"Балет" → MajorCategory.other or arts', () {
        final cat = service.detectCategory('Балет');
        expect([MajorCategory.arts, MajorCategory.other].contains(cat), isTrue);
      });
    });
  });
}
