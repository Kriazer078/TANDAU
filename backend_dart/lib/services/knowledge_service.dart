// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';

/// Service that searches the knowledge base using vector embeddings
/// for semantic similarity (RAG pipeline with Gemini Embeddings).
class KnowledgeService {
  final FirebaseService _firebaseService;
  final String _apiKey;

  /// Cached knowledge base documents
  List<Map<String, dynamic>> _knowledgeBase = [];

  /// Pre-computed embeddings for each document (parallel index)
  List<List<double>> _docEmbeddings = [];

  bool _isLoaded = false;

  /// Gemini Embedding model endpoint
  static const String _embeddingEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent';

  /// Batch embedding endpoint
  static const String _batchEmbeddingEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:batchEmbedContents';

  KnowledgeService(this._firebaseService, this._apiKey);

  /// Load knowledge base and pre-compute embeddings
  Future<void> init() async {
    try {
      _knowledgeBase = await _firebaseService.getKnowledgeBase();
      print('📚 Knowledge Base loaded: ${_knowledgeBase.length} documents');

      if (_apiKey.isNotEmpty && !_apiKey.startsWith('REPLACE')) {
        await _computeEmbeddings();
      } else {
        print('⚠️ No API key — falling back to keyword search');
      }

      _isLoaded = true;
    } catch (e) {
      print('⚠️ Failed to load Knowledge Base: $e');
      _knowledgeBase = [];
    }
  }

  /// Generate embeddings for all KB documents in batches
  Future<void> _computeEmbeddings() async {
    print('🧮 Computing embeddings for ${_knowledgeBase.length} docs...');
    final List<List<double>> allEmbeddings = [];

    // Process in batches of 20 (API limit)
    const int batchSize = 20;
    for (int i = 0; i < _knowledgeBase.length; i += batchSize) {
      final batch = _knowledgeBase.sublist(
        i,
        min(i + batchSize, _knowledgeBase.length),
      );

      final List<Map<String, dynamic>> requests = batch.map((doc) {
        final text = '${doc['title'] ?? ''}: ${doc['content'] ?? ''}';
        return {
          'model': 'models/text-embedding-004',
          'content': {
            'parts': [
              {'text': text}
            ]
          },
          'taskType': 'RETRIEVAL_DOCUMENT',
        };
      }).toList();

      try {
        final response = await http.post(
          Uri.parse('$_batchEmbeddingEndpoint?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'requests': requests}),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final embeddings = json['embeddings'] as List<dynamic>;
          for (final emb in embeddings) {
            final values = (emb['values'] as List<dynamic>)
                .map((v) => (v as num).toDouble())
                .toList();
            allEmbeddings.add(values);
          }
        } else {
          print('⚠️ Embedding batch failed: ${response.statusCode}');
          print('   Body: ${response.body}');
          // Fill with empty embeddings for this batch
          for (int j = 0; j < batch.length; j++) {
            allEmbeddings.add([]);
          }
        }
      } catch (e) {
        print('⚠️ Embedding batch error: $e');
        for (int j = 0; j < batch.length; j++) {
          allEmbeddings.add([]);
        }
      }

      // Small delay to avoid rate limiting
      if (i + batchSize < _knowledgeBase.length) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    _docEmbeddings = allEmbeddings;
    final validCount = allEmbeddings.where((e) => e.isNotEmpty).length;
    print('✅ Embeddings computed: $validCount/${_knowledgeBase.length} docs');
  }

  /// Embed a user query for retrieval
  Future<List<double>> _embedQuery(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$_embeddingEndpoint?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'content': {
            'parts': [
              {'text': query}
            ]
          },
          'taskType': 'RETRIEVAL_QUERY',
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return (json['embedding']['values'] as List<dynamic>)
            .map((v) => (v as num).toDouble())
            .toList();
      }
    } catch (e) {
      print('⚠️ Query embedding error: $e');
    }
    return [];
  }

  /// Cosine similarity between two vectors
  static double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.0;
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denominator = sqrt(normA) * sqrt(normB);
    if (denominator == 0) return 0.0;
    return dotProduct / denominator;
  }

  /// Search knowledge base using vector similarity.
  /// Falls back to keyword search if embeddings unavailable.
  String searchAndFormat(String query) {
    if (!_isLoaded || _knowledgeBase.isEmpty) return '';

    // If embeddings are ready, use them (async result cached)
    // Since searchAndFormat is sync, we check if we have embeddings
    if (_docEmbeddings.isNotEmpty && _docEmbeddings.any((e) => e.isNotEmpty)) {
      return _searchSync(query);
    }

    // Fallback: keyword search
    return _keywordSearch(query);
  }

  /// Async vector search — preferred method
  Future<String> searchAndFormatAsync(String query) async {
    if (!_isLoaded || _knowledgeBase.isEmpty) return '';

    if (_docEmbeddings.isNotEmpty && _docEmbeddings.any((e) => e.isNotEmpty)) {
      // Embed the query and search
      final queryEmbedding = await _embedQuery(query);
      if (queryEmbedding.isNotEmpty) {
        return _vectorSearch(queryEmbedding);
      }
    }

    // Fallback: keyword search
    return _keywordSearch(query);
  }

  /// Sync search using pre-computed query embeddings cache
  String _searchSync(String query) {
    // Use keyword search as sync fallback — vector search is async
    return _keywordSearch(query);
  }

  /// Vector similarity search — returns top-5 most relevant docs
  String _vectorSearch(List<double> queryEmbedding) {
    final List<MapEntry<int, double>> scored = [];

    for (int i = 0; i < _docEmbeddings.length; i++) {
      if (_docEmbeddings[i].isEmpty) continue;
      final similarity = _cosineSimilarity(queryEmbedding, _docEmbeddings[i]);
      scored.add(MapEntry(i, similarity));
    }

    if (scored.isEmpty) return '';

    // Sort by similarity descending, take top 5
    scored.sort((a, b) => b.value.compareTo(a.value));
    final topDocs = scored
        .take(5)
        .where((e) => e.value > 0.3) // Minimum similarity threshold
        .map((e) => _knowledgeBase[e.key])
        .toList();

    if (topDocs.isEmpty) return '';

    return _formatDocs(topDocs);
  }

  /// Keyword-based fallback search (original logic, improved)
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

  /// Format documents for RAG injection
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
