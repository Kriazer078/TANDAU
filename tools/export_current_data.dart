// ignore_for_file: avoid_print
// ═══════════════════════════════════════════════════════════════
// 📤 Экспорт текущих данных из base64 в CSV для Google Sheets
// ═══════════════════════════════════════════════════════════════
//
// Использование:
//   dart run tools/export_current_data.dart
//
// Создаёт tools/university_data.csv со всеми текущими вузами.
// Импортируйте этот CSV в Google Sheets для ручного дополнения.
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

void main() {
  // Декодируем base64 из universities.dart
  final File sourceFile = File('lib/data/universities.dart');
  if (!sourceFile.existsSync()) {
    print('❌ Файл lib/data/universities.dart не найден!');
    exit(1);
  }

  final String content = sourceFile.readAsStringSync();

  // Извлекаем base64 строку
  final RegExp b64Regex = RegExp(r"'([A-Za-z0-9+/=]{100,})'");
  final Match? match = b64Regex.firstMatch(content);

  if (match == null) {
    print('❌ Не удалось найти base64 строку в файле');
    exit(1);
  }

  final String b64 = match.group(1)!;
  final String rawJson = utf8.decode(base64Decode(b64));
  final List<dynamic> universities = jsonDecode(rawJson) as List<dynamic>;

  print('📋 Найдено ${universities.length} университетов');

  // Заголовки CSV
  const List<String> headers = [
    'id',
    'name',
    'city',
    'website',
    'email',
    'contactPhone',
    'address',
    'studentCount',
    'tuitionRange',
    'hasDormitory',
    'hasGrants',
    'hasMilitaryDepartment',
    'logoUrl',
    'description',
    'majors',
    'specialtyCodes',
    'passingScore',
    'applicationDeadline',
    'requirements',
  ];

  final StringBuffer csv = StringBuffer();

  // Записываем заголовки
  csv.writeln(headers.join(','));

  // Записываем данные
  for (final Map<String, dynamic> uni in universities.cast()) {
    final List<String> row = [];

    for (final String header in headers) {
      final dynamic value = uni[header];

      if (value == null) {
        row.add('');
      } else if (value is List) {
        // Списки — через точку с запятой
        row.add(_escapeCsv(value.join(';')));
      } else if (value is bool) {
        row.add(value.toString());
      } else {
        row.add(_escapeCsv(value.toString()));
      }
    }

    csv.writeln(row.join(','));
  }

  // Сохраняем
  final File outputFile = File('tools/university_data.csv');
  outputFile.writeAsStringSync(csv.toString(), encoding: utf8);

  print('💾 CSV сохранён: tools/university_data.csv');
  print('');
  print('📊 Статистика:');

  // Статистика
  int withWebsite = 0;
  int withEmail = 0;
  int withTuition = 0;
  int withLogo = 0;
  int withMajors = 0;
  int withDescription = 0;

  for (final Map<String, dynamic> uni in universities.cast()) {
    final String desc = (uni['description'] ?? '').toString();
    if ((uni['website'] ?? '').toString().isNotEmpty) withWebsite++;
    if ((uni['email'] ?? '').toString().isNotEmpty) withEmail++;
    if ((uni['tuitionRange'] ?? '').toString().isNotEmpty) withTuition++;
    if ((uni['logoUrl'] ?? '').toString().isNotEmpty) withLogo++;
    if (uni['majors'] is List && (uni['majors'] as List).isNotEmpty) {
      withMajors++;
    }
    if (desc.isNotEmpty && !desc.contains('Официальные данные eGov')) {
      withDescription++;
    }
  }

  final int total = universities.length;
  print('  ✅ name:         $total/$total (100%)');
  print('  ✅ city:         $total/$total (100%)');
  print('  ${withWebsite > 0 ? "🟡" : "❌"} website:      $withWebsite/$total');
  print('  ${withEmail > 0 ? "🟡" : "❌"} email:        $withEmail/$total');
  print('  ${withTuition > 0 ? "🟡" : "❌"} tuitionRange: $withTuition/$total');
  print('  ${withLogo > 0 ? "🟡" : "❌"} logoUrl:      $withLogo/$total');
  print('  ${withMajors > 0 ? "🟡" : "❌"} majors:       $withMajors/$total');
  print(
    '  ${withDescription > 0 ? "🟡" : "❌"} description:  $withDescription/$total',
  );
  print('');
  print('🔧 Далее:');
  print('  1. Импортируйте CSV в Google Sheets');
  print('  2. Заполните пустые поля (website, email, tuition, и т.д.)');
  print('  3. Экспортируйте обратно как CSV');
  print(
    '  4. dart run tools/csv_to_json_converter.dart tools/university_data.csv',
  );
}

/// Экранирует значение для CSV (добавляет кавычки если нужно)
String _escapeCsv(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
