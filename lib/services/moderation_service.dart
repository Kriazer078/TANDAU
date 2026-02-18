class ModerationService {
  static final ModerationService _instance = ModerationService._internal();
  factory ModerationService() => _instance;
  ModerationService._internal();

  // Spam protection
  DateTime? _lastMessageTime;
  static const int _spamIntervalSeconds = 2; // Cooldown between messages

  // Enhanced Profanity lists
  final List<String> _profanityEn = [
    'fuck',
    'shit',
    'asshole',
    'bitch',
    'dick',
    'pussy',
    'bastard',
    'cunt',
    'whore',
    'slut',
    'faggot',
    'nigger',
    'nigga',
    'cock',
    'sucker',
    'motherfucker',
  ];

  final List<String> _profanityRu = [
    'хуй',
    'пизда',
    'ебать',
    'сука',
    'бля',
    'блядь',
    'гандон',
    'мудак',
    'уебок',
    'пидор',
    'дрочить',
    'хер',
    'манда',
    'залупа',
    'долбоеб',
    'еблан',
    'шлюха',
  ];

  final List<String> _profanityKk = [
    'қотақ',
    'ам',
    'сігу',
    'кеще',
    'мал',
    'қатын',
    'көт',
    'сіге',
    'жалеп',
    'емше',
    'қотақбас',
    'шүш',
    'сука',
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

  /// Normalize text to handle leetspeak and symbols
  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[0]'), 'o')
        .replaceAll(RegExp(r'[1!]'), 'i')
        .replaceAll(RegExp(r'[@4]'), 'a')
        .replaceAll(RegExp(r'[\$5]'), 's')
        .replaceAll(RegExp(r'[3]'), 'e')
        .replaceAll(RegExp(r'[+]'), 't')
        .replaceAll(
          RegExp(r'[^\w\sа-яёәіңғүұқөһ]'),
          '',
        ); // Remove other symbols
  }

  /// Checks for offensive language in English, Russian, and Kazakh
  bool hasProfanity(String text) {
    if (text.isEmpty) return false;

    // 1. Check original text broken into words
    if (_checkWords(text.toLowerCase())) return true;

    // 2. Check normalized text (handles leetspeak: h3llo -> hello)
    final normalized = _normalize(text);
    if (_checkWords(normalized)) return true;

    return false;
  }

  bool _checkWords(String text) {
    final words = text.split(RegExp(r'\s+'));

    for (final word in words) {
      // Clean word purely for matching
      final cleanWord = word.replaceAll(RegExp(r'[^\wа-яёәіңғүұқөһ]'), '');
      if (cleanWord.isEmpty) continue;

      // Exact match
      if (_profanityEn.contains(cleanWord) ||
          _profanityRu.contains(cleanWord) ||
          _profanityKk.contains(cleanWord)) {
        return true;
      }

      // Partial match for longer words (avoid false positives like "bass", "shoe")
      if (cleanWord.length > 3) {
        // Only trigger partial match if it's a known strong bad word
        for (final bad in _profanityEn) {
          // Avoid "shitt" match, but "bullshit" is ok.
          // Simple contains is risky: "class" contain "ass".
          // So we check if it is part of compound logic only if strictly needed.
          // For now, strict contains only for specific roots.
          if (bad.length > 3 && cleanWord.contains(bad)) {
            // Exception: "classic", "assembly"
            if (bad == 'ass' &&
                (cleanWord.contains('class') ||
                    cleanWord.contains('pass') ||
                    cleanWord.contains('mass') ||
                    cleanWord.contains('bass'))) {
              continue;
            }
            return true;
          }
        }
        for (final bad in _profanityRu) {
          if (cleanWord.contains(bad)) return true;
        }
        for (final bad in _profanityKk) {
          if (cleanWord.contains(bad)) return true;
        }
      }
    }
    return false;
  }
}
