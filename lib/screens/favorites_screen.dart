import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../models/university.dart';
import '../services/university_service.dart';
import '../widgets/university_card.dart';
import 'university_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final UniversityService _service = UniversityService();
  List<University> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _service.getFavoriteUniversities();
    setState(() {
      _favorites = favorites;
    });
  }

  Future<void> _toggleFavorite(String universityId) async {
    await _service.removeFromFavorites(universityId);
    await _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.favoritesSavedTitle ?? 'Saved'),
      ),
      body: _favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.favoritesEmptyTitle ??
                        'No saved universities',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.favoritesEmptySubtitle ??
                        'Save universities you like',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final university = _favorites[index];

                return UniversityCard(
                  universityId: university.id,
                  name: university.name,
                  city: university.city,
                  logoUrl: university.logoUrl,
                  features: [
                    if (university.hasDormitory)
                      l10n?.favoritesDormitory ?? 'Dormitory',
                    if (university.hasGrants)
                      l10n?.favoritesGrant ?? 'Grant',
                    '${university.rating} ⭐',
                  ],
                  isFavorite: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UniversityDetailScreen(university: university),
                      ),
                    );
                  },
                  onFavoriteToggle: () => _toggleFavorite(university.id),
                );
              },
            ),
    );
  }
}
