import 'firebase_service.dart';

/// Service that searches the knowledge base for relevant context
/// to inject into AI prompts (RAG pipeline).
class KnowledgeService {
  final FirebaseService _firebaseService;

  /// Cached knowledge base documents (loaded once at startup)
  List<Map<String, dynamic>> _knowledgeBase = [];
  bool _isLoaded = false;

  KnowledgeService(this._firebaseService);

  /// Load knowledge base from Firestore (call once at startup)
  Future<void> init() async {
    try {
      _knowledgeBase = await _firebaseService.getKnowledgeBase();
      _isLoaded = true;
      print('📚 Knowledge Base loaded: ${_knowledgeBase.length} documents');
    } catch (e) {
      print('⚠️ Failed to load Knowledge Base: $e');
      _knowledgeBase = [];
    }
  }

  /// Search for relevant knowledge base documents based on a user query.
  /// Returns formatted context string for RAG injection.
  /// Uses simple keyword matching (category + content).
  String searchAndFormat(String query) {
    if (!_isLoaded || _knowledgeBase.isEmpty) return '';

    final queryLower = query.toLowerCase();

    // Keyword → category mapping for smarter matching
    final Map<String, List<String>> keywordCategories = {
      'ент': ['ent', 'scores'],
      'ұбт': ['ent', 'scores'],
      'балл': ['ent', 'scores'],
      'порог': ['scores'],
      'грант': ['grants', 'quotas'],
      'стипенд': ['grants'],
      'серпін': ['quotas'],
      'серпин': ['quotas'],
      'сельск': ['quotas'],
      'ауыл': ['quotas'],
      'квота': ['quotas'],
      'сусн': ['quotas'],
      'сирот': ['quotas'],
      'инвалид': ['quotas'],
      'алтын': ['achievements'],
      'белгі': ['achievements'],
      'медал': ['achievements'],
      'жатақхана': ['lifestyle'],
      'общежити': ['lifestyle'],
      'мамандық': ['trends'],
      'специальност': ['trends'],
      'тренд': ['trends'],
      'it': ['trends'],
      'медицин': ['trends'],
      'педагог': ['trends'],
      'әскери': ['extras'],
      'военн': ['extras'],
      'кафедр': ['extras'],
      'подач': ['grants'],
      'докумен': ['grants', 'ent'],
      'дедлайн': ['grants', 'ent'],
      'срок': ['grants', 'ent'],
      // Success stories
      'истори': ['success_story'],
      'поступил': ['success_story'],
      'пример': ['success_story'],
      'опыт': ['success_story'],
      'совет': ['success_story'],
      'реальн': ['success_story'],
    };

    // Find matching categories
    final Set<String> matchedCategories = {};
    for (final entry in keywordCategories.entries) {
      if (queryLower.contains(entry.key)) {
        matchedCategories.addAll(entry.value);
      }
    }

    // Score each document
    final List<MapEntry<Map<String, dynamic>, int>> scored = [];

    for (final doc in _knowledgeBase) {
      int score = 0;
      final docCategory = (doc['category'] as String? ?? '').toLowerCase();
      final docContent = (doc['content'] as String? ?? '').toLowerCase();
      final docTitle = (doc['title'] as String? ?? '').toLowerCase();

      // Category match = strong signal
      if (matchedCategories.contains(docCategory)) {
        score += 10;
      }

      // Title keyword match
      for (final word in queryLower.split(RegExp(r'\s+'))) {
        if (word.length < 3) continue;
        if (docTitle.contains(word)) score += 5;
        if (docContent.contains(word)) score += 2;
      }

      if (score > 0) {
        scored.add(MapEntry(doc, score));
      }
    }

    if (scored.isEmpty) return '';

    // Sort by score descending, take top 3
    scored.sort((a, b) => b.value.compareTo(a.value));
    final topDocs = scored.take(3).map((e) => e.key).toList();

    // Format for injection
    final buffer = StringBuffer();
    buffer.writeln('[ФАКТЫ ИЗ БАЗЫ ЗНАНИЙ TANDAU (верифицированные данные):');
    for (final doc in topDocs) {
      final title = doc['title'] ?? 'Без названия';
      final content = doc['content'] ?? '';
      final source = doc['source'] ?? 'TANDAU';
      buffer.writeln('');
      buffer.writeln('📌 $title [Источник: $source]');
      buffer.writeln(content);
    }
    buffer.writeln(']');
    buffer.writeln('');
    buffer.writeln(
        'ВАЖНО: Используй ТОЛЬКО факты из секции выше. Если вопрос НЕ покрыт фактами, отвечай на основе своих знаний, но честно укажи "🟡 данные общей оценки".');

    return buffer.toString();
  }
}
