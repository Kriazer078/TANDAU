import 'package:flutter/material.dart';
import '../models/university.dart';
import '../services/university_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import 'moderator_edit_university_screen.dart';

/// Модераторская панель управления ВУЗами.
/// Доступна только для admin и moderator.
class ModeratorUniversitiesScreen extends StatefulWidget {
  const ModeratorUniversitiesScreen({super.key});

  @override
  State<ModeratorUniversitiesScreen> createState() =>
      _ModeratorUniversitiesScreenState();
}

class _ModeratorUniversitiesScreenState
    extends State<ModeratorUniversitiesScreen> {
  final UniversityService _universityService = UniversityService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<University> _universities = [];
  List<University> _filtered = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUniversities();
    _searchController.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUniversities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _universityService.getAllUniversities(
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _universities = list;
        _applySearch();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applySearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = List.from(_universities);
      } else {
        _filtered = _universities
            .where((u) =>
                u.name.toLowerCase().contains(query) ||
                u.city.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _deleteUniversity(University uni) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.moderatorDeleteConfirm ?? 'Удалить ВУЗ?'),
        content: Text(
          '${uni.name}\n\nЭто действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final success = await _universityService.deleteUniversity(uni.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${uni.name} удалён'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadUniversities();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка удаления'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _openEditor({University? university}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ModeratorEditUniversityScreen(university: university),
      ),
    );
    if (result == true) {
      _loadUniversities();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    // 🔒 Проверка доступа
    if (!_authService.canManageUniversities) {
      return Scaffold(
        appBar: AppBar(title: const Text('Доступ запрещён')),
        body: const Center(child: Text('У вас нет доступа к этому разделу')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(l10n?.moderatorTitle ?? 'Управление ВУЗами'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadUniversities,
            tooltip: 'Обновить',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n?.moderatorAddUni ?? 'Добавить ВУЗ'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 🔍 Поиск
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по названию или городу...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.cardDark : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // 📊 Счётчик
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.school_rounded,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Всего: ${_filtered.length}',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // 📋 Список
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(_error!,
                                textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadUniversities,
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : _filtered.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isNotEmpty
                                  ? 'Ничего не найдено'
                                  : 'Нет университетов',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUniversities,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 4, 16, 100),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final uni = _filtered[index];
                                return _buildUniversityCard(uni, isDark);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildUniversityCard(University uni, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.border.withValues(alpha: 0.5),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            uni.name.isNotEmpty ? uni.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          uni.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(uni.city,
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 12),
              const Icon(Icons.people_alt_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('${uni.studentCount}',
                  style: const TextStyle(fontSize: 12)),
              if (uni.hasDormitory) ...[
                const SizedBox(width: 8),
                const Icon(Icons.night_shelter_rounded,
                    size: 14, color: AppColors.success),
              ],
              if (uni.hasMilitaryDepartment) ...[
                const SizedBox(width: 8),
                const Icon(Icons.shield_rounded,
                    size: 14, color: AppColors.gold),
              ],
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _openEditor(university: uni);
            } else if (value == 'delete') {
              _deleteUniversity(uni);
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)?.moderatorEditUni ??
                      'Редактировать'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_rounded,
                      size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  const Text('Удалить'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _openEditor(university: uni),
      ),
    );
  }
}
