// ignore_for_file: avoid_print
// ═══════════════════════════════════════════════════════════════
// 📊 CSV → JSON конвертер для данных университетов TANDAU
// ═══════════════════════════════════════════════════════════════
//
// Использование:
//   dart run tools/csv_to_json_converter.dart tools/university_data.csv
//
// Входной файл: CSV (экспорт из Google Sheets)
// Выходной файл: tools/universities_output.json
//
// После конвертации запустите:
//   dart run tools/json_to_firestore_uploader.dart
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('❌ Укажите путь к CSV-файлу.');
    print('   Пример: dart run tools/csv_to_json_converter.dart tools/university_data.csv');
    exit(1);
  }

  final String csvPath = args[0];
  final File csvFile = File(csvPath);

  if (!csvFile.existsSync()) {
    print('❌ Файл не найден: $csvPath');
    exit(1);
  }

  print('📂 Читаю CSV: $csvPath');

  final String csvContent = csvFile.readAsStringSync(encoding: utf8);
  final List<String> lines = _splitCsvLines(csvContent);

  if (lines.length < 2) {
    print('❌ CSV-файл должен содержать заголовки и хотя бы одну строку данных.');
    exit(1);
  }

  // Парсим заголовки
  final List<String> headers = _parseCsvRow(lines[0]);
  print('📋 Найдено ${headers.length} колонок: ${headers.join(', ')}');

  // Обязательные поля
  const requiredFields = ['id', 'name', 'city'];
  for (final field in requiredFields) {
    if (!headers.contains(field)) {
      print('❌ Обязательная колонка "$field" отсутствует в CSV.');
      exit(1);
    }
  }

  // Парсим строки
  final List<Map<String, dynamic>> universities = [];
  int skipped = 0;

  for (int i = 1; i < lines.length; i++) {
    final String line = lines[i].trim();
    if (line.isEmpty) continue;

    final List<String> values = _parseCsvRow(line);

    if (values.length != headers.length) {
      print('⚠️  Строка $i: неверное кол-во полей '
          '(${values.length} вместо ${headers.length}), пропускаю.');
      skipped++;
      continue;
    }

    final Map<String, dynamic> uni = {};

    for (int j = 0; j < headers.length; j++) {
      final String key = headers[j].trim();
      final String value = values[j].trim();

      // Конвертация типов
      switch (key) {
        case 'studentCount':
        case 'passingScore':
          uni[key] = int.tryParse(value) ?? 0;
          break;
        case 'hasDormitory':
        case 'hasGrants':
        case 'hasMilitaryDepartment':
          uni[key] = value.toLowerCase() == 'true' ||
              value.toLowerCase() == 'да' ||
              value == '1';
          break;
        case 'majors':
        case 'specialtyCodes':
        case 'imageUrls':
        case 'requirements':
          // Разделитель — точка с запятой (;)
          if (value.isNotEmpty) {
            uni[key] = value
                .split(';')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
          } else {
            uni[key] = <String>[];
          }
          break;
        default:
          uni[key] = value;
      }
    }

    // Добавляем дефолтные поля если отсутствуют
    uni.putIfAbsent('logoUrl', () => '');
    uni.putIfAbsent('imageUrls', () => <String>[]);
    uni.putIfAbsent('majors', () => <String>[]);
    uni.putIfAbsent('specialtyCodes', () => <String>[]);
    uni.putIfAbsent('requirements', () => <String>['ЕНТ']);
    uni.putIfAbsent('passingScore', () => 50);
    uni.putIfAbsent('tuitionRange', () => '');
    uni.putIfAbsent('hasDormitory', () => false);
    uni.putIfAbsent('hasGrants', () => true);
    uni.putIfAbsent('hasMilitaryDepartment', () => false);
    uni.putIfAbsent('description', () => '');
    uni.putIfAbsent('applicationDeadline', () => '15-25 Июля');
    uni.putIfAbsent('address', () => '');
    uni.putIfAbsent('website', () => '');
    uni.putIfAbsent('contactPhone', () => '');
    uni.putIfAbsent('email', () => '');
    uni.putIfAbsent('studentCount', () => 0);
    uni.putIfAbsent('averageRating', () => 0.0);
    uni.putIfAbsent('likesCount', () => 0);
    uni.putIfAbsent('reviewsCount', () => 0);

    universities.add(uni);
  }

  print('');
  print('✅ Успешно обработано: ${universities.length} университетов');
  if (skipped > 0) {
    print('⚠️  Пропущено: $skipped строк');
  }

  // Статистика заполненности
  _printFillStats(universities);

  // Сохраняем JSON
  final String outputPath = csvPath.replaceAll('.csv', '_output.json');
  final File outputFile = File(outputPath);
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  outputFile.writeAsStringSync(encoder.convert(universities), encoding: utf8);

  print('');
  print('💾 JSON сохранён: $outputPath');
  print('');
  print('🔥 Далее: загрузите JSON в Firestore с помощью:');
  print('   1. Откройте приложение TANDAU');
  print('   2. Перейдите в Admin Panel → Миграция данных');
  print('   3. Или используйте скрипт: dart run tools/json_to_firestore.dart $outputPath');
}

/// Разделяет CSV-контент на строки, учитывая переносы строк внутри кавычек
List<String> _splitCsvLines(String content) {
  final List<String> lines = [];
  final StringBuffer current = StringBuffer();
  bool inQuotes = false;

  for (int i = 0; i < content.length; i++) {
    final String char = content[i];

    if (char == '"') {
      inQuotes = !inQuotes;
      current.write(char);
    } else if ((char == '\n' || char == '\r') && !inQuotes) {
      if (current.isNotEmpty) {
        lines.add(current.toString());
        current.clear();
      }
      // Skip \r\n pair
      if (char == '\r' && i + 1 < content.length && content[i + 1] == '\n') {
        i++;
      }
    } else {
      current.write(char);
    }
  }
  if (current.isNotEmpty) {
    lines.add(current.toString());
  }

  return lines;
}

/// Парсит одну строку CSV с учётом кавычек
List<String> _parseCsvRow(String row) {
  final List<String> fields = [];
  final StringBuffer current = StringBuffer();
  bool inQuotes = false;

  for (int i = 0; i < row.length; i++) {
    final String char = row[i];

    if (char == '"') {
      if (inQuotes && i + 1 < row.length && row[i + 1] == '"') {
        // Escaped quote
        current.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char == ',' && !inQuotes) {
      fields.add(current.toString());
      current.clear();
    } else {
      current.write(char);
    }
  }
  fields.add(current.toString());

  return fields;
}

/// Печатает статистику заполненности полей
void _printFillStats(List<Map<String, dynamic>> universities) {
  final int total = universities.length;
  if (total == 0) return;

  print('');
  print('═══ 📊 Статистика заполненности ═══');

  final fieldsToCheck = [
    'name', 'city', 'website', 'email', 'contactPhone',
    'address', 'tuitionRange', 'logoUrl', 'description',
  ];

  for (final field in fieldsToCheck) {
    int filled = 0;
    for (final uni in universities) {
      final value = uni[field];
      if (value != null && value.toString().isNotEmpty) {
        filled++;
      }
    }
    final int percent = (filled * 100 / total).round();
    final String bar = _progressBar(percent);
    final String icon = percent == 100
        ? '✅'
        : percent > 50
            ? '🟡'
            : '❌';
    print('  $icon ${field.padRight(18)} $bar $percent% ($filled/$total)');
  }

  // List fields
  for (final field in ['majors', 'specialtyCodes']) {
    int filled = 0;
    for (final uni in universities) {
      final value = uni[field];
      if (value is List && value.isNotEmpty) {
        filled++;
      }
    }
    final int percent = (filled * 100 / total).round();
    final String bar = _progressBar(percent);
    final String icon = percent > 50 ? '🟡' : '❌';
    print('  $icon ${field.padRight(18)} $bar $percent% ($filled/$total)');
  }
}

String _progressBar(int percent) {
  const int width = 20;
  final int filled = (percent * width / 100).round();
  final String bar = '█' * filled + '░' * (width - filled);
  return '[$bar]';
}
