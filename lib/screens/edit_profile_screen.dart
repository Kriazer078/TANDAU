import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';
import '../utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../services/moderation_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _cityController;
  late TextEditingController _untScoreController;
  late TextEditingController _ieltsScoreController;
  late TextEditingController _gpaController;
  late TextEditingController _mathScoreController;

  String? _selectedCityDropdown;
  String? _selectedEducation;
  bool _isLoading = false;
  bool _hasChanges = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _initializeControllers();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _ageController = TextEditingController(text: widget.user.age ?? '');
    _cityController = TextEditingController(text: widget.user.city ?? '');
    _untScoreController = TextEditingController(
      text: widget.user.untScore?.toString() ?? '',
    );
    _ieltsScoreController = TextEditingController(
      text: widget.user.ieltsScore?.toString() ?? '',
    );
    _gpaController = TextEditingController(
      text: widget.user.gpa?.toString() ?? '',
    );
    _mathScoreController = TextEditingController(
      text: widget.user.mathScore?.toString() ?? '',
    );

    // Track changes
    _nameController.addListener(_markChanged);
    _ageController.addListener(_markChanged);
    _cityController.addListener(_markChanged);
    _untScoreController.addListener(_markChanged);
    _ieltsScoreController.addListener(_markChanged);
    _gpaController.addListener(_markChanged);
    _mathScoreController.addListener(_markChanged);

    // Initialize Education
    if (widget.user.education != null &&
        AppConstants.educationOptions.contains(widget.user.education)) {
      _selectedEducation = widget.user.education;
    }

    // Initialize City Dropdown Logic
    final city = widget.user.city;
    if (city != null && city.isNotEmpty) {
      if (AppConstants.cities.contains(city)) {
        _selectedCityDropdown = city;
      } else {
        _selectedCityDropdown = 'Другой';
      }
    }
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  /// How complete is the profile (0.0 – 1.0)
  double get _completionProgress {
    int filled = 0;
    int total = 7; // name, age, education, city, unt, ielts/gpa, mathScore
    if (_nameController.text.trim().isNotEmpty) filled++;
    if (_ageController.text.isNotEmpty) filled++;
    if (_selectedEducation != null) filled++;
    if (_cityController.text.trim().isNotEmpty) filled++;
    if (_untScoreController.text.trim().isNotEmpty) filled++;
    if (_gpaController.text.trim().isNotEmpty ||
        _ieltsScoreController.text.trim().isNotEmpty) {
      filled++;
    }
    if (_mathScoreController.text.trim().isNotEmpty) filled++;
    return filled / total;
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _untScoreController.dispose();
    _ieltsScoreController.dispose();
    _gpaController.dispose();
    _mathScoreController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (ModerationService().hasProfanity(_nameController.text.trim())) {
      _showError('Имя содержит недопустимые слова (мат/оскорбления).');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await AuthService().updateProfile(
        name: _nameController.text.trim(),
        age: _ageController.text.trim(),
        education: _selectedEducation,
        city: _cityController.text.trim(),
        untScore: int.tryParse(_untScoreController.text.trim()),
        ieltsScore: double.tryParse(_ieltsScoreController.text.trim()),
        gpa: double.tryParse(_gpaController.text.trim()),
        mathScore: int.tryParse(_mathScoreController.text.trim()),
      );

      if (mounted) {
        if (success) {
          _hasChanges = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)?.profileUpdated ??
                        'Профиль успешно обновлён',
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF22C55E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.pop(context);
        } else {
          _showError(
            AppLocalizations.of(context)?.profileErrorUpdate ??
                'Ошибка обновления профиля',
          );
        }
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber.shade700,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  'Несохранённые изменения',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Text(
            'У вас есть несохранённые изменения. '
            'Вы уверены, что хотите выйти?',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade700,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
              child: const Text('Остаться'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Выйти'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context)?.editProfileTitle ??
                  'Редактировать профиль',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              onPressed: () async {
                final shouldPop = await _onWillPop();
                if (shouldPop && context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          body: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                // ═══ Scrollable content ═══
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    physics: const BouncingScrollPhysics(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAvatarSection(isDark),
                          const SizedBox(height: 24),
                          _buildCompletionBar(isDark),
                          const SizedBox(height: 28),
                          _buildSectionHeader(
                            icon: Icons.person_outline,
                            title: 'Личные данные',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 14),
                          _buildPersonalFields(),
                          const SizedBox(height: 28),
                          _buildSectionHeader(
                            icon: Icons.location_on_outlined,
                            title:
                                AppLocalizations.of(context)?.profileCity ??
                                'Город',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 14),
                          _buildCityFields(),
                          const SizedBox(height: 28),
                          _buildSectionHeader(
                            icon: Icons.school_outlined,
                            title: 'Академические баллы',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 14),
                          _buildAcademicFields(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
                // ═══ Fixed Save Button at the bottom ═══
                _buildBottomSaveBar(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // COMPLETION BAR
  // ═══════════════════════════════════════════
  Widget _buildCompletionBar(bool isDark) {
    final progress = _completionProgress;
    final percent = (progress * 100).round();
    final Color barColor;
    final String label;

    if (percent < 40) {
      barColor = Colors.red.shade400;
      label = 'Заполните профиль для лучших рекомендаций';
    } else if (percent < 80) {
      barColor = Colors.amber.shade600;
      label = 'Почти готово! Добавьте оставшиеся данные';
    } else {
      barColor = const Color(0xFF22C55E);
      label = 'Отличная работа! Профиль заполнен';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade100,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    percent == 100
                        ? Icons.check_circle_rounded
                        : Icons.auto_graph_rounded,
                    color: barColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Заполнение профиля',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: barColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(barColor),
                  minHeight: 6,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SECTION HEADER
  // ═══════════════════════════════════════════
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.primary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // AVATAR SECTION
  // ═══════════════════════════════════════════
  Widget _buildAvatarSection(bool isDark) {
    return ValueListenableBuilder<UserModel?>(
      valueListenable: AuthService().currentUser,
      builder: (context, user, child) {
        final displayUser = user ?? widget.user;
        final hasPhoto =
            displayUser.photoUrl != null && displayUser.photoUrl!.isNotEmpty;

        return Center(
          child: Column(
            children: [
              // Avatar with gradient ring
              GestureDetector(
                onTap: () => _showImagePicker(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        Color(0xFF60A5FA),
                        Color(0xFF818CF8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      border: Border.all(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        width: 3,
                      ),
                      image: hasPhoto && !_isLoading
                          ? DecorationImage(
                              image: NetworkImage(displayUser.photoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.primary,
                            ),
                          )
                        : !hasPhoto
                        ? Center(
                            child: Text(
                              displayUser.name.isNotEmpty
                                  ? displayUser.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // „Change photo" text
              GestureDetector(
                onTap: () => _showImagePicker(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Изменить фото',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // PERSONAL FIELDS
  // ═══════════════════════════════════════════
  Widget _buildPersonalFields() {
    final l10n = AppLocalizations.of(context);
    final ageValue =
        _ageController.text.isNotEmpty &&
            AppConstants.ageOptions.contains(_ageController.text)
        ? _ageController.text
        : null;

    return Column(
      children: [
        CustomTextField(
          label: l10n?.authFullName ?? 'ФИО',
          controller: _nameController,
          icon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
          validator: (v) =>
              v!.isEmpty ? (l10n?.validationName ?? 'Введите имя') : null,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: l10n?.authEmail ?? 'Email',
          controller: _emailController,
          icon: Icons.email_outlined,
          readOnly: true,
          suffixIcon: Icon(
            Icons.lock_outline,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: CustomDropdown(
                value: ageValue,
                items: AppConstants.ageOptions,
                label: l10n?.profileAge ?? 'Возраст',
                icon: Icons.calendar_today_outlined,
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _ageController.text = v);
                    _markChanged();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomDropdown(
                value: _selectedEducation,
                items: AppConstants.educationOptions,
                label: l10n?.profileEducation ?? 'Учёба',
                icon: Icons.school_outlined,
                onChanged: (v) {
                  setState(() => _selectedEducation = v);
                  _markChanged();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // CITY FIELDS
  // ═══════════════════════════════════════════
  Widget _buildCityFields() {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        CustomDropdown(
          value: _selectedCityDropdown,
          items: AppConstants.cities,
          label: l10n?.profileCity ?? 'Город',
          icon: Icons.location_city_outlined,
          onChanged: (v) {
            setState(() {
              _selectedCityDropdown = v;
              if (v != 'Другой') {
                _cityController.text = v ?? '';
              } else {
                _cityController.clear();
              }
            });
            _markChanged();
          },
        ),
        if (_selectedCityDropdown == 'Другой') ...[
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Введите название города',
            controller: _cityController,
            icon: Icons.edit_location_alt_outlined,
            textCapitalization: TextCapitalization.words,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Введите город';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════
  // ACADEMIC FIELDS
  // ═══════════════════════════════════════════
  Widget _buildAcademicFields() {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: l10n?.profileUntScore ?? 'Баллы ЕНТ',
                hintText: '0 – 140',
                controller: _untScoreController,
                icon: Icons.score_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final score = int.tryParse(v);
                  if (score == null || score > 140) return 'Max 140';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: l10n?.profileIeltsScore ?? 'IELTS',
                hintText: '0.0 – 9.0',
                controller: _ieltsScoreController,
                icon: Icons.language_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,1}(\.\d{0,1})?'),
                  ),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final score = double.tryParse(v);
                  if (score == null || score > 9.0) return 'Max 9.0';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'GPA',
                hintText: '0.00 – 4.00',
                controller: _gpaController,
                icon: Icons.star_outline_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,1}(\.\d{0,2})?'),
                  ),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final gpa = double.tryParse(v);
                  if (gpa == null || gpa > 4.0) return 'Max 4.0';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'Мат. (проф)',
                hintText: '0 – 50',
                controller: _mathScoreController,
                icon: Icons.calculate_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final score = int.tryParse(v);
                  if (score == null || score > 50) return 'Max 50';
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // BOTTOM SAVE BAR
  // ═══════════════════════════════════════════
  Widget _buildBottomSaveBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.shade200,
          ),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)?.saveChanges ??
                          'Сохранить изменения',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // IMAGE PICKER
  // ═══════════════════════════════════════════
  Future<void> _showImagePicker(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Выберите источник',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Галерея',
                      color: const Color(0xFF3B82F6),
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(ctx);
                        _handleImageSelection(ImageSource.gallery);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Камера',
                      color: const Color(0xFF8B5CF6),
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(ctx);
                        _handleImageSelection(ImageSource.camera);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    if (_isLoading) return;

    final picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      final File file = File(image.path);
      final downloadUrl = await AuthService().uploadProfilePhoto(file);

      if (downloadUrl != null) {
        final success = await AuthService().updateProfile(
          photoUrl: downloadUrl,
        );
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Фото успешно обновлено!'),
                  ],
                ),
                backgroundColor: const Color(0xFF22C55E),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        } else {
          throw Exception('Ошибка обновления ссылки в профиле');
        }
      } else {
        throw Exception('Ошибка загрузки в облако');
      }
    } catch (e) {
      debugPrint('Photo error: $e');
      if (mounted) {
        _showError('Ошибка: ${e.toString().replaceAll('Exception:', '')}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
