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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return StreamBuilder(
      stream: _comparisonService.getComparisonStream(),
      builder: (context, snapshot) {
        return FutureBuilder<List<University>>(
          future: _comparisonService.getComparisonUniversities(),
          builder: (context, uniSnapshot) {
            final universities = uniSnapshot.data ?? [];
            final isLoading =
                uniSnapshot.connectionState == ConnectionState.waiting;

            return Scaffold(
              appBar: AppBar(
                title: Text(l10n?.comparisonTitle ?? 'Comparison'),
                actions: [
                  if (universities.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep),
                      onPressed: () => _comparisonService.clearComparison(),
                    ),
                ],
              ),
              body: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : universities.isEmpty
                  ? Center(
                      child: Text(l10n?.comparisonEmpty ?? 'List is empty'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: universities.length,
                      itemBuilder: (context, index) {
                        return _buildUniRow(universities[index]);
                      },
                    ),
            );
          },
        );
      },
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
          onPressed: () => _comparisonService.removeFromComparison(uni.id),
        ),
      ),
    );
  }
}
