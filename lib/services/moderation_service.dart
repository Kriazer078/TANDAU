class ModerationService {
  static final ModerationService _instance = ModerationService._internal();
  factory ModerationService() => _instance;
  ModerationService._internal();

  // Spam protection
  DateTime? _lastMessageTime;
  static const int _spamIntervalSeconds = 2; // Cooldown between messages

  // ==========================================
  // PROFANITY DICTIONARIES
  // ==========================================

  // Strong roots that trigger on ANY partial match (rarely have false positives)
  final List<String> _strongRootsRu = [
    'хуй',
    'хуя',
    'пизд',
    'ебан',
    'ёбан',
    'ебуч',
    'бляд',
    'блят',
    'гандон',
    'гондон',
    'залуп',
    'шлюх',
    'мудак',
    'пидор',
    'пидр',
    'еблан',
    'долбоеб',
    'долбоёб',
    'уебок',
    'уёбок',
  ];

  // Words that MUST match exactly to avoid false positives (e.g., 'бля' in 'рубля')
  final List<String> _exactWordsRu = [
    'бля',
    'сука',
    'суки',
    'сучку',
    'сучка',
    'хер',
    'манда',
    'ебать',
    'хня',
    'суку',
    'мразь',
    'мрази',
  ];

  final List<String> _strongRootsKk = [
    'қотақ',
    'жалеп',
    'амда',
    'шешенді',
    'қотақбас',
  ];

  final List<String> _exactWordsKk = [
    'ам',
    'сігу',
    'кеще',
    'мал',
    'қатын',
    'көт',
    'сіге',
    'емше',
    'шүш',
    'шешең',
    'шешен',
    'сигу',
    'котак',
    'котакбас',
  ];

  final List<String> _strongRootsEn = [
    'fuck',
    'shit',
    'bitch',
    'cunt',
    'nigg',
    'whore',
    'slut',
    'fagg',
    'pussy',
  ];

  final List<String> _exactWordsEn = [
    'ass',
    'dick',
    'cock',
    'sucker',
    'bastard',
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

    // 1. Check original text
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

      // 1. Exact matches
      if (_exactWordsEn.contains(cleanWord) ||
          _exactWordsRu.contains(cleanWord) ||
          _exactWordsKk.contains(cleanWord)) {
        return true;
      }

      // 2. Partial strong roots match
      for (final root in _strongRootsRu) {
        if (cleanWord.contains(root)) return true;
      }
      for (final root in _strongRootsKk) {
        if (cleanWord.contains(root)) return true;
      }
      for (final root in _strongRootsEn) {
        if (cleanWord.contains(root)) return true;
      }
    }
    return false;
  }
}
