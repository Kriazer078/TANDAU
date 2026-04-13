import 'dart:io';

/// 💰 Cost Tracking Service for Gemini API usage.
///
/// Tracks input/output tokens per request and calculates
/// estimated cost based on Gemini pricing.
class CostTrackerService {
  // ── Pricing: Gemini 2.0 Flash (April 2026) ──
  // https://ai.google.dev/pricing
  static const double inputPricePer1M = 0.075;  // $0.075 per 1M input tokens
  static const double outputPricePer1M = 0.30;  // $0.30  per 1M output tokens

  // ── Per-model pricing overrides ──
  static const Map<String, List<double>> _modelPricing = {
    'gemini-2.5-flash':      [0.075, 0.30],
    'gemini-2.5-pro':        [3.50, 10.50],
    'gemini-2.5-flash-lite': [0.035, 0.15],
    'gemini-2.0-flash':      [0.075, 0.30],
  };




  // ── Aggregate counters ──
  int _totalInputTokens = 0;
  int _totalOutputTokens = 0;
  int _totalRequests = 0;
  double _totalCostUsd = 0.0;
  DateTime _trackingSince = DateTime.now().toUtc();

  // ── Per-endpoint breakdown ──
  final Map<String, _EndpointCost> _byEndpoint = {};

  // ── Daily breakdown ──
  final Map<String, _DailyCost> _byDay = {};

  /// Track a single API call's token usage.
  void trackUsage({
    required String endpoint,
    required int inputTokens,
    required int outputTokens,
  }) {
    final cost = _calculateCost(inputTokens, outputTokens);

    _totalInputTokens += inputTokens;
    _totalOutputTokens += outputTokens;
    _totalRequests++;
    _totalCostUsd += cost;

    // Per-endpoint
    final ep = _byEndpoint.putIfAbsent(
        endpoint, () => _EndpointCost(endpoint: endpoint));
    ep.inputTokens += inputTokens;
    ep.outputTokens += outputTokens;
    ep.requests++;
    ep.costUsd += cost;

    // Daily
    final today = _todayKey();
    final day = _byDay.putIfAbsent(today, () => _DailyCost(date: today));
    day.inputTokens += inputTokens;
    day.outputTokens += outputTokens;
    day.requests++;
    day.costUsd += cost;

    stderr.writeln('💰 Cost: +$inputTokens in / +$outputTokens out = '
        '\$${cost.toStringAsFixed(6)} ($endpoint)');
  }

  /// Calculate cost in USD for given token counts + model override.
  double _calculateCost(int inputTokens, int outputTokens, [String? model]) {
    final pricing = (model != null ? _modelPricing[model] : null);
    final inRate  = pricing?[0] ?? inputPricePer1M;
    final outRate = pricing?[1] ?? outputPricePer1M;
    return (inputTokens / 1000000.0) * inRate +
        (outputTokens / 1000000.0) * outRate;
  }

  /// Get the estimated cost for a specific request (without tracking).
  double estimateCost(int inputTokens, int outputTokens) {
    return _calculateCost(inputTokens, outputTokens);
  }

  /// Get comprehensive stats for admin endpoint.
  Map<String, dynamic> getStats() {
    return {
      'tracking_since': _trackingSince.toIso8601String(),
      'total': {
        'requests': _totalRequests,
        'input_tokens': _totalInputTokens,
        'output_tokens': _totalOutputTokens,
        'total_tokens': _totalInputTokens + _totalOutputTokens,
        'cost_usd': double.parse(_totalCostUsd.toStringAsFixed(6)),
        'cost_formatted': '\$${_totalCostUsd.toStringAsFixed(4)}',
      },
      'pricing': {
        'model': 'Gemini 2.0 Flash',
        'input_per_1M': '\$$inputPricePer1M',
        'output_per_1M': '\$$outputPricePer1M',
      },
      'by_endpoint': _byEndpoint.values
          .map((ep) => {
                'endpoint': ep.endpoint,
                'requests': ep.requests,
                'input_tokens': ep.inputTokens,
                'output_tokens': ep.outputTokens,
                'cost_usd': double.parse(ep.costUsd.toStringAsFixed(6)),
              })
          .toList(),
      'by_day': _byDay.values
          .map((day) => {
                'date': day.date,
                'requests': day.requests,
                'input_tokens': day.inputTokens,
                'output_tokens': day.outputTokens,
                'cost_usd': double.parse(day.costUsd.toStringAsFixed(6)),
              })
          .toList()
        ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String)),
      'averages': _totalRequests > 0
          ? {
              'tokens_per_request':
                  ((_totalInputTokens + _totalOutputTokens) / _totalRequests)
                      .round(),
              'cost_per_request_usd': double.parse(
                  (_totalCostUsd / _totalRequests).toStringAsFixed(6)),
              'estimated_daily_cost_usd': _estimateDailyCost(),
            }
          : null,
    };
  }

  /// Estimate daily cost based on current usage rate.
  String _estimateDailyCost() {
    final elapsed = DateTime.now().toUtc().difference(_trackingSince).inMinutes;
    if (elapsed <= 0) return '\$0.00';
    final rate = _totalCostUsd / elapsed; // cost per minute
    final daily = rate * 60 * 24;
    return '\$${daily.toStringAsFixed(4)}';
  }

  String _todayKey() {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Reset all counters (for testing or manual reset).
  void reset() {
    _totalInputTokens = 0;
    _totalOutputTokens = 0;
    _totalRequests = 0;
    _totalCostUsd = 0.0;
    _byEndpoint.clear();
    _byDay.clear();
    _trackingSince = DateTime.now().toUtc();
  }
}

class _EndpointCost {
  final String endpoint;
  int inputTokens = 0;
  int outputTokens = 0;
  int requests = 0;
  double costUsd = 0.0;

  _EndpointCost({required this.endpoint});
}

class _DailyCost {
  final String date;
  int inputTokens = 0;
  int outputTokens = 0;
  int requests = 0;
  double costUsd = 0.0;

  _DailyCost({required this.date});
}
