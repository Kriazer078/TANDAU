import 'dart:io';
import 'dart:math';
import 'package:googleapis/firestore/v1.dart';

/// 🧪 A/B Prompt Testing Service.
///
/// Loads prompt variants from Firestore `prompt_config` collection
/// and distributes traffic based on weights.
class PromptConfigService {
  final FirestoreApi _firestoreApi;
  final String _projectId;
  final Random _random = Random();

  /// Loaded prompt configurations: `{ promptType → List<PromptVariant> }`
  final Map<String, List<PromptVariant>> _configs = {};

  /// Timestamp of last config load
  DateTime? _lastLoadTime;

  /// How often to refresh config (5 minutes)
  static const Duration _refreshInterval = Duration(minutes: 5);

  PromptConfigService(this._firestoreApi, this._projectId);

  /// Initialize: load all prompt configs from Firestore.
  Future<void> init() async {
    await _loadConfigs();
  }

  /// Get the active prompt variant for a given prompt type.
  /// Uses weighted random selection. Returns null if no config exists
  /// (in which case the default hardcoded prompt should be used).
  PromptVariant? getActiveVariant(String promptType) {
    // Auto-refresh if stale
    if (_lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!) > _refreshInterval) {
      _loadConfigs(); // Non-blocking refresh
    }

    final variants = _configs[promptType];
    if (variants == null || variants.isEmpty) return null;

    // If only one variant, return it
    if (variants.length == 1) return variants.first;

    // Weighted random selection
    final totalWeight = variants.fold<double>(0.0, (sum, v) => sum + v.weight);
    double roll = _random.nextDouble() * totalWeight;

    for (final variant in variants) {
      roll -= variant.weight;
      if (roll <= 0) return variant;
    }

    return variants.last; // Fallback
  }

  /// Get all loaded configs for admin inspection.
  Map<String, dynamic> getStats() {
    final result = <String, dynamic>{
      'last_loaded': _lastLoadTime?.toIso8601String(),
      'prompt_types': _configs.keys.toList(),
      'configs': {},
    };

    _configs.forEach((type, variants) {
      result['configs'] = {
        ...(result['configs'] as Map<String, dynamic>),
        type: variants
            .map((v) => {
                  'id': v.id,
                  'weight': v.weight,
                  'content_preview': v.content.length > 100
                      ? '${v.content.substring(0, 100)}...'
                      : v.content,
                })
            .toList(),
      };
    });

    return result;
  }

  /// Force refresh configs from Firestore.
  Future<void> refresh() async {
    await _loadConfigs();
  }

  /// Load prompt configs from Firestore `prompt_config` collection.
  Future<void> _loadConfigs() async {
    final parent = 'projects/$_projectId/databases/(default)/documents';
    try {
      final response = await _firestoreApi.projects.databases.documents
          .list(parent, 'prompt_config', pageSize: 50);

      if (response.documents == null || response.documents!.isEmpty) {
        stderr.writeln(
            '🧪 PromptConfig: No configs found in prompt_config collection');
        return;
      }

      _configs.clear();

      for (final doc in response.documents!) {
        final docId = doc.name!.split('/').last; // e.g. "chat_system_prompt"
        final fields = doc.fields;
        if (fields == null) continue;

        // Parse variants array
        final variantsValue = fields['variants'];
        if (variantsValue?.arrayValue?.values == null) continue;

        final variants = <PromptVariant>[];
        for (final item in variantsValue!.arrayValue!.values!) {
          if (item.mapValue?.fields == null) continue;
          final f = item.mapValue!.fields!;

          final id = f['id']?.stringValue ?? 'unknown';
          final weight = f['weight']?.doubleValue ??
              double.tryParse(f['weight']?.integerValue ?? '0') ??
              0.5;
          final content = f['content']?.stringValue ?? '';

          if (content.isNotEmpty) {
            variants.add(PromptVariant(
              id: id,
              content: content,
              weight: weight,
            ));
          }
        }

        if (variants.isNotEmpty) {
          _configs[docId] = variants;
          stderr.writeln(
              '🧪 PromptConfig: Loaded "$docId" with ${variants.length} variants');
        }
      }

      _lastLoadTime = DateTime.now();
      stderr
          .writeln('🧪 PromptConfig: Loaded ${_configs.length} prompt type(s)');
    } catch (e) {
      stderr.writeln('⚠️ PromptConfig: Failed to load configs: $e');
      // Keep existing configs if load fails
    }
  }
}

/// A single prompt variant with ID, content, and traffic weight.
class PromptVariant {
  final String id;
  final String content;
  final double weight;

  PromptVariant({
    required this.id,
    required this.content,
    required this.weight,
  });
}
