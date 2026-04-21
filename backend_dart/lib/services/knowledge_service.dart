import 'dart:io';
import 'firebase_service.dart';

/// Service that searches the knowledge base using keyword matching
/// for document retrieval (RAG pipeline).
/// Note: Vector embeddings disabled — Groq API doesn't support embeddings.
/// Falls back to optimized keyword search.
class KnowledgeService {
  final FirebaseService _firebaseService;

  /// Cached knowledge base documents
  List<Map<String, dynamic>> _knowledgeBase = [];

  bool _isLoaded = false;
  bool get isInitialized => _isLoaded;

  // Note: Embeddings disabled — Groq doesn't have embeddings API.
  // Using keyword search as fallback.

  KnowledgeService(this._firebaseService);

  /// Load knowledge base and pre-compute embeddings
  Future<void> init() async {
    await _loadAndCompute();
  }

  /// Force reload of knowledge base (e.g. after admin updates)
  Future<void> reinit() async {
    _isLoaded = false;
    await _loadAndCompute();
  }

  Future<void> _loadAndCompute() async {
    try {
      _knowledgeBase = await _firebaseService.getKnowledgeBase();
      stderr.writeln('📚 Knowledge Base loaded: ${_knowledgeBase.length} documents');
      stderr.writeln('🔍 Using keyword search for RAG (Groq has no embeddings API)');
      _isLoaded = true;
    } catch (e) {
      stderr.writeln('⚠️ Failed to load Knowledge Base: $e');
      _knowledgeBase = [];
    }
  }

  // Note: Embedding methods removed — Groq doesn't support embeddings API.
  // Using keyword search exclusively for RAG retrieval.



  String searchAndFormat(String query) {
    if (!_isLoaded || _knowledgeBase.isEmpty) return '';
    return _keywordSearch(query);
  }

  Future<String> searchAndFormatAsync(String query) async {
    if (!_isLoaded || _knowledgeBase.isEmpty) return '';
    return _keywordSearch(query);
  }


  String _keywordSearch(String query) {
    final queryLower = query.toLowerCase();

    final Map<String, List<String>> keywordCategories = {
      'ент': ['ent', 'scores'],
      'ұбт': ['ent', 'scores'],
      'балл': ['ent', 'scores'],
      'порог': ['scores'],
      'грант': ['grants', 'quotas'],
      'стипенд': ['grants', 'scholarships'],
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
      'общежити': ['lifestyle'],
      'жатақхана': ['lifestyle'],
      'специальност': ['trends'],
      'мамандық': ['trends'],
      'it': ['trends'],
      'медицин': ['trends'],
      'педагог': ['trends'],
      'военн': ['lifestyle'],
      'подач': ['grants'],
      'докумен': ['grants', 'ent', 'faq'],
      'дедлайн': ['grants', 'ent'],
      'срок': ['grants', 'ent'],
      'истори': ['success_story'],
      'совет': ['success_story'],
      'колледж': ['faq'],
      'перевод': ['faq'],
      'алматы': ['cities', 'university'],
      'астана': ['cities', 'university'],
      'шымкент': ['cities', 'university'],
      'караганда': ['cities', 'university'],
      'болашак': ['scholarships'],
      'erasmus': ['scholarships'],
    };

    final Set<String> matchedCategories = {};
    for (final entry in keywordCategories.entries) {
      if (queryLower.contains(entry.key)) {
        matchedCategories.addAll(entry.value);
      }
    }

    final List<MapEntry<Map<String, dynamic>, int>> scored = [];
    for (final doc in _knowledgeBase) {
      int score = 0;
      final docCategory = (doc['category'] as String? ?? '').toLowerCase();
      final docContent = (doc['content'] as String? ?? '').toLowerCase();
      final docTitle = (doc['title'] as String? ?? '').toLowerCase();

      if (matchedCategories.contains(docCategory)) score += 10;
      for (final word in queryLower.split(RegExp(r'\s+'))) {
        if (word.length < 3) continue;
        if (docTitle.contains(word)) score += 5;
        if (docContent.contains(word)) score += 2;
      }
      if (score > 0) scored.add(MapEntry(doc, score));
    }

    if (scored.isEmpty) return '';

    scored.sort((a, b) => b.value.compareTo(a.value));
    final topDocs = scored.take(5).map((e) => e.key).toList();

    return _formatDocs(topDocs);
  }

  String _formatDocs(List<Map<String, dynamic>> docs) {
    final buffer = StringBuffer();
    buffer.writeln('[ФАКТЫ ИЗ БАЗЫ ЗНАНИЙ TANDAU (верифицированные данные):');
    for (final doc in docs) {
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
