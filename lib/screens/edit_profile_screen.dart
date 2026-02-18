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

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
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

  @override
  void initState() {
    super.initState();
    _initializeControllers();
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

  @override
  void dispose() {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.profileUpdated ??
                    'Profile updated successfully',
              ),
              backgroundColor: Colors.green,
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)?.editProfileTitle ?? 'Edit Profile',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildAvatarSection(),
                const SizedBox(height: 32),
                _buildFormFields(),
                const SizedBox(height: 40),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return ValueListenableBuilder<UserModel?>(
      valueListenable: AuthService().currentUser,
      builder: (context, user, child) {
        final displayUser = user ?? widget.user;
        final hasPhoto =
            displayUser.photoUrl != null && displayUser.photoUrl!.isNotEmpty;

        return Center(
          child: Stack(
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isLoading
                      ? Colors.grey.shade300
                      : (hasPhoto ? Colors.transparent : Colors.blue.shade300),
                  image: hasPhoto && !_isLoading
                      ? DecorationImage(
                          image: NetworkImage(displayUser.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: !hasPhoto && !_isLoading
                    ? Center(
                        child: Text(
                          displayUser.name.isNotEmpty
                              ? displayUser.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : null,
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showImagePicker(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormFields() {
    final l10n = AppLocalizations.of(context);

    // Initial value for dropdowns
    final ageValue =
        _ageController.text.isNotEmpty &&
            AppConstants.ageOptions.contains(_ageController.text)
        ? _ageController.text
        : null;

    return Column(
      children: [
        CustomTextField(
          label: l10n?.authFullName ?? 'Full Name',
          controller: _nameController,
          icon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
          validator: (v) =>
              v!.isEmpty ? (l10n?.validationName ?? 'Name is required') : null,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: l10n?.authEmail ?? 'Email',
          controller: _emailController,
          icon: Icons.email_outlined,
          readOnly: true,
          suffixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: CustomDropdown(
                value: ageValue,
                items: AppConstants.ageOptions,
                label: l10n?.profileAge ?? 'Возраст',
                icon: Icons.calendar_today,
                onChanged: (v) {
                  if (v != null) setState(() => _ageController.text = v);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomDropdown(
                value: _selectedEducation,
                items: AppConstants.educationOptions,
                label: l10n?.profileEducation ?? 'Учёба',
                icon: Icons.school,
                onChanged: (v) => setState(() => _selectedEducation = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        CustomDropdown(
          value: _selectedCityDropdown,
          items: AppConstants.cities,
          label: l10n?.profileCity ?? 'Город',
          icon: Icons.location_city,
          onChanged: (v) {
            setState(() {
              _selectedCityDropdown = v;
              if (v != 'Другой') {
                _cityController.text = v ?? '';
              } else {
                _cityController.clear();
              }
            });
          },
        ),
        if (_selectedCityDropdown == 'Другой') ...[
          const SizedBox(height: 12),
          CustomTextField(
            label: l10n?.profileCity ?? 'Введите название города',
            controller: _cityController,
            icon: Icons.location_city,
            textCapitalization: TextCapitalization.words,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return l10n?.validationName ?? 'Введите город';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: l10n?.profileUntScore ?? 'Баллы ЕНТ',
                controller: _untScoreController,
                icon: Icons.score,
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
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                label: l10n?.profileIeltsScore ?? 'IELTS',
                controller: _ieltsScoreController,
                icon: Icons.language,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
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
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'GPA (max 4.0)',
                controller: _gpaController,
                icon: Icons.grade,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final gpa = double.tryParse(v);
                  if (gpa == null || gpa > 4.0) return 'Max 4.0';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                label: 'Мат. (проф)',
                controller: _mathScoreController,
                icon: Icons.calculate,
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.4),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                AppLocalizations.of(context)?.saveChanges ?? 'Save Changes',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _showImagePicker(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('Галерея'),
                onTap: () {
                  Navigator.pop(context);
                  _handleImageSelection(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.purple),
                ),
                title: const Text('Камера'),
                onTap: () {
                  Navigator.pop(context);
                  _handleImageSelection(ImageSource.camera);
                },
              ),
            ],
          ),
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
              const SnackBar(
                content: Text('Фото успешно обновлено!'),
                backgroundColor: Colors.green,
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
