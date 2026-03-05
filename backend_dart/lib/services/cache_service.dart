import 'dart:io';

/// 🗄️ In-memory cache with TTL support.
///
/// Used to cache Firestore data (universities, knowledge base)
/// and avoid redundant API calls.
class CacheService {
  final Map<String, _CacheEntry<dynamic>> _cache = {};
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  /// Get a cached value by key. Returns null if not found or expired.
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) {
      _misses++;
      return null;
    }
    if (entry.isExpired) {
      _cache.remove(key);
      _evictions++;
      _misses++;
      return null;
    }
    _hits++;
    return entry.value as T;
  }

  /// Store a value in the cache with a TTL duration.
  void set<T>(String key, T value, Duration ttl) {
    _cache[key] = _CacheEntry<T>(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  /// Invalidate a specific cache key.
  void invalidate(String key) {
    if (_cache.remove(key) != null) {
      _evictions++;
    }
  }

  /// Invalidate all cache entries.
  void invalidateAll() {
    _evictions += _cache.length;
    _cache.clear();
  }

  /// Remove all expired entries (manual cleanup).
  int cleanup() {
    final expiredKeys = _cache.entries
        .where((e) => e.value.isExpired)
        .map((e) => e.key)
        .toList();
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
    _evictions += expiredKeys.length;
    return expiredKeys.length;
  }

  /// Get cache statistics for monitoring.
  Map<String, dynamic> stats() {
    // Clean up before reporting
    cleanup();
    final total = _hits + _misses;
    final hitRate =
        total > 0 ? (_hits / total * 100).toStringAsFixed(1) : '0.0';
    return {
      'entries': _cache.length,
      'hits': _hits,
      'misses': _misses,
      'evictions': _evictions,
      'hit_rate_percent': hitRate,
      'keys': _cache.keys.toList(),
    };
  }

  /// Log cache stats to stderr for debugging.
  void logStats() {
    final s = stats();
    stderr.writeln(
        '📦 Cache: ${s['entries']} entries, ${s['hit_rate_percent']}% hit rate '
        '(${s['hits']} hits / ${s['misses']} misses)');
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiresAt;

  _CacheEntry({required this.value, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
