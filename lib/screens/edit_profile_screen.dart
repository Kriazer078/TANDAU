import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../theme/app_colors.dart';
import 'package:image_picker/image_picker.dart'; // ⭐ Image Picker
import 'dart:io'; // ⭐ File
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
  late TextEditingController _gpaController; // ⭐
  late TextEditingController _mathScoreController; // ⭐
  String? _selectedEducation;

  bool _isLoading = false;

  final List<String> _educationOptions = ['11 класс', 'Колледж'];

  @override
  void initState() {
    super.initState();
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

    if (widget.user.education != null &&
        _educationOptions.contains(widget.user.education)) {
      _selectedEducation = widget.user.education;
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
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final success = await AuthService().updateProfile(
        name: _nameController.text.trim(),
        age: _ageController.text.trim(),
        education: _selectedEducation,
        city: _cityController.text.trim(),
        untScore: int.tryParse(_untScoreController.text.trim()),
        ieltsScore: double.tryParse(_ieltsScoreController.text.trim()),
        gpa: double.tryParse(_gpaController.text.trim()), // ⭐
        mathScore: int.tryParse(_mathScoreController.text.trim()), // ⭐
      );

      if (mounted) {
        setState(() => _isLoading = false);
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.profileErrorUpdate ??
                    'Ошибка обновления профиля',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Telegram-style Profile Picture
              ValueListenableBuilder<UserModel?>(
                valueListenable: AuthService().currentUser,
                builder: (context, user, child) {
                  final displayUser = user ?? widget.user;
                  return Center(
                    child: Stack(
                      children: [
                        // Main Avatar
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isLoading
                                ? Colors.grey.shade300
                                : (displayUser.photoUrl != null &&
                                          displayUser.photoUrl!.isNotEmpty
                                      ? Colors.transparent
                                      : Colors.blue.shade300),
                            image:
                                displayUser.photoUrl != null &&
                                    displayUser.photoUrl!.isNotEmpty &&
                                    !_isLoading
                                ? DecorationImage(
                                    image: NetworkImage(displayUser.photoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              (displayUser.photoUrl == null ||
                                      displayUser.photoUrl!.isEmpty) &&
                                  !_isLoading
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

                        // Loading Overlay
                        if (_isLoading)
                          Positioned.fill(
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.blue.shade400,
                            ),
                          ),

                        // Camera Icon Button
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _showImagePicker(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor,
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
              ),
              const SizedBox(height: 32),

              CustomTextField(
                label:
                    AppLocalizations.of(context)?.authFullName ?? 'Full Name',
                controller: _nameController,
                icon: Icons.person_outline,
                validator: (v) => v!.isEmpty
                    ? (AppLocalizations.of(context)?.validationName ??
                          'Name is required')
                    : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: AppLocalizations.of(context)?.authEmail ?? 'Email',
                controller: _emailController,
                icon: Icons.email_outlined,
                readOnly: true, // Email cannot be changed here
                suffixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      menuMaxHeight: 300,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                      ),
                      initialValue:
                          _ageController.text.isNotEmpty &&
                              List.generate(
                                17,
                                (i) => (i + 14).toString(),
                              ).contains(_ageController.text)
                          ? _ageController.text
                          : null,
                      isExpanded: true, // ⭐ Устраняет переполнение
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ), // Меньше отступы
                        labelText:
                            AppLocalizations.of(context)?.profileAge ??
                            'Возраст',
                        labelStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.calendar_today,
                          color: AppColors.primary,
                        ),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).inputDecorationTheme.fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: List.generate(17, (i) => (i + 14).toString())
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _ageController.text = v);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      menuMaxHeight: 300,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                      ),
                      initialValue: _selectedEducation,
                      isExpanded: true, // ⭐ Устраняет переполнение
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ), // Меньше отступы
                        labelText:
                            AppLocalizations.of(context)?.profileEducation ??
                            'Учёба',
                        labelStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.school,
                          color: AppColors.primary,
                        ),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).inputDecorationTheme.fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: _educationOptions
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedEducation = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                menuMaxHeight: 300,
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 16,
                ),
                initialValue:
                    _cityController.text.isNotEmpty &&
                        [
                          'Алматы',
                          'Астана',
                          'Шымкент',
                          'Караганда',
                          'Актобе',
                          'Усть-Каменогорск',
                          'Костанай',
                          'Семей',
                          'Павлодар',
                          'Атырау',
                          'Кызылорда',
                          'Тараз',
                          'Уральск',
                          'Актау',
                          'Петропавловск',
                          'Кокшетау',
                          'Талдыкорган',
                          'Темиртау',
                          'Туркестан',
                          'Другой',
                        ].contains(_cityController.text)
                    ? _cityController.text
                    : null,
                decoration: InputDecoration(
                  isDense: true,
                  labelText:
                      AppLocalizations.of(context)?.profileCity ?? 'Город',
                  labelStyle: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.location_city,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                items:
                    [
                          'Алматы',
                          'Астана',
                          'Шымкент',
                          'Караганда',
                          'Актобе',
                          'Усть-Каменогорск',
                          'Костанай',
                          'Семей',
                          'Павлодар',
                          'Атырау',
                          'Кызылорда',
                          'Тараз',
                          'Уральск',
                          'Актау',
                          'Петропавловск',
                          'Кокшетау',
                          'Талдыкорган',
                          'Темиртау',
                          'Туркестан',
                          'Другой',
                        ]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _cityController.text = v);
                  }
                },
              ),
              const SizedBox(height: 20),

              // Existing Score Fields
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label:
                          AppLocalizations.of(context)?.profileUntScore ??
                          'Баллы ЕНТ',
                      controller: _untScoreController,
                      icon: Icons.score,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label:
                          AppLocalizations.of(context)?.profileIeltsScore ??
                          'IELTS (если есть)',
                      controller: _ieltsScoreController,
                      icon: Icons.language,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // NEW: GPA and Math Score
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'GPA (max 4.0)', // Localize later
                      controller: _gpaController,
                      icon: Icons.grade,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Проф. Математика', // Localize later
                      controller: _mathScoreController,
                      icon: Icons.calculate,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              SizedBox(
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
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          AppLocalizations.of(context)?.saveChanges ??
                              'Save Changes',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showImagePicker(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Галерея'),
              onTap: () {
                Navigator.pop(context);
                _handleImageSelection(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Камера'),
              onTap: () {
                Navigator.pop(context);
                _handleImageSelection(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    if (_isLoading) return;

    final messenger = ScaffoldMessenger.of(context);
    final ImagePicker picker = ImagePicker();

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
          messenger.showSnackBar(
            const SnackBar(content: Text('Фото успешно обновлено!')),
          );
        } else {
          throw Exception('Ошибка обновления ссылки в профиле');
        }
      } else {
        throw Exception('Ошибка загрузки в облако');
      }
    } catch (e) {
      debugPrint('Photo error: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString().replaceAll('Exception:', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
