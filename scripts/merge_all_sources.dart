// ignore_for_file: avoid_print
// ═══════════════════════════════════════════════════════════════
// 🔧 MASTER MERGE: Объединение ВСЕХ источников данных
// ═══════════════════════════════════════════════════════════════
//
// Использование:
//   dart run scripts/merge_all_sources.dart
//
// Источники:
//   1. tools/university_data_output.json (основной — 127 универов)
//   2. assets/parsed_universities.json   (specialty codes + lat/long)
//   3. tools/fill_university_data.dart   (enrichment — website, email, etc.)
//   4. assets/higher_education_org1-v1.json (geo coords, student count)
//
// Выход:
//   - tools/merged_universities.json     (для Firestore upload)
//   - lib/data/universities.dart         (Base64 encoded)
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

void main() async {
  print('═══════════════════════════════════════════════════');
  print('🔧 TANDAU — Master University Data Merge');
  print('═══════════════════════════════════════════════════');

  // ═══ 1. Загружаем ОСНОВНОЙ источник ═══
  final File mainFile = File('tools/university_data_output.json');
  if (!mainFile.existsSync()) {
    print('❌ tools/university_data_output.json не найден!');
    exit(1);
  }
  final List<dynamic> mainData =
      jsonDecode(await mainFile.readAsString()) as List<dynamic>;
  print('📂 [Источник 1] university_data_output.json: ${mainData.length} записей');

  // Конвертируем в Map по id
  final Map<String, Map<String, dynamic>> universityById = {};
  for (final item in mainData) {
    final Map<String, dynamic> uni = item as Map<String, dynamic>;
    final String id = uni['id']?.toString() ?? '';
    if (id.isNotEmpty) {
      universityById[id] = Map<String, dynamic>.from(uni);
    }
  }

  // ═══ 2. Загружаем parsed_universities.json (specialty codes) ═══
  final File parsedFile = File('assets/parsed_universities.json');
  int specialtyMatches = 0;
  if (parsedFile.existsSync()) {
    final List<dynamic> parsedData =
        jsonDecode(await parsedFile.readAsString()) as List<dynamic>;
    print('📂 [Источник 2] parsed_universities.json: ${parsedData.length} записей');

    // Создаём маппинг по website URL
    final Map<String, Map<String, dynamic>> parsedByWebsite = {};
    for (final item in parsedData) {
      final Map<String, dynamic> parsed = item as Map<String, dynamic>;
      final String website = (parsed['website'] ?? '').toString().trim().toLowerCase();
      if (website.isNotEmpty) {
        parsedByWebsite[website] = parsed;
        // Также добавляем без trailing slash
        final String cleanUrl = website.endsWith('/')
            ? website.substring(0, website.length - 1)
            : website;
        parsedByWebsite[cleanUrl] = parsed;
      }
    }

    // Merge specialty codes
    for (final uni in universityById.values) {
      final String uniWebsite = (uni['website'] ?? '').toString().trim().toLowerCase();
      if (uniWebsite.isEmpty) continue;

      final String cleanUrl = uniWebsite.endsWith('/')
          ? uniWebsite.substring(0, uniWebsite.length - 1)
          : uniWebsite;

      final Map<String, dynamic>? match =
          parsedByWebsite[uniWebsite] ?? parsedByWebsite[cleanUrl];

      if (match != null) {
        // Добавляем specialty codes
        final List<dynamic>? specialties = match['specialties'] as List<dynamic>?;
        if (specialties != null && specialties.isNotEmpty) {
          final List<String> codes = specialties
              .map((s) => (s as Map<String, dynamic>)['code']?.toString() ?? '')
              .where((c) => c.isNotEmpty)
              .toList();
          if (codes.isNotEmpty) {
            uni['specialtyCodes'] = codes;
            specialtyMatches++;
          }
        }

        // Добавляем координаты если есть
        if (match.containsKey('lat') && match['lat'] != null) {
          uni['latitude'] = double.tryParse(match['lat'].toString()) ?? 0.0;
        }
        if (match.containsKey('long') && match['long'] != null) {
          uni['longitude'] = double.tryParse(match['long'].toString()) ?? 0.0;
        }

        // Добавляем выпускников если есть
        if (match.containsKey('graduates') && match['graduates'] != null) {
          uni['graduatesCount'] = int.tryParse(match['graduates'].toString()) ?? 0;
        }
      }
    }
    print('   ✅ Matched specialty codes for $specialtyMatches universities');
  } else {
    print('⚠️  parsed_universities.json не найден, пропускаем');
  }

  // ═══ 3. Загружаем higher_education_org1-v1.json (geo data) ═══
  final File orgFile = File('assets/higher_education_org1-v1.json');
  int geoMatches = 0;
  if (orgFile.existsSync()) {
    final List<dynamic> orgData =
        jsonDecode(await orgFile.readAsString()) as List<dynamic>;
    print('📂 [Источник 3] higher_education_org1-v1.json: ${orgData.length} записей');

    // Map по id
    final Map<String, Map<String, dynamic>> orgById = {};
    for (final item in orgData) {
      final Map<String, dynamic> org = item as Map<String, dynamic>;
      final String id = org['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        orgById[id] = org;
      }
    }

    // Merge geo data
    for (final entry in universityById.entries) {
      final Map<String, dynamic>? orgMatch = orgById[entry.key];
      if (orgMatch != null) {
        geoMatches++;
        // studentCount — обновляем если в основном 0
        if ((entry.value['studentCount'] ?? 0) == 0) {
          final int stuCount =
              int.tryParse(orgMatch['number_stu']?.toString() ?? '0') ?? 0;
          if (stuCount > 0) {
            entry.value['studentCount'] = stuCount;
          }
        }

        // Координаты — добавляем если ещё нет
        if (!entry.value.containsKey('latitude') ||
            entry.value['latitude'] == 0.0) {
          final double lat =
              double.tryParse(orgMatch['lat']?.toString() ?? '0') ?? 0.0;
          final double lng =
              double.tryParse(orgMatch['long']?.toString() ?? '0') ?? 0.0;
          if (lat != 0.0) entry.value['latitude'] = lat;
          if (lng != 0.0) entry.value['longitude'] = lng;
        }
      }
    }
    print('   ✅ Matched geo data for $geoMatches universities');
  } else {
    print('⚠️  higher_education_org1-v1.json не найден, пропускаем');
  }

  // ═══ 4. Нормализация городов ═══
  final Map<String, String> cityNormalization = {
    'Астана': 'Астана',
    'город Астана': 'Астана',
    'г.Астана': 'Астана',
    'г. Астана': 'Астана',
    'Алматы': 'Алматы',
    'город Алматы': 'Алматы',
    'г.Алматы': 'Алматы',
    'г. Алматы': 'Алматы',
    'Шымкент': 'Шымкент',
    'город Шымкент': 'Шымкент',
    'г.Шымкент': 'Шымкент',
    'Туркестанская область': 'Туркестан',
    'Актюбинская область': 'Актобе',
    'Атырауская область': 'Атырау',
    'Западно-Казахстанская область': 'Уральск',
    'Восточно-Казахстанская область': 'Усть-Каменогорск',
    'Карагандинская область': 'Караганда',
    'Костанайская область': 'Костанай',
    'Кызылординская область': 'Кызылорда',
    'Мангистауская область': 'Актау',
    'Павлодарская область': 'Павлодар',
    'Северо-Казахстанская область': 'Петропавловск',
    'Жамбылская область': 'Тараз',
    'Акмолинская область': 'Кокшетау',
    'Алматинская область': 'Алматы',
    'Область Абай': 'Семей',
    'Область Жетісу': 'Талдыкорган',
    'Область Ұлытау': 'Жезказган',
  };

  for (final uni in universityById.values) {
    final String rawCity = (uni['city'] ?? '').toString().trim();
    if (cityNormalization.containsKey(rawCity)) {
      uni['city'] = cityNormalization[rawCity]!;
    }
  }

  // ═══ 5. Валидация и очистка ═══
  int withWebsite = 0;
  int withEmail = 0;
  int withDescription = 0;
  int withSpecialties = 0;
  int withStudentCount = 0;
  int withTuition = 0;

  for (final uni in universityById.values) {
    // Ensure all required fields exist
    uni['logoUrl'] ??= '';
    uni['imageUrls'] ??= <dynamic>[];
    uni['majors'] ??= <dynamic>[];
    uni['specialtyCodes'] ??= <dynamic>[];
    uni['passingScore'] ??= 50;
    uni['hasDormitory'] ??= false;
    uni['hasGrants'] ??= true;
    uni['hasMilitaryDepartment'] ??= false;
    uni['requirements'] ??= <dynamic>['ЕНТ'];
    uni['applicationDeadline'] ??= '15-25 Июля';
    uni['averageRating'] ??= 0.0;
    uni['likesCount'] ??= 0;
    uni['reviewsCount'] ??= 0;
    uni['contactPhone'] ??= '';
    uni['email'] ??= '';
    uni['studentCount'] ??= 0;

    // Stats
    if ((uni['website'] ?? '').toString().isNotEmpty) withWebsite++;
    if ((uni['email'] ?? '').toString().isNotEmpty) withEmail++;
    if ((uni['description'] ?? '').toString().isNotEmpty &&
        uni['description'] != 'Официальные данные eGov') {
      withDescription++;
    }
    if ((uni['specialtyCodes'] as List).isNotEmpty) withSpecialties++;
    if ((uni['studentCount'] ?? 0) > 0) withStudentCount++;
    if ((uni['tuitionRange'] ?? '').toString().isNotEmpty) withTuition++;
  }

  final int total = universityById.length;
  print('');
  print('═══════════════════════════════════════════════════');
  print('📊 Data Quality Report ($total universities)');
  print('═══════════════════════════════════════════════════');
  print('  ✅ website:        $withWebsite/$total (${(withWebsite * 100 / total).round()}%)');
  print('  ✅ email:          $withEmail/$total (${(withEmail * 100 / total).round()}%)');
  print('  ✅ description:    $withDescription/$total (${(withDescription * 100 / total).round()}%)');
  print('  ✅ tuitionRange:   $withTuition/$total (${(withTuition * 100 / total).round()}%)');
  print('  ✅ studentCount:   $withStudentCount/$total (${(withStudentCount * 100 / total).round()}%)');
  print('  🎯 specialtyCodes: $withSpecialties/$total (${(withSpecialties * 100 / total).round()}%)');

  // ═══ 6. Сохраняем merged JSON (для Firestore) ═══
  final List<Map<String, dynamic>> finalList = universityById.values.toList();
  // Sort by id для стабильности
  finalList.sort((a, b) {
    final int idA = int.tryParse(a['id'].toString()) ?? 0;
    final int idB = int.tryParse(b['id'].toString()) ?? 0;
    return idA.compareTo(idB);
  });

  final String mergedJson =
      const JsonEncoder.withIndent('  ').convert(finalList);
  final File mergedFile = File('tools/merged_universities.json');
  await mergedFile.writeAsString(mergedJson);
  print('');
  print('📦 Saved: tools/merged_universities.json (${finalList.length} universities)');

  // ═══ 7. Генерируем lib/data/universities.dart ═══
  final String jsonString = jsonEncode(finalList);
  final String base64Data = base64Encode(utf8.encode(jsonString));

  final StringBuffer dartCode = StringBuffer();
  dartCode.writeln("// ⚠️ ПОЛНОСТЬЮ СГЕНЕРИРОВАННЫЙ ФАЙЛ — НЕ РЕДАКТИРОВАТЬ");
  dartCode.writeln("// 🚫 Запустите: dart run scripts/merge_all_sources.dart");
  dartCode.writeln("// 📊 ${finalList.length} universities | ${DateTime.now().toIso8601String()}");
  dartCode.writeln("import 'dart:convert';");
  dartCode.writeln("import 'package:flutter/foundation.dart';");
  dartCode.writeln("import '../models/university.dart';");
  dartCode.writeln("");
  dartCode.writeln("const String _b64 = '$base64Data';");
  dartCode.writeln("");
  dartCode.writeln("final List<University> universitiesList = _decodeUniversities();");
  dartCode.writeln("");
  dartCode.writeln("List<University> _decodeUniversities() {");
  dartCode.writeln("  try {");
  dartCode.writeln("    final rawJson = utf8.decode(base64Decode(_b64));");
  dartCode.writeln("    final List<dynamic> list = jsonDecode(rawJson);");
  dartCode.writeln("    return list.map((e) => University.fromMap(e as Map<String, dynamic>)).toList();");
  dartCode.writeln("  } catch (e) {");
  dartCode.writeln("    debugPrint('Error decoding universities: \$e');");
  dartCode.writeln("    return [];");
  dartCode.writeln("  }");
  dartCode.writeln("}");

  final File dartFile = File('lib/data/universities.dart');
  await dartFile.writeAsString(dartCode.toString());
  print('📦 Saved: lib/data/universities.dart (Base64 encoded)');

  // ═══ 8. Список городов ═══
  final Set<String> cities = {};
  for (final uni in finalList) {
    final String city = (uni['city'] ?? '').toString().trim();
    if (city.isNotEmpty) cities.add(city);
  }
  print('');
  print('🏙️  Уникальные города (${cities.length}): ${(cities.toList()..sort()).join(', ')}');

  print('');
  print('═══════════════════════════════════════════════════');
  print('✅ MERGE COMPLETE! Next steps:');
  print('   1. flutter pub get');
  print('   2. flutter analyze');
  print('   3. Upload to Firestore via admin panel');
  print('      or: use merged_universities.json with');
  print('      FirestoreUploadScript.uploadFromJsonFile()');
  print('═══════════════════════════════════════════════════');
}
