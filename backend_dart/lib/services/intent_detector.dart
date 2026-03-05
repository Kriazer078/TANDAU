/// 🎯 Intent Detection for TANDAU AI.
///
/// Classifies user queries into intents BEFORE calling LLM.
/// Fast keyword-based — no API calls needed.
///
/// Usage:
///   final result = IntentDetector.detect("Сравни КазНУ и КБТУ");
///   // result.intent == QueryIntent.compare
///   // result.quickReply == null (needs AI)
///
///   final greeting = IntentDetector.detect("Привет");
///   // greeting.intent == QueryIntent.greeting
///   // greeting.quickReply == "Привет! 👋 Я — TANDAU AI..."
class IntentDetector {
  IntentDetector._();

  /// Detect intent from user query
  static IntentResult detect(String query) {
    final q = query.toLowerCase().trim();

    // 1. Empty query
    if (q.isEmpty) {
      return IntentResult(
        intent: QueryIntent.greeting,
        quickReply:
            'Привет! 👋 Я — TANDAU AI, твой помощник по поступлению. Задай вопрос о вузах, ЕНТ или грантах!',
      );
    }

    // 2. Greetings (no AI needed)
    if (_matchesAny(q, _greetings) && q.length < 30) {
      return IntentResult(
        intent: QueryIntent.greeting,
        quickReply:
            'Привет! 👋 Я — TANDAU AI, твой персональный помощник по поступлению в Казахстане. Спрашивай про ЕНТ, гранты, вузы — помогу разобраться! 🎓',
      );
    }

    // 3. Off-topic (no AI needed)
    if (_matchesAny(q, _offTopic) && !_matchesAny(q, _topicKeywords)) {
      return IntentResult(
        intent: QueryIntent.offTopic,
        quickReply:
            'Я специализируюсь на поступлении в вузы Казахстана 🇰🇿\n\nМогу помочь с:\n• Баллы ЕНТ и пороги\n• Гранты и стипендии\n• Выбор вуза и специальности\n\nЗадай вопрос по этим темам!',
      );
    }

    // 4. Comparison
    if (_matchesAny(q, _compareKeywords)) {
      return IntentResult(intent: QueryIntent.compare);
    }

    // 5. Strategy / chances
    if (_matchesAny(q, _strategyKeywords)) {
      return IntentResult(intent: QueryIntent.strategy);
    }

    // 6. Action (save/favorite/compare command)
    if (_matchesAny(q, _actionKeywords)) {
      return IntentResult(intent: QueryIntent.action);
    }

    // 7. Emotional support
    if (_matchesAny(q, _emotionKeywords)) {
      return IntentResult(intent: QueryIntent.emotion);
    }

    // 8. Default: informational
    return IntentResult(intent: QueryIntent.info);
  }

  // ═══════════════════════════════════════════════════════════════
  // KEYWORD LISTS — easy to extend
  // ═══════════════════════════════════════════════════════════════

  static bool _matchesAny(String query, List<String> keywords) {
    return keywords.any((kw) => query.contains(kw));
  }

  static const List<String> _greetings = [
    'привет',
    'салем',
    'сәлем',
    'здравствуй',
    'hello',
    'hi',
    'добрый день',
    'добрый вечер',
    'доброе утро',
    'хай',
    'қайырлы таң',
    'қайырлы күн',
  ];

  static const List<String> _offTopic = [
    'погод',
    'weather',
    'анекдот',
    'шутк',
    'кино',
    'фильм',
    'музык',
    'игр',
    'game',
    'рецепт',
    'готов',
    'спорт',
    'футбол',
    'политик',
    'война',
    'новост',
    'курс доллар',
    'биткоин',
    'крипт',
  ];

  static const List<String> _topicKeywords = [
    'ент',
    'ұбт',
    'балл',
    'грант',
    'вуз',
    'универ',
    'поступ',
    'специальн',
    'мамандық',
    'стипенд',
    'квота',
    'серпін',
    'общежити',
    'жатақхана',
    'образован',
    'білім',
  ];

  static const List<String> _compareKeywords = [
    'сравни',
    'сравнить',
    'сравнение',
    'vs',
    'или',
    'салыстыр',
    'что лучше',
    'разница',
    'отличи',
  ];

  static const List<String> _strategyKeywords = [
    'шанс',
    'вероятность',
    'могу ли',
    'поступлю',
    'стратеги',
    'план',
    'жоспар',
    'мүмкіндік',
    'хватит ли',
    'пройду',
    'попаду',
    'успею',
  ];

  static const List<String> _actionKeywords = [
    'сохрани',
    'добавь в избранн',
    'избранн',
    'сақта',
    'таңдаулылар',
    'bookmark',
  ];

  static const List<String> _emotionKeywords = [
    'боюсь',
    'страшно',
    'не уверен',
    'переживаю',
    'стресс',
    'тревог',
    'волну',
    'не знаю что делать',
    'помоги',
    'қорқ',
    'уайым',
    'мотивац',
  ];
}

/// The detected intent type
enum QueryIntent {
  /// Short factual answer
  info,

  /// Comparison table
  compare,

  /// Detailed admission strategy
  strategy,

  /// Save/favorite/action command
  action,

  /// Emotional support
  emotion,

  /// Greeting — no AI needed
  greeting,

  /// Off-topic — no AI needed
  offTopic,
}

/// Result of intent detection
class IntentResult {
  final QueryIntent intent;

  /// If not null, respond immediately without calling LLM
  final String? quickReply;

  const IntentResult({
    required this.intent,
    this.quickReply,
  });

  /// Whether this intent needs an LLM call
  bool get needsAI => quickReply == null;
}
