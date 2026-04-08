import 'package:flutter/material.dart';
import '../../models/university.dart';
import '../../services/auth_service.dart';
import '../../services/university_service.dart';
import '../../services/audit_log_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/markdown_editor.dart';

class UniversityEditorScreen extends StatefulWidget {
  final University? university;

  const UniversityEditorScreen({super.key, this.university});

  @override
  State<UniversityEditorScreen> createState() => _UniversityEditorScreenState();
}

class _UniversityEditorScreenState extends State<UniversityEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _logoUrlCtrl;
  late TextEditingController _passingScoreCtrl;
  late TextEditingController _tuitionCtrl;
  late TextEditingController _descCtrl;
  
  // New Controllers
  late TextEditingController _addressCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _deadlineCtrl;
  late TextEditingController _studentCountCtrl;
  
  late TextEditingController _imageUrlsCtrl;
  late TextEditingController _majorsCtrl;
  late TextEditingController _requirementsCtrl;
  late TextEditingController _specialtyCodesCtrl;
  
  bool _hasDorm = false;
  bool _hasGrants = true;
  bool _hasMilitary = false;
  bool _isLoading = false;
  late bool _isAdmin;

  @override
  void initState() {
    super.initState();
    final uni = widget.university;
    _nameCtrl = TextEditingController(text: uni?.name ?? '');
    _cityCtrl = TextEditingController(text: uni?.city ?? '');
    _logoUrlCtrl = TextEditingController(text: uni?.logoUrl ?? '');
    _passingScoreCtrl = TextEditingController(text: uni != null ? uni.passingScore.toString() : '');
    _tuitionCtrl = TextEditingController(text: uni?.tuitionRange ?? '');
    _descCtrl = TextEditingController(text: uni?.description ?? '');
    
    _addressCtrl = TextEditingController(text: uni?.address ?? '');
    _websiteCtrl = TextEditingController(text: uni?.website ?? '');
    _phoneCtrl = TextEditingController(text: uni?.contactPhone ?? '');
    _emailCtrl = TextEditingController(text: uni?.email ?? '');
    _deadlineCtrl = TextEditingController(text: uni?.applicationDeadline ?? '');
    _studentCountCtrl = TextEditingController(text: uni != null ? uni.studentCount.toString() : '');
    
    _imageUrlsCtrl = TextEditingController(text: uni?.imageUrls.join('\n') ?? '');
    _majorsCtrl = TextEditingController(text: uni?.majors.join('\n') ?? '');
    _requirementsCtrl = TextEditingController(text: uni?.requirements.join('\n') ?? '');
    _specialtyCodesCtrl = TextEditingController(text: uni?.specialtyCodes.join('\n') ?? '');
    
    if (uni != null) {
      _hasDorm = uni.hasDormitory;
      _hasGrants = uni.hasGrants;
      _hasMilitary = uni.hasMilitaryDepartment;
    }
    _isAdmin = AuthService().isAdmin;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _logoUrlCtrl.dispose();
    _passingScoreCtrl.dispose();
    _tuitionCtrl.dispose();
    _descCtrl.dispose();
    
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _deadlineCtrl.dispose();
    _studentCountCtrl.dispose();
    
    _imageUrlsCtrl.dispose();
    _majorsCtrl.dispose();
    _requirementsCtrl.dispose();
    _specialtyCodesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final uni = University(
        id: widget.university?.id ?? '', 
        name: _nameCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        logoUrl: _logoUrlCtrl.text.trim(),
        passingScore: int.tryParse(_passingScoreCtrl.text) ?? 50,
        tuitionRange: _tuitionCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        
        address: _addressCtrl.text.trim(),
        website: _websiteCtrl.text.trim(),
        contactPhone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        applicationDeadline: _deadlineCtrl.text.trim(),
        studentCount: int.tryParse(_studentCountCtrl.text) ?? 0,
        
        imageUrls: _imageUrlsCtrl.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        majors: _majorsCtrl.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        requirements: _requirementsCtrl.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        specialtyCodes: _specialtyCodesCtrl.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),

        hasDormitory: _hasDorm,
        hasGrants: _hasGrants,
        hasMilitaryDepartment: _hasMilitary,
        
        likesCount: widget.university?.likesCount ?? 0,
        reviewsCount: widget.university?.reviewsCount ?? 0,
        averageRating: widget.university?.averageRating ?? 0.0,
      );

      bool success;
      if (widget.university == null) {
        success = await UniversityService().addUniversity(uni);
      } else {
        success = await UniversityService().updateUniversity(uni);
      }

      if (success) {
        final diffs = widget.university != null ? _computeDiff(widget.university!, uni) : {'action': 'created'};
        if (diffs.isNotEmpty || widget.university == null) {
          AuditLogService().log(
            action: AuditLogService.actionUpdateUniversity,
            targetUid: uni.id,
            targetName: uni.name,
            diffs: diffs,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Успешно сохранено' : 'Ошибка при сохранении', style: const TextStyle(color: Colors.white)),
            backgroundColor: success ? AppColors.success : AppColors.error,
          )
        );
        if (success) {
          Navigator.pop(context, true); 
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          widget.university == null 
              ? 'Добавить ВУЗ' 
              : (_isAdmin ? 'Редактировать: ${widget.university!.name}' : 'Просмотр: ${widget.university!.name}'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.backgroundDark,
        centerTitle: false,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isAdmin ? 'Основная информация' : 'Данные университета', 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isAdmin ? 'Заполните поля ниже для управления данными' : 'Доступно только в режиме просмотра',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildField('Название', _nameCtrl, required: true),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(child: _buildField('Город', _cityCtrl, required: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField('Кол-во студентов', _studentCountCtrl, isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  MarkdownEditor(
                    controller: _descCtrl,
                    label: 'Описание ВУЗа',
                    enabled: _isAdmin,
                    minLines: 5,
                  ),
                  const SizedBox(height: 24),
                  
                  Text('Финансы и Поступление', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary.withValues(alpha: 0.8))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildField('Проходной балл', _passingScoreCtrl, isNumber: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField('Стоимость обучения (строка)', _tuitionCtrl)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildField('Дедлайн приема документов', _deadlineCtrl),
                  const SizedBox(height: 24),

                  Text('Контакты и Ссылки', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary.withValues(alpha: 0.8))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildField('Эл. почта (Email)', _emailCtrl)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField('Номер телефона', _phoneCtrl)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildField('Веб-сайт', _websiteCtrl)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField('Адрес ВУЗа', _addressCtrl)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildField('URL логотипа', _logoUrlCtrl),
                  const SizedBox(height: 24),
                  
                  Text('Списки (каждое значение с новой строки)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary.withValues(alpha: 0.8))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildField('Специальности (Majors)', _majorsCtrl, maxLines: 4)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField('Коды ГОП', _specialtyCodesCtrl, maxLines: 4)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildField('Требования', _requirementsCtrl, maxLines: 4)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField('URL картинок (Галерея)', _imageUrlsCtrl, maxLines: 4)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Text('Опции инфраструктуры', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary.withValues(alpha: 0.8))),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Есть гранты', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          value: _hasGrants,
                          onChanged: _isAdmin ? (val) => setState(() => _hasGrants = val) : null,
                          activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                          activeThumbColor: AppColors.primary,
                          tileColor: Colors.transparent,
                        ),
                        Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                        SwitchListTile(
                          title: const Text('Есть общежитие', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          value: _hasDorm,
                          onChanged: _isAdmin ? (val) => setState(() => _hasDorm = val) : null,
                          activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                          activeThumbColor: AppColors.primary,
                          tileColor: Colors.transparent,
                        ),
                        Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                        SwitchListTile(
                          title: const Text('Есть военная кафедра', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          value: _hasMilitary,
                          onChanged: _isAdmin ? (val) => setState(() => _hasMilitary = val) : null,
                          activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                          activeThumbColor: AppColors.primary,
                          tileColor: Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  if (_isAdmin) ...[
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : _save,
                        child: _isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                            : const Text('СОХРАНИТЬ ИЗМЕНЕНИЯ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 16)),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 48),
                    Center(
                      child: Text(
                        'Редактирование доступно только администраторам',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool required = false, bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: _isAdmin,
      style: TextStyle(color: _isAdmin ? Colors.white : Colors.white.withValues(alpha: 0.7)),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: required ? (v) => v == null || v.isEmpty ? 'Обязательное поле' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.02)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.surfaceDark.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Map<String, dynamic> _computeDiff(University old, University newUni) {
    final diff = <String, dynamic>{};
    void compare(String key, dynamic oldVal, dynamic newVal) {
      if (oldVal != newVal) {
        if (oldVal is List && newVal is List) {
          if (oldVal.join(', ') != newVal.join(', ')) {
            diff[key] = {'old': oldVal.join(', '), 'new': newVal.join(', ')};
          }
        } else {
          diff[key] = {'old': oldVal, 'new': newVal};
        }
      }
    }
    compare('name', old.name, newUni.name);
    compare('city', old.city, newUni.city);
    compare('passingScore', old.passingScore, newUni.passingScore);
    compare('tuitionRange', old.tuitionRange, newUni.tuitionRange);
    compare('description', old.description, newUni.description);
    compare('address', old.address, newUni.address);
    compare('website', old.website, newUni.website);
    compare('contactPhone', old.contactPhone, newUni.contactPhone);
    compare('email', old.email, newUni.email);
    compare('applicationDeadline', old.applicationDeadline, newUni.applicationDeadline);
    compare('studentCount', old.studentCount, newUni.studentCount);
    compare('hasDormitory', old.hasDormitory, newUni.hasDormitory);
    compare('hasGrants', old.hasGrants, newUni.hasGrants);
    compare('hasMilitaryDepartment', old.hasMilitaryDepartment, newUni.hasMilitaryDepartment);
    return diff;
  }
}
