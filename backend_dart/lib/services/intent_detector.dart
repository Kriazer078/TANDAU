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
  static IntentResult detect(String query, {String language = 'ru'}) {
    final q = query.toLowerCase().trim();

    // Multilingual Quick Replies
    final Map<String, String> emptyQueryMsg = {
      'ru': 'Привет! 👋 Я — TANDAU AI, твой помощник по поступлению. Задай вопрос о вузах, ЕНТ или грантах!',
      'kk': 'Сәлем! 👋 Мен — TANDAU AI, оқуға түсу бойынша көмекшіңмін. Университеттер, ҰБТ немесе гранттар туралы сұрақ қой!',
      'en': 'Hi! 👋 I am TANDAU AI, your admission assistant. Ask me about universities, exams, or grants!'
    };

    final Map<String, String> greetingMsg = {
      'ru': 'Привет! 👋 Я — TANDAU AI, твой персональный помощник по поступлению в Казахстане. Спрашивай про ЕНТ, гранты, вузы — помогу разобраться! 🎓',
      'kk': 'Сәлем! 👋 Мен — Қазақстанда оқуға түсуге арналған жеке көмекшің TANDAU AI-мын. ҰБТ, гранттар, университеттер туралы сұрай бер! 🎓',
      'en': 'Hi! 👋 I am TANDAU AI, your personal admission assistant in Kazakhstan. Ask me about exams, grants, and universities! 🎓'
    };

    final Map<String, String> offTopicMsg = {
      'ru': 'Я специализируюсь на поступлении в вузы Казахстана 🇰🇿\n\nМогу помочь с:\n• Баллы ЕНТ и пороги\n• Гранты и стипендии\n• Выбор вуза и специальности\n\nЗадай вопрос по этим темам!',
      'kk': 'Мен Қазақстан университеттеріне түсу бойынша маманданғанмын 🇰🇿\n\nКелесі тақырыптарда көмектесе аламын:\n• ҰБТ балдары және шекті балдар\n• Гранттар және стипендиялар\n• Университет және мамандық таңдау\n\nОсы тақырыптар бойынша сұрақ қой!',
      'en': 'I specialize in university admissions in Kazakhstan 🇰🇿\n\nI can help with:\n• Exam scores and thresholds\n• Grants and scholarships\n• Choosing university and major\n\nAsk me about these topics!'
    };

    // 1. Empty query
    if (q.isEmpty) {
      return IntentResult(
        intent: QueryIntent.greeting,
        quickReply: emptyQueryMsg[language] ?? emptyQueryMsg['ru'],
      );
    }

    // 2. Greetings (no AI needed)
    if (_matchesAny(q, _greetings) && q.length < 30) {
      return IntentResult(
        intent: QueryIntent.greeting,
        quickReply: greetingMsg[language] ?? greetingMsg['ru'],
      );
    }

    // 3. Off-topic (no AI needed)
    if (_matchesAny(q, _offTopic) && !_matchesAny(q, _topicKeywords)) {
      return IntentResult(
        intent: QueryIntent.offTopic,
        quickReply: offTopicMsg[language] ?? offTopicMsg['ru'],
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
    for (final kw in keywords) {
      if (kw.contains(' ')) {
        // Multi-word phrases: simple contains
        if (query.contains(kw)) return true;
      } else {
        // Single root: ensure it does not appear in the middle of another word
        final regex = RegExp(r"(^|[\s.,!?;:\(\)\[\]'-])" '${RegExp.escape(kw)}');
        if (regex.hasMatch(query)) return true;
      }
    }
    return false;
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
    // ⚠️ 'или' убрано — слишком общее, вызывало false-positive
    // (например: «есть ли грант или скидка?» → compare intent)
    'или выбрать',
    'или лучше',
    'салыстыр',
    'салыстыру',
    'что лучше',
    'разница',
    'отличи',
    'қайсысы жақсы',
    'айырмашылығы',
    'артықшылығы',
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
    'документ',
    'нужно для',
    'какие предметы',
    'проходной',
    'түсе алам ба',
    'өту балы',
    'қандай пәндер',
    'құжаттар',
    'қалай түсуге болады',
    'қанша балл',
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
    'білмеймін',
    'көмектесші',
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
