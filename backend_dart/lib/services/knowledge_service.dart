import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';

/// Service that searches the knowledge base using vector embeddings
/// for semantic similarity (RAG pipeline with OpenAI Embeddings).
class KnowledgeService {
  final FirebaseService _firebaseService;
  final String _apiKey;

  /// Cached knowledge base documents
  List<Map<String, dynamic>> _knowledgeBase = [];

  /// Pre-computed embeddings for each document (parallel index)
  List<List<double>> _docEmbeddings = [];

  bool _isLoaded = false;
  bool get isInitialized => _isLoaded;

  /// OpenAI Embedding model endpoint
  static const String _embeddingEndpoint = 'https://api.openai.com/v1/embeddings';
  static const String _model = 'text-embedding-3-small';

  KnowledgeService(this._firebaseService, this._apiKey);

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

      if (_apiKey.isNotEmpty && !_apiKey.startsWith('REPLACE')) {
        await _computeEmbeddings();
      } else {
        stderr.writeln('⚠️ No API key — falling back to keyword search');
      }

      _isLoaded = true;
    } catch (e) {
      stderr.writeln('⚠️ Failed to load Knowledge Base: $e');
      _knowledgeBase = [];
    }
  }

  /// Generate embeddings for all KB documents in batches
  Future<void> _computeEmbeddings() async {
    stderr.writeln('🧮 Checking embeddings for ${_knowledgeBase.length} docs (OpenAI)...');
    final List<List<double>> allEmbeddings = List.filled(_knowledgeBase.length, []);

    // 1. Extract already computed embeddings from database
    List<int> missingIndices = [];
    for (int i = 0; i < _knowledgeBase.length; i++) {
      final doc = _knowledgeBase[i];
      // Note: If we switched from Gemini to OpenAI, existing embeddings in Firestore might be the wrong size/model.
      // We should probably check the dimension or have a model version flag.
      // OpenAI text-embedding-3-small is 1536 dims. Gemini is 768.
      if (doc['embedding'] != null && doc['embedding'] is List && (doc['embedding'] as List).length == 1536) {
        allEmbeddings[i] = (doc['embedding'] as List).map((e) => (e as num).toDouble()).toList();
      } else {
        missingIndices.add(i);
      }
    }

    if (missingIndices.isEmpty) {
      _docEmbeddings = allEmbeddings;
      stderr.writeln('✅ All embeddings loaded from database (${allEmbeddings.length} docs)');
      return;
    }

    stderr.writeln('🧮 Computing missing embeddings for ${missingIndices.length} docs with OpenAI...');

    // 2. Process missing ones in batches of 20
    const int batchSize = 20;
    for (int i = 0; i < missingIndices.length; i += batchSize) {
      final batchIndices = missingIndices.sublist(
        i,
        min(i + batchSize, missingIndices.length),
      );

      final List<String> inputs = batchIndices.map((idx) {
        final doc = _knowledgeBase[idx];
        return '${doc['title'] ?? ''}: ${doc['content'] ?? ''}';
      }).toList();

      try {
        final response = await http.post(
          Uri.parse(_embeddingEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'input': inputs,
          }),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final data = json['data'] as List<dynamic>;
          for (int j = 0; j < data.length; j++) {
            final embData = data[j];
            final values = (embData['embedding'] as List<dynamic>)
                .map((v) => (v as num).toDouble())
                .toList();
            
            final idx = batchIndices[j];
            allEmbeddings[idx] = values;
            
            // 💾 Asynchronously save to Firestore to persist it
            final docId = _knowledgeBase[idx]['id'];
            if (docId != null) {
              _firebaseService.updateKnowledgeDocEmbedding(docId.toString(), values);
            }
          }
        } else {
          stderr.writeln('⚠️ OpenAI Embedding batch failed: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        stderr.writeln('⚠️ OpenAI Embedding batch error: $e');
      }

      if (i + batchSize < missingIndices.length) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    _docEmbeddings = allEmbeddings;
    final validCount = allEmbeddings.where((e) => e.isNotEmpty).length;
    stderr.writeln('✅ OpenAI Embeddings loaded/computed: $validCount/${_knowledgeBase.length} docs');
  }

  /// Embed a user query for retrieval
  Future<List<double>> _embedQuery(String query) async {
    try {
      final response = await http.post(
        Uri.parse(_embeddingEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'input': query,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return (json['data'][0]['embedding'] as List<dynamic>)
            .map((v) => (v as num).toDouble())
            .toList();
      }
    } catch (e) {
      stderr.writeln('⚠️ OpenAI Query embedding error: $e');
    }
    return [];
  }

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

  String searchAndFormat(String query) {
    if (!_isLoaded || _knowledgeBase.isEmpty) return '';
    if (_docEmbeddings.isNotEmpty && _docEmbeddings.any((e) => e.isNotEmpty)) {
      return _keywordSearch(query); // Sync fallback
    }
    return _keywordSearch(query);
  }

  Future<String> searchAndFormatAsync(String query) async {
    if (!_isLoaded || _knowledgeBase.isEmpty) return '';

    if (_docEmbeddings.isNotEmpty && _docEmbeddings.any((e) => e.isNotEmpty)) {
      final queryEmbedding = await _embedQuery(query);
      if (queryEmbedding.isNotEmpty) {
        return _vectorSearch(queryEmbedding);
      }
    }

    return _keywordSearch(query);
  }

  String _vectorSearch(List<double> queryEmbedding) {
    final List<MapEntry<int, double>> scored = [];

    for (int i = 0; i < _docEmbeddings.length; i++) {
      if (_docEmbeddings[i].isEmpty) continue;
      final similarity = _cosineSimilarity(queryEmbedding, _docEmbeddings[i]);
      scored.add(MapEntry(i, similarity));
    }

    if (scored.isEmpty) return '';

    scored.sort((a, b) => b.value.compareTo(a.value));
    final topDocs = scored
        .take(5)
        .where((e) => e.value > 0.4) // Threshold for OpenAI text-embedding-3-small
        .map((e) => _knowledgeBase[e.key])
        .toList();

    if (topDocs.isEmpty) return '';

    return _formatDocs(topDocs);
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
