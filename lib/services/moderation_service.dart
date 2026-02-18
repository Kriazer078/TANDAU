class ModerationService {
  static final ModerationService _instance = ModerationService._internal();
  factory ModerationService() => _instance;
  ModerationService._internal();

  // Spam protection
  DateTime? _lastMessageTime;
  static const int _spamIntervalSeconds = 2; // Cooldown between messages

  // Profanity lists (simplified for demonstration, should be expanded)
  final List<String> _profanityEn = [
    'fuck',
    'shit',
    'asshole',
    'bitch',
    'dick',
    'pussy',
    'bastard',
    'cunt',
  ];

  final List<String> _profanityRu = [
    'хуй',
    'пизда',
    'ебать',
    'сука',
    'бля',
    'гандон',
    'мудак',
    'уебок',
    'пидор',
    'дрочить',
  ];

  final List<String> _profanityKk = [
    'қотақ',
    'ам',
    'сігу',
    'кеще',
    'мал',
    'қатын',
    'көт',
  ];

  /// Checks if the message is sent too fast
  bool isSpamming() {
    if (_lastMessageTime == null) {
      _lastMessageTime = DateTime.now();
      return false;
    }

    final now = DateTime.now();
    final difference = now.difference(_lastMessageTime!).inSeconds;

    if (difference < _spamIntervalSeconds) {
      return true;
    }

    _lastMessageTime = now;
    return false;
  }

  /// Checks for offensive language in English, Russian, and Kazakh
  bool hasProfanity(String text) {
    final lowerText = text.toLowerCase();

    // Check all words
    final words = lowerText.split(RegExp(r'\s+'));

    for (final word in words) {
      // Clean word from punctuation
      final cleanWord = word.replaceAll(RegExp(r'[^\w\sа-яёәіңғүұқөһ]'), '');

      if (_profanityEn.contains(cleanWord) ||
          _profanityRu.contains(cleanWord) ||
          _profanityKk.contains(cleanWord)) {
        return true;
      }

      // Check for partial matches (substrings) if word is long enough
      if (cleanWord.length > 3) {
        for (final bad in _profanityEn) {
          if (cleanWord.contains(bad)) {
            return true;
          }
        }
        for (final bad in _profanityRu) {
          if (cleanWord.contains(bad)) {
            return true;
          }
        }
        for (final bad in _profanityKk) {
          if (cleanWord.contains(bad)) {
            return true;
          }
        }
      }
    }

    return false;
  }
}
