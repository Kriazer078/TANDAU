import 'package:flutter_test/flutter_test.dart';
import 'package:tandau/services/moderation_service.dart';

void main() {
  late ModerationService moderationService;

  setUp(() {
    moderationService = ModerationService();
  });

  group('ModerationService - Profanity Detection', () {
    test('Detects Russian profanity (strong roots & exact words)', () {
      expect(moderationService.hasProfanity('Ты хуй'), isTrue);
      expect(moderationService.hasProfanity('Это просто пиздец'), isTrue);
      expect(moderationService.hasProfanity('шлюха'), isTrue);
      expect(moderationService.hasProfanity('Обычный текст'), isFalse);

      // Exact word check vs partial match
      expect(moderationService.hasProfanity('мразь'), isTrue);
      expect(moderationService.hasProfanity('сука'), isTrue);
      expect(
        moderationService.hasProfanity('100 рубля'),
        isFalse,
      ); // 'бля' is exact, shouldn't trigger here because of split
    });

    test('Detects Kazakh profanity', () {
      expect(moderationService.hasProfanity('қотақбас'), isTrue);
      expect(moderationService.hasProfanity('шешенді'), isTrue);
      expect(moderationService.hasProfanity('сігу'), isTrue);
      expect(moderationService.hasProfanity('Сәлем әлем'), isFalse);
    });

    test('Detects English profanity', () {
      expect(moderationService.hasProfanity('fuck you'), isTrue);
      expect(moderationService.hasProfanity('bullshit'), isTrue);
      expect(moderationService.hasProfanity('dick'), isTrue);
      expect(moderationService.hasProfanity('hello world'), isFalse);
    });

    test('Leetspeak and symbol circumvention', () {
      // Leetspeak detection: sh1t -> shit, b1tch -> bitch, 5hit -> shit
      expect(moderationService.hasProfanity('sh1t'), isTrue);
      expect(moderationService.hasProfanity('b1tch'), isTrue);
      expect(moderationService.hasProfanity('5hit'), isTrue);
    });
  });

  group('ModerationService - Spam Check', () {
    test('Spamming logic allows messages with delay', () async {
      // First message should not be spam
      expect(moderationService.isSpamming(), isFalse);

      // Immediate second message should be flagged as spam
      expect(moderationService.isSpamming(), isTrue);
    });
  });
}
