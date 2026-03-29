import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../services/moderation_service.dart';

// Extracted profile widgets
import '../widgets/profile/profile_avatar_section.dart';
import '../widgets/profile/profile_completion_bar.dart';
import '../widgets/profile/profile_section_header.dart';
import '../widgets/profile/profile_personal_fields.dart';
import '../widgets/profile/profile_city_fields.dart';
import '../widgets/profile/profile_academic_fields.dart';
import '../widgets/profile/profile_bottom_save_bar.dart';
import '../widgets/profile/profile_image_picker_sheet.dart';
import '../widgets/profile/profile_preferences_fields.dart';
import '../widgets/profile/profile_quotas_fields.dart';
import '../widgets/profile/profile_ent_fields.dart';

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

  // 📋 Расширенные поля профиля (из OnboardingWizard)
  final Set<String> _selectedMajors = {};
  final Set<String> _selectedCities = {};
  final Set<String> _selectedAchievements = {};
  String? _financialSituation;
  bool _isRural = false;
  bool _isOrphan = false;
  bool _hasDisability = false;

  // 🎯 ЕНТ
  String? _subjectType;
  String? _entSubject1;
  String? _entSubject2;

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
    final String? city = widget.user.city;
    if (city != null && city.isNotEmpty) {
      if (AppConstants.cities.contains(city)) {
        _selectedCityDropdown = city;
      } else {
        _selectedCityDropdown = 'Другой';
      }
    }

    // 📋 Initialize extended profile fields from UserModel
    _selectedMajors.addAll(widget.user.preferredMajors);
    _selectedCities.addAll(widget.user.preferredCities);
    _selectedAchievements.addAll(widget.user.achievements);
    _financialSituation = widget.user.financialSituation;
    _isRural = widget.user.isRural ?? false;
    _isOrphan = widget.user.isOrphan ?? false;
    _hasDisability = widget.user.hasDisability ?? false;

    // 🎯 Initialize ENT direction fields
    _subjectType = widget.user.subjectType;
    _entSubject1 = widget.user.entSubject1;
    _entSubject2 = widget.user.entSubject2;
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  /// How complete is the profile (0.0 – 1.0)
  double get _completionProgress {
    int filled = 0;
    int total = 11; // name, age, education, city, unt, ielts/gpa, math, majors, achievements, financial, ent_direction
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
    if (_selectedMajors.isNotEmpty) filled++;
    if (_selectedAchievements.isNotEmpty) filled++;
    if (_financialSituation != null) filled++;
    if (_subjectType != null && _entSubject1 != null) filled++;
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

  // ── Save ─────────────────────────────────────────────────────

  /// 📋 Save extended fields (preferredMajors, achievements, cities, quotas) directly to Firestore
  Future<void> _saveExtendedFields() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'preferredMajors': _selectedMajors.toList(),
        'achievements': _selectedAchievements.toList(),
        'preferredCities': _selectedCities.toList(),
        'financialSituation': _financialSituation,
        'isRural': _isRural,
        'isOrphan': _isOrphan,
        'hasDisability': _hasDisability,
        'subjectType': _subjectType,
        'entSubject1': _entSubject1,
        'entSubject2': _entSubject2,
      });

      // Refresh AuthService local state so AI sees new data
      await AuthService().refreshUserData();
    } catch (e) {
      debugPrint('⚠️ Error saving extended fields: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (ModerationService().hasProfanity(_nameController.text.trim())) {
      final l10n = AppLocalizations.of(context);
      _showError(
        l10n?.profileNameProfanity ??
            'Имя содержит недопустимые слова (мат/оскорбления).',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bool success = await AuthService().updateProfile(
        name: _nameController.text.trim(),
        age: _ageController.text.trim(),
        education: _selectedEducation,
        city: _cityController.text.trim(),
        untScore: int.tryParse(_untScoreController.text.trim()),
        ieltsScore: double.tryParse(_ieltsScoreController.text.trim()),
        gpa: double.tryParse(_gpaController.text.trim()),
        mathScore: int.tryParse(_mathScoreController.text.trim()),
        // 📋 Расширенные поля
        preferredCities: _selectedCities.toList(),
        financialSituation: _financialSituation,
        hasDisability: _hasDisability,
        isOrphan: _isOrphan,
        isRural: _isRural,
      );

      // 📋 Сохранить списковые поля напрямую (не через updateProfile)
      if (success) {
        await _saveExtendedFields();
      }

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
          Navigator.pop(context, true); // true = profile updated
        } else {
          _showError(
            AppLocalizations.of(context)?.profileErrorUpdate ??
                'Ошибка обновления профиля',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showError(
          '${AppLocalizations.of(context)?.commonError ?? 'Ошибка:'} $e',
        );
      }
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

  // ── Navigation guard ───────────────────────────────────

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final bool isDark = Theme.of(ctx).brightness == Brightness.dark;
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
              Flexible(
                child: Text(
                  AppLocalizations.of(ctx)?.profileUnsavedChanges ??
                      'Несохранённые изменения',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            AppLocalizations.of(ctx)?.profileUnsavedMessage ??
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
              child: Text(AppLocalizations.of(ctx)?.profileStay ?? 'Остаться'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(AppLocalizations.of(ctx)?.profileLeave ?? 'Выйти'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ThemeData theme = Theme.of(context);
    final AppLocalizations? l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
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
              l10n?.editProfileTitle ?? 'Редактировать профиль',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                behavior: HitTestBehavior
                    .opaque, // ⚡ Critical: detect taps on entire area
                onTap: () async {
                  final bool shouldPop = await _onWillPop();
                  if (shouldPop && context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: isDark ? Colors.white70 : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.shade100,
              ),
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
                          ProfileAvatarSection(
                            user: widget.user,
                            isDark: isDark,
                            isLoading: _isLoading,
                            onPickImage: () => _showImagePicker(),
                          ),
                          const SizedBox(height: 20),
                          ProfileCompletionBar(
                            progress: _completionProgress,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 24),

                          // ═══ Personal Data Card ═══
                          _buildSectionCard(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ProfileSectionHeader(
                                  icon: Icons.person_outline,
                                  title: l10n?.profileSectionPersonal ??
                                      'Личные данные',
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 18),
                                ProfilePersonalFields(
                                  nameController: _nameController,
                                  emailController: _emailController,
                                  ageController: _ageController,
                                  selectedEducation: _selectedEducation,
                                  onAgeChanged: (v) {
                                    if (v != null) {
                                      setState(() => _ageController.text = v);
                                      _markChanged();
                                    }
                                  },
                                  onEducationChanged: (v) {
                                    setState(() => _selectedEducation = v);
                                    _markChanged();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ═══ City Card ═══
                          _buildSectionCard(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ProfileSectionHeader(
                                  icon: Icons.location_on_outlined,
                                  title: l10n?.profileCity ?? 'Город',
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 18),
                                ProfileCityFields(
                                  selectedCityDropdown: _selectedCityDropdown,
                                  cityController: _cityController,
                                  onCityDropdownChanged: (v) {
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ═══ ENT Direction Card ═══
                          _buildSectionCard(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ProfileSectionHeader(
                                  icon: Icons.explore_outlined,
                                  title: 'Направление и предметы ЕНТ',
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 18),
                                ProfileEntFields(
                                  subjectType: _subjectType,
                                  entSubject1: _entSubject1,
                                  entSubject2: _entSubject2,
                                  onSubjectTypeChanged: (v) {
                                    setState(() {
                                      _subjectType = v;
                                      // Reset subjects if direction changes
                                      _entSubject1 = null;
                                      _entSubject2 = null;
                                    });
                                    _markChanged();
                                  },
                                  onSubject1Changed: (v) {
                                    setState(() => _entSubject1 = v);
                                    _markChanged();
                                  },
                                  onSubject2Changed: (v) {
                                    setState(() => _entSubject2 = v);
                                    _markChanged();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ═══ Academic Scores Card ═══
                          _buildSectionCard(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ProfileSectionHeader(
                                  icon: Icons.school_outlined,
                                  title: l10n?.profileSectionAcademic ??
                                      'Академические баллы',
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 18),
                                ProfileAcademicFields(
                                  untScoreController: _untScoreController,
                                  ieltsScoreController: _ieltsScoreController,
                                  gpaController: _gpaController,
                                  mathScoreController: _mathScoreController,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ═══ Preferences Card ═══
                          _buildSectionCard(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ProfileSectionHeader(
                                  icon: Icons.interests_outlined,
                                  title: 'Предпочтения',
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 18),
                                ProfilePreferencesFields(
                                  selectedMajors: _selectedMajors,
                                  selectedAchievements: _selectedAchievements,
                                  onMajorToggle: (v) {
                                    setState(() {
                                      if (_selectedMajors.contains(v)) {
                                        _selectedMajors.remove(v);
                                      } else {
                                        _selectedMajors.add(v);
                                      }
                                    });
                                    _markChanged();
                                  },
                                  onAchievementToggle: (v) {
                                    setState(() {
                                      if (_selectedAchievements.contains(v)) {
                                        _selectedAchievements.remove(v);
                                      } else {
                                        _selectedAchievements.add(v);
                                      }
                                    });
                                    _markChanged();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ═══ Quotas & Financial Card ═══
                          _buildSectionCard(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ProfileSectionHeader(
                                  icon: Icons.account_balance_outlined,
                                  title: 'Финансы и квоты',
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 18),
                                ProfileQuotasFields(
                                  financialSituation: _financialSituation,
                                  isRural: _isRural,
                                  isOrphan: _isOrphan,
                                  hasDisability: _hasDisability,
                                  onFinancialChanged: (v) {
                                    setState(() => _financialSituation = v);
                                    _markChanged();
                                  },
                                  onRuralChanged: (v) {
                                    setState(() => _isRural = v);
                                    _markChanged();
                                  },
                                  onOrphanChanged: (v) {
                                    setState(() => _isOrphan = v);
                                    _markChanged();
                                  },
                                  onDisabilityChanged: (v) {
                                    setState(() => _hasDisability = v);
                                    _markChanged();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
                // ═══ Fixed Save Button at the bottom ═══
                ProfileBottomSaveBar(
                  isDark: isDark,
                  isLoading: _isLoading,
                  onSave: _saveProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section Card ──────────────────────────────────────

  Widget _buildSectionCard({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
      ),
      child: child,
    );
  }

  // ── Image picker shortcut ──────────────────────────────

  void _showImagePicker() {
    ProfileImagePickerHelper.showPicker(
      context: context,
      onLoadingChanged: (loading) {
        if (mounted) setState(() => _isLoading = loading);
      },
      onPhotoUpdated: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)?.profilePhotoUpdated ??
                        'Фото успешно обновлено!',
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
        }
      },
      onError: (message) {
        if (mounted) _showError(message);
      },
    );
  }
}
