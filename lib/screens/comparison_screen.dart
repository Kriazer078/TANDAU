import 'package:flutter/material.dart';
import '../models/university.dart';
import '../services/comparison_service.dart';
import '../l10n/app_localizations.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final ComparisonService _comparisonService = ComparisonService();
  List<University> _universities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComparison();
  }

  Future<void> _loadComparison() async {
    setState(() => _isLoading = true);
    final universities = await _comparisonService.getComparisonUniversities();
    setState(() {
      _universities = universities;
      _isLoading = false;
    });
  }

  Future<void> _removeUniversity(String universityId) async {
    await _comparisonService.removeFromComparison(universityId);
    await _loadComparison();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.comparisonTitle ?? 'Comparison'),
        actions: [
          if (_universities.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () async {
                await _comparisonService.clearComparison();
                _loadComparison();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _universities.isEmpty
          ? Center(child: Text(l10n?.comparisonEmpty ?? 'List is empty'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [..._universities.map((uni) => _buildUniRow(uni))],
            ),
    );
  }

  Widget _buildUniRow(University uni) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          uni.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${uni.city} • ${uni.tuitionRange}'),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: () => _removeUniversity(uni.id),
        ),
      ),
    );
  }
}
