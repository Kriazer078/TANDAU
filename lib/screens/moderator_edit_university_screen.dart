import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/university.dart';
import '../services/university_service.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

/// Экран добавления/редактирования ВУЗа для модераторов.
class ModeratorEditUniversityScreen extends StatefulWidget {
  /// Если null — создание нового ВУЗа, иначе редактирование.
  final University? university;

  const ModeratorEditUniversityScreen({super.key, this.university});
  

  @override
  State<ModeratorEditUniversityScreen> createState() =>
      _ModeratorEditUniversityScreenState();
}

class _ModeratorEditUniversityScreenState
    extends State<ModeratorEditUniversityScreen> {
  final _formKey = GlobalKey<FormState>();
  final UniversityService _universityService = UniversityService();
  bool _isSaving = false;

  bool get _isEditing => widget.university != null;

  // Контроллеры — Секция 1: Основная информация
  late final TextEditingController _nameCtl;
  late final TextEditingController _cityCtl;
  late final TextEditingController _studentCountCtl;
  late final TextEditingController _descriptionCtl;

  // Секция 2: Финансы и Поступление
  late final TextEditingController _passingScoreCtl;
  late final TextEditingController _tuitionRangeCtl;
  late final TextEditingController _applicationDeadlineCtl;
  bool _hasGrants = false;

  // Секция 3: Инфраструктура
  bool _hasDormitory = false;
  late final TextEditingController _dormitoryPriceCtl;
  bool _hasMilitaryDepartment = false;
  late final TextEditingController _militaryStartCourseCtl;
  late final TextEditingController _militaryCompetitionCtl;
  bool _dormitoryForFreshmen = false;
  late final TextEditingController _dormitoryPriceYearCtl;
  late final TextEditingController _dormitoryDistanceCtl;
  late final TextEditingController _dormitoryDescriptionCtl;
  late final TextEditingController _dormitoryPhotosCtl;

  // Секция 4: Местоположение
  late final TextEditingController _addressCtl;
  late final TextEditingController _latitudeCtl;
  late final TextEditingController _longitudeCtl;

  // Секция 5: Контакты
  late final TextEditingController _contactPhoneCtl;
  late final TextEditingController _emailCtl;
  late final TextEditingController _websiteCtl;
  late final TextEditingController _logoUrlCtl;

  // Секция 6: Специальности
  late final TextEditingController _majorsCtl;

  @override
  void initState() {
    super.initState();
    final u = widget.university;

    _nameCtl = TextEditingController(text: u?.name ?? '');
    _cityCtl = TextEditingController(text: u?.city ?? '');
    _studentCountCtl =
        TextEditingController(text: u?.studentCount.toString() ?? '0');
    _descriptionCtl = TextEditingController(text: u?.description ?? '');

    _passingScoreCtl =
        TextEditingController(text: u?.passingScore.toString() ?? '0');
    _tuitionRangeCtl = TextEditingController(text: u?.tuitionRange ?? '');
    _applicationDeadlineCtl =
        TextEditingController(text: u?.applicationDeadline ?? '');
    _hasGrants = u?.hasGrants ?? false;

    _hasDormitory = u?.hasDormitory ?? false;
    _dormitoryPriceCtl =
        TextEditingController(text: u?.dormitoryPrice?.toString() ?? '');
    _hasMilitaryDepartment = u?.hasMilitaryDepartment ?? false;
    _militaryStartCourseCtl = TextEditingController(
        text: u?.militaryStartCourse?.toString() ?? '');
    _militaryCompetitionCtl =
        TextEditingController(text: u?.militaryCompetition ?? '');
    _dormitoryForFreshmen = u?.dormitoryForFreshmen ?? false;
    _dormitoryPriceYearCtl =
        TextEditingController(text: u?.dormitoryPriceYear?.toString() ?? '');
    _dormitoryDistanceCtl =
        TextEditingController(text: u?.dormitoryDistanceInfo ?? '');
    _dormitoryDescriptionCtl =
        TextEditingController(text: u?.dormitoryDescription ?? '');
    _dormitoryPhotosCtl =
        TextEditingController(text: u?.dormitoryPhotoUrls.join(', ') ?? '');

    _addressCtl = TextEditingController(text: u?.address ?? '');
    _latitudeCtl =
        TextEditingController(text: u?.latitude?.toString() ?? '');
    _longitudeCtl =
        TextEditingController(text: u?.longitude?.toString() ?? '');

    _contactPhoneCtl = TextEditingController(text: u?.contactPhone ?? '');
    _emailCtl = TextEditingController(text: u?.email ?? '');
    _websiteCtl = TextEditingController(text: u?.website ?? '');
    _logoUrlCtl = TextEditingController(text: u?.logoUrl ?? '');

    _majorsCtl =
        TextEditingController(text: u?.majors.join(', ') ?? '');
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _cityCtl.dispose();
    _studentCountCtl.dispose();
    _descriptionCtl.dispose();
    _passingScoreCtl.dispose();
    _tuitionRangeCtl.dispose();
    _applicationDeadlineCtl.dispose();
    _dormitoryPriceCtl.dispose();
    _addressCtl.dispose();
    _latitudeCtl.dispose();
    _longitudeCtl.dispose();
    _contactPhoneCtl.dispose();
    _emailCtl.dispose();
    _websiteCtl.dispose();
    _logoUrlCtl.dispose();
    _majorsCtl.dispose();
    _dormitoryPriceYearCtl.dispose();
    _dormitoryDistanceCtl.dispose();
    _dormitoryDescriptionCtl.dispose();
    _dormitoryPhotosCtl.dispose();
    _militaryStartCourseCtl.dispose();
    _militaryCompetitionCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final majors = _majorsCtl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final university = University(
        id: widget.university?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameCtl.text.trim(),
        city: _cityCtl.text.trim(),
        logoUrl: _logoUrlCtl.text.trim(),
        imageUrls: widget.university?.imageUrls ?? [],
        majors: majors,
        passingScore: int.tryParse(_passingScoreCtl.text) ?? 0,
        tuitionRange: _tuitionRangeCtl.text.trim(),
        hasDormitory: _hasDormitory,
        dormitoryPrice: _hasDormitory
            ? int.tryParse(_dormitoryPriceCtl.text)
            : null,
        dormitoryForFreshmen: _hasDormitory && _dormitoryForFreshmen,
        dormitoryPriceYear: _hasDormitory
            ? int.tryParse(_dormitoryPriceYearCtl.text)
            : null,
        dormitoryPhotoUrls: _hasDormitory
            ? _dormitoryPhotosCtl.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList()
            : [],
        dormitoryDistanceInfo: _hasDormitory
            ? _dormitoryDistanceCtl.text.trim()
            : null,
        dormitoryDescription: _hasDormitory
            ? _dormitoryDescriptionCtl.text.trim()
            : null,
        hasGrants: _hasGrants,
        hasMilitaryDepartment: _hasMilitaryDepartment,
        militaryStartCourse: _hasMilitaryDepartment
            ? int.tryParse(_militaryStartCourseCtl.text)
            : null,
        militaryCompetition: _hasMilitaryDepartment
            ? _militaryCompetitionCtl.text.trim()
            : null,
        latitude: double.tryParse(_latitudeCtl.text),
        longitude: double.tryParse(_longitudeCtl.text),
        description: _descriptionCtl.text.trim(),
        requirements: widget.university?.requirements ?? [],
        applicationDeadline: _applicationDeadlineCtl.text.trim(),
        address: _addressCtl.text.trim(),
        website: _websiteCtl.text.trim(),
        studentCount: int.tryParse(_studentCountCtl.text) ?? 0,
        contactPhone: _contactPhoneCtl.text.trim(),
        email: _emailCtl.text.trim(),
        specialtyCodes: widget.university?.specialtyCodes ?? [],
        likesCount: widget.university?.likesCount ?? 0,
        reviewsCount: widget.university?.reviewsCount ?? 0,
        averageRating: widget.university?.averageRating ?? 0.0,
      );

      bool success;
      if (_isEditing) {
        success = await _universityService.updateUniversity(university);
      } else {
        success = await _universityService.addUniversity(university);
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'ВУЗ обновлён ✅' : 'ВУЗ добавлен ✅'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка сохранения'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Save university error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing
            ? (l10n?.moderatorEditUni ?? 'Редактировать ВУЗ')
            : (l10n?.moderatorAddUni ?? 'Добавить ВУЗ')),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save_rounded),
              onPressed: _save,
              tooltip: 'Сохранить',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ═══ Секция 1: Основная информация ═══
            _buildSectionHeader(
              '📋 ${l10n?.moderatorSectionBasic ?? 'Основная информация'}',
              isDark,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nameCtl,
              label: 'Название ВУЗа *',
              icon: Icons.school_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _cityCtl,
                    label: 'Город *',
                    icon: Icons.location_city_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Обязательное поле'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _studentCountCtl,
                    label: 'Студентов',
                    icon: Icons.people_alt_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _descriptionCtl,
              label: 'Описание',
              icon: Icons.description_rounded,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _logoUrlCtl,
              label: 'URL логотипа',
              icon: Icons.image_rounded,
              keyboardType: TextInputType.url,
            ),

            const SizedBox(height: 24),

            // ═══ Секция 2: Финансы и Поступление ═══
            _buildSectionHeader(
              '💰 ${l10n?.moderatorSectionFinance ?? 'Финансы и Поступление'}',
              isDark,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _passingScoreCtl,
                    label: 'Проходной балл',
                    icon: Icons.grade_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _tuitionRangeCtl,
                    label: 'Стоимость обучения',
                    icon: Icons.attach_money_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _applicationDeadlineCtl,
              label: 'Дедлайн подачи',
              icon: Icons.calendar_today_rounded,
            ),
            const SizedBox(height: 8),
            _buildSwitchTile(
              'Гранты',
              Icons.star_rounded,
              _hasGrants,
              (v) => setState(() => _hasGrants = v),
              isDark,
            ),

            const SizedBox(height: 24),

            // ═══ Секция 3: Инфраструктура ═══
            _buildSectionHeader(
              '🏗️ ${l10n?.moderatorSectionInfra ?? 'Инфраструктура'}',
              isDark,
            ),
            const SizedBox(height: 12),
            _buildSwitchTile(
              l10n?.dormitory ?? 'Общежитие',
              Icons.night_shelter_rounded,
              _hasDormitory,
              (v) => setState(() => _hasDormitory = v),
              isDark,
            ),
            if (_hasDormitory) ...[
              const SizedBox(height: 8),
              _buildTextField(
                controller: _dormitoryPriceCtl,
                label: '${l10n?.dormitoryPrice ?? 'Цена общежития'} (₸/мес)',
                icon: Icons.payments_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 8),
              _buildSwitchTile(
                l10n?.dormitoryForFreshmen ?? '100% первокурсникам',
                Icons.verified_rounded,
                _dormitoryForFreshmen,
                (v) => setState(() => _dormitoryForFreshmen = v),
                isDark,
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _dormitoryPriceYearCtl,
                label: '${l10n?.dormitoryPriceYear ?? 'Стоимость за год'} (₸)',
                icon: Icons.calendar_month_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _dormitoryDistanceCtl,
                label: l10n?.dormitoryDistance ?? 'Расстояние до корпусов',
                icon: Icons.directions_walk_rounded,
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _dormitoryDescriptionCtl,
                label: l10n?.dormitoryConditions ?? 'Условия проживания',
                icon: Icons.info_outline_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _dormitoryPhotosCtl,
                label: '${l10n?.dormitoryPhotos ?? 'Фото комнат'} (URL через запятую)',
                icon: Icons.photo_library_rounded,
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 8),
            _buildSwitchTile(
              l10n?.militaryDepartment ?? 'Военная кафедра',
              Icons.shield_rounded,
              _hasMilitaryDepartment,
              (v) => setState(() => _hasMilitaryDepartment = v),
              isDark,
            ),
            if (_hasMilitaryDepartment) ...[
              const SizedBox(height: 8),
              _buildTextField(
                controller: _militaryStartCourseCtl,
                label: 'С какого курса (1-4)',
                icon: Icons.school_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _militaryCompetitionCtl,
                label: 'Конкурс (напр. 3 чел/место)',
                icon: Icons.people_rounded,
              ),
            ],

            const SizedBox(height: 24),

            // ═══ Секция 4: Местоположение ═══
            _buildSectionHeader(
              '📍 ${l10n?.location ?? 'Местоположение'}',
              isDark,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressCtl,
              label: 'Адрес',
              icon: Icons.place_rounded,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _latitudeCtl,
                    label: 'Широта',
                    icon: Icons.explore_rounded,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _longitudeCtl,
                    label: 'Долгота',
                    icon: Icons.explore_rounded,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ═══ Секция 5: Контакты ═══
            _buildSectionHeader('📞 Контакты', isDark),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _contactPhoneCtl,
              label: 'Телефон',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emailCtl,
              label: 'Email',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _websiteCtl,
              label: 'Веб-сайт',
              icon: Icons.language_rounded,
              keyboardType: TextInputType.url,
            ),

            const SizedBox(height: 24),

            // ═══ Секция 6: Специальности ═══
            _buildSectionHeader('🎓 Специальности', isDark),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _majorsCtl,
              label: 'Специальности (через запятую)',
              icon: Icons.list_alt_rounded,
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // ═══ Кнопка сохранения ═══
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isSaving ? 'Сохранение...' : 'Сохранить',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: isDark ? AppColors.cardDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.3),
        ),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 15)),
          ],
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
