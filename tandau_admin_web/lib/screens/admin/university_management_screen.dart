import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;

import '../../services/firestore_service.dart';
import '../../services/university_service.dart';
import '../../services/auth_service.dart';
import '../../models/university.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import 'university_editor_screen.dart';

class UniversityManagementScreen extends StatefulWidget {
  const UniversityManagementScreen({super.key});

  @override
  State<UniversityManagementScreen> createState() => _UniversityManagementScreenState();
}

class _UniversityManagementScreenState extends State<UniversityManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isImporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── CSV & Excel Import Logic (Full Overwrite) ─────────────────────────
  Future<void> _pickAndImportCsv() async {
    // Only Admin can import
    if (!AuthService().isAdmin) {
      _showSnack('❌ Только администратор может импортировать данные', AppColors.error);
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    
    // Show confirmation dialog for full overwrite
    final confirm = await _showConfirmationDialog(
      title: 'Полная перезапись каталога?',
      content: 'Все текущие данные ВУЗов будут УДАЛЕНЫ. Это действие невозможно отменить.',
      confirmText: 'ДА, ПЕРЕЗАПИСАТЬ',
      isDangerous: true,
    );

    if (confirm != true) return;

    setState(() => _isImporting = true);

    try {
      List<List<dynamic>> rows = [];

      if (file.extension?.toLowerCase() == 'csv') {
        // 1. Parse CSV (with allowMalformed to prevent crashes on non-utf8 encodings like Windows-1251)
        final csvString = utf8.decode(bytes, allowMalformed: true);
        rows = const CsvToListConverter().convert(csvString);
      } else {
        // 1. Parse Excel
        var excel = Excel.decodeBytes(bytes);
        var table = excel.tables[excel.tables.keys.first];
        if (table != null) {
          for (var row in table.rows) {
            final parsedRow = [];
            for (var cell in row) {
              if (cell == null) {
                parsedRow.add('');
              } else {
                dynamic v = cell.value;
                if (v == null) {
                  parsedRow.add('');
                } else {
                  try {
                    // handles excel: ^4.0.0 CellValue wrappers
                    parsedRow.add((v as dynamic).value.toString());
                  } catch (_) {
                    // handles older excel versions where value is primitive
                    parsedRow.add(v.toString());
                  }
                }
              }
            }
            rows.add(parsedRow);
          }
        }
      }

      if (rows.length < 2) throw 'Файл слишком короткий или пустой';

      // Assume first row is header
      final List<University> universities = [];
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 5) continue; // Skip malformed rows

        // Basic mapping logic (Example: id, name, city, logoUrl, majors_sep_by_semicolon...)
        universities.add(University(
          id: row[0].toString().trim(),
          name: row[1].toString().trim(),
          city: row[2].toString().trim(),
          logoUrl: row[3].toString().trim(),
          imageUrls: [],
          majors: row[4].toString().split(';').map((e) => e.trim()).toList(),
          passingScore: int.tryParse(row[5].toString()) ?? 0,
          tuitionRange: row.length > 6 ? row[6].toString() : '',
          hasDormitory: row.length > 7 ? row[7].toString().toLowerCase() == 'true' : false,
          hasGrants: row.length > 8 ? row[8].toString().toLowerCase() == 'true' : true,
          description: row.length > 9 ? row[9].toString() : '',
          requirements: [],
          applicationDeadline: '',
          address: '',
          website: '',
          studentCount: 0,
        ));
      }

      // 2. Wipe catalog
      await FirestoreService().deleteAllUniversities();

      // 3. Update Firestore
      final success = await UniversityService().migrateToFirestore(universities);
      
      if (success) {
        // 4. Sync metadata
        await FirestoreService().syncAggregationMetadata();
        _showSnack('✓ Импорт успешно завершен (${universities.length} ВУЗов)', AppColors.success);
      } else {
        throw 'Ошибка при сохранении в базу данных';
      }
    } catch (e) {
      _showSnack('❌ Ошибка импорта: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  // ── Wipe All Logic ───────────────────────────────────────────
  Future<void> _clearCatalog() async {
    final confirm = await _showConfirmationDialog(
      title: 'Очистить весь каталог ВУЗов?',
      content: 'Все записи об университетах и их специальностях будут удалены безвозвратно.',
      confirmText: 'УДАЛИТЬ ВСЕ',
      isDangerous: true,
    );

    if (confirm == true) {
      setState(() => _isImporting = true);
      final success = await FirestoreService().deleteAllUniversities();
      if (mounted) {
        setState(() => _isImporting = false);
        if (success) {
          _showSnack('✓ Каталог полностью очищен', AppColors.primary);
        } else {
          _showSnack('❌ Ошибка при очистке', AppColors.error);
        }
      }
    }
  }

  // ── UI Helpers ───────────────────────────────────────────────
  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isDangerous ? AppColors.error : AppColors.primary, width: 0.5)),
        title: Text(title, style: TextStyle(color: isDangerous ? AppColors.error : Colors.white, fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ОТМЕНА', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: isDangerous ? AppColors.error : AppColors.primary, foregroundColor: Colors.black),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isAdmin = AuthService().isAdmin;

    return Column(
      children: [
        // ── Header / Controls ──────────────────────────────────
        _buildHeader(isAdmin, isDark),

        // ── List ───────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<University>>(
            stream: FirestoreService().getUniversitiesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined, size: 64, color: isDark ? Colors.white24 : Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Каталог пуст', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 18)),
                      if (isAdmin) const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text('Используйте "Импорт CSV" для загрузки данных', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    ],
                  ),
                );
              }

              final filtered = snapshot.data!.where((u) => u.matchesSearch(_searchQuery)).toList();

              return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  mainAxisExtent: 180,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) => _buildUniversityCard(filtered[index], isDark),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isAdmin, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск ВУЗа по названию или городу...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white54 : Colors.black54),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.5))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary)),
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.05),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(width: 24),
          
          if (isAdmin) ...[
            // Wipe Button
            _actionButton(
              icon: Icons.delete_sweep_rounded,
              label: 'ОЧИСТИТЬ ВСЁ',
              color: AppColors.error,
              onTap: _clearCatalog,
            ),
            const SizedBox(width: 12),
            // Import Button
            _actionButton(
              icon: Icons.upload_file_rounded,
              label: _isImporting ? 'ЗАГРУЗКА...' : 'ИМПОРТ EXCEL/CSV',
              color: AppColors.success,
              onTap: _isImporting ? null : _pickAndImportCsv,
            ),
            const SizedBox(width: 12),
            // Add Button
            _actionButton(
              icon: Icons.add_rounded,
              label: 'ДОБАВИТЬ ВУЗ',
              color: AppColors.primary,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UniversityEditorScreen()),
                );
                if (result == true) setState(() {});
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          hoverColor: color.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUniversityCard(University uni, bool isDark) {
    return GlassCard(
      onTap: AuthService().isAdmin ? () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UniversityEditorScreen(university: uni)),
        );
        if (result == true) setState(() {});
      } : null,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: uni.logoUrl.isNotEmpty 
                      ? Image.network(uni.logoUrl, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.school, size: 40))
                      : const Icon(Icons.school, size: 40),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(uni.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(uni.city, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text('${uni.majors.length} специальностей', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
    );
  }
}
