// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main() async {
  print('Running TANDAU unified university generator...');

  final orgFile = File('assets/higher_education_org1-v1.json');
  final denomFile = File('assets/bilim_beru_dengeileri_boiynsha1-v4.json');

  if (!orgFile.existsSync() || !denomFile.existsSync()) {
    print('❌ Error: Missing eGov JSON files in assets/');
    exit(1);
  }

  // Load datasets
  final orgDataRaw = jsonDecode(await orgFile.readAsString());
  final denomDataRaw = jsonDecode(await denomFile.readAsString());

  // Convert orgData to Map keyed by ID
  Map<String, Map<String, dynamic>> orgs = {};
  for (var item in orgDataRaw) {
    if (item['id'] != null) {
      orgs[item['id'].toString()] = item;
    }
  }

  print('Loaded ${orgs.length} base organizations.');

  List<Map<String, dynamic>> mergedList = [];
  int matched = 0;

  for (var dItem in denomDataRaw) {
    String denomId = dItem['id'].toString();
    var orgMatch = orgs[denomId];

    if (orgMatch != null) {
      matched++;
      // Construct University map
      final String rawName = dItem['nameoftheorganization']?.toString() ?? '';
      
      // Clean names naturally
      final String name = rawName.replaceAll(RegExp(r'\s+'), ' ').trim();
      final String city = dItem['nameoftheregion']?.toString() ?? orgMatch['region_nam']?.toString() ?? '';
      final String address = dItem['legaladdress']?.toString() ?? orgMatch['address']?.toString() ?? '';
      final String phone = dItem['contactphonenumber']?.toString() ?? '';
      final num students = num.tryParse(orgMatch['number_stu']?.toString() ?? '0') ?? 0;

      // Ensure city looks good (e.g. "город Астана" -> "Астана")
      String cleanCity = city.replaceAll("город ", "").replaceAll(" г.А.", "").replaceAll(" Г.А.", "").trim();

      Map<String, dynamic> uniMap = {
        'id': denomId,
        'name': name,
        'city': cleanCity,
        'logoUrl': '',
        'imageUrls': [],
        'majors': [],
        'passingScore': 50, // default
        'tuitionRange': '',
        'hasDormitory': false,
        'hasGrants': true,
        'description': 'Официальные данные eGov',
        'requirements': ['ЕНТ'],
        'applicationDeadline': '15-25 Июля',
        'address': address,
        'website': '',
        'studentCount': students.toInt(),
        'contactPhone': phone,
        'email': '',
        'averageRating': 0.0,
      };

      mergedList.add(uniMap);
    } else {
      // If denominative data has an ID not in orgs, we can still add it if needed
      final String rawName = dItem['nameoftheorganization']?.toString() ?? '';
      final String name = rawName.replaceAll(RegExp(r'\s+'), ' ').trim();
      final String city = dItem['nameoftheregion']?.toString() ?? '';
      final String address = dItem['legaladdress']?.toString() ?? '';
      final String phone = dItem['contactphonenumber']?.toString() ?? '';
      String cleanCity = city.replaceAll("город ", "").replaceAll(" г.А.", "").replaceAll(" Г.А.", "").trim();

      Map<String, dynamic> uniMap = {
        'id': denomId,
        'name': name,
        'city': cleanCity,
        'logoUrl': '',
        'imageUrls': [],
        'majors': [],
        'passingScore': 50,
        'tuitionRange': '',
        'hasDormitory': false,
        'hasGrants': true,
        'description': 'Официальные данные eGov',
        'requirements': ['ЕНТ'],
        'applicationDeadline': '15-25 Июля',
        'address': address,
        'website': '',
        'studentCount': 0,
        'contactPhone': phone,
        'email': '',
        'averageRating': 0.0,
      };
      mergedList.add(uniMap);
    }
  }

  print('Merged list contains ${mergedList.length} universities ($matched matched exactly).');

  // Generate safe Dart output using Base64 encoding to prevent ANY syntax errors
  final jsonString = jsonEncode(mergedList);
  final base64Data = base64Encode(utf8.encode(jsonString));

  final StringBuffer dartCode = StringBuffer();
  dartCode.writeln('// ⚠️ ПОЛНОСТЬЮ СГЕНЕРИРОВАННЫЙ ФАЙЛ');
  dartCode.writeln('// 🚫 НЕ ИЗМЕНЯТЬ ВРУЧНУЮ! Запустите `dart lib/scripts/generate_universities_data.dart`');
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

  final outFile = File('lib/data/universities.dart');
  await outFile.writeAsString(dartCode.toString());
  print('✅ Successfully wrote ${mergedList.length} universities to lib/data/universities.dart (Safe Base64 encoded)');
}
