import 'dart:io';
import 'package:googleapis/firestore/v1.dart';

/// 📊 Asynchronous AI interaction logger.
///
/// Logs AI interactions to Firestore `ai_logs` collection
/// for analytics (top questions, error rate, latency).
/// All data is logged **anonymously** (no UID).
class AILoggerService {
  final FirestoreApi _firestoreApi;
  final String _projectId;

  /// In-memory buffer for batch writing
  final List<Map<String, dynamic>> _buffer = [];
  static const int _batchSize = 10;
  bool _isFlushing = false;

  AILoggerService(this._firestoreApi, this._projectId);

  /// Log an AI interaction (fire-and-forget, never throws).
  void logInteraction({
    required String endpoint,
    required String question,
    String? intent,
    int? responseLengthChars,
    int? latencyMs,
    bool success = true,
    String? errorMessage,
    String? promptVariant,
    int? inputTokens,
    int? outputTokens,
    double? costUsd,
  }) {
    try {
      final entry = <String, dynamic>{
        'endpoint': endpoint,
        'question': _truncate(question, 500), // Limit stored question length
        'intent': intent,
        'response_length': responseLengthChars,
        'latency_ms': latencyMs,
        'success': success,
        'prompt_variant': promptVariant,
        'input_tokens': inputTokens,
        'output_tokens': outputTokens,
        'cost_usd': costUsd,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

      // Remove null values
      entry.removeWhere((key, value) => value == null);

      _buffer.add(entry);

      // Auto-flush when buffer is full
      if (_buffer.length >= _batchSize) {
        _flush();
      }
    } catch (e) {
      stderr.writeln('⚠️ AILogger: Failed to buffer log: $e');
    }
  }

  /// Flush buffered logs to Firestore (fire-and-forget).
  Future<void> _flush() async {
    if (_isFlushing || _buffer.isEmpty) return;
    _isFlushing = true;

    final batch = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();

    try {
      for (final entry in batch) {
        await _writeToFirestore(entry);
      }
      stderr.writeln('📊 AILogger: Flushed ${batch.length} logs to Firestore');
    } catch (e) {
      stderr.writeln('⚠️ AILogger: Flush failed: $e');
      // Don't re-add to buffer to avoid infinite loop
    } finally {
      _isFlushing = false;
    }
  }

  /// Force flush remaining buffered logs.
  Future<void> forceFlush() async {
    if (_buffer.isEmpty) return;
    _isFlushing = false; // Reset lock to allow flush
    await _flush();
  }

  /// Write a single log entry to Firestore `ai_logs` collection.
  Future<void> _writeToFirestore(Map<String, dynamic> entry) async {
    final parent = 'projects/$_projectId/databases/(default)/documents';
    try {
      final fields = <String, Value>{};

      entry.forEach((key, val) {
        if (val is String) {
          fields[key] = Value(stringValue: val);
        } else if (val is int) {
          fields[key] = Value(integerValue: val.toString());
        } else if (val is bool) {
          fields[key] = Value(booleanValue: val);
        } else if (val is double) {
          fields[key] = Value(doubleValue: val);
        }
      });

      final document = Document(fields: fields);
      await _firestoreApi.projects.databases.documents
          .createDocument(document, parent, 'ai_logs');
    } catch (e) {
      stderr.writeln('⚠️ AILogger: Firestore write failed: $e');
    }
  }

  /// Truncate string to maxLength.
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
