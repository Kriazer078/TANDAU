import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/ent_specialties_2026.dart';
import 'auth_service.dart';
import 'locale_manager.dart';

/// 💬 Модель описания специальности
class SpecialtyDescription {
  final String code;
  final String descriptionRu;
  final String descriptionKk;
  final String descriptionEn;
  final List<String> careerExamples;
  final List<String> workplaces;

  const SpecialtyDescription({
    required this.code,
    required this.descriptionRu,
    required this.descriptionKk,
    required this.descriptionEn,
    required this.careerExamples,
    required this.workplaces,
  });

  /// Получить описание по языку
  String getDescription(String langCode) {
    switch (langCode) {
      case 'kk':
        return descriptionKk;
      case 'en':
        return descriptionEn;
      default:
        return descriptionRu;
    }
  }

  factory SpecialtyDescription.fromJson(Map<String, dynamic> json) {
    return SpecialtyDescription(
      code: json['code'] as String? ?? '',
      descriptionRu: json['descriptionRu'] as String? ?? '',
      descriptionKk: json['descriptionKk'] as String? ?? '',
      descriptionEn: json['descriptionEn'] as String? ?? '',
      careerExamples: List<String>.from(json['careerExamples'] ?? []),
      workplaces: List<String>.from(json['workplaces'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'descriptionRu': descriptionRu,
        'descriptionKk': descriptionKk,
        'descriptionEn': descriptionEn,
        'careerExamples': careerExamples,
        'workplaces': workplaces,
      };
}

/// 🔧 Сервис описаний специальностей
///
/// - Использует AI backend для генерации описаний
/// - Кэширует результаты в памяти
/// - Фоллбэк: статические описания для популярных ГОП
class SpecialtyDescriptionService {
  static final SpecialtyDescriptionService _instance =
      SpecialtyDescriptionService._internal();
  factory SpecialtyDescriptionService() => _instance;
  SpecialtyDescriptionService._internal();

  static const String _baseUrl = 'https://tandau-backend.onrender.com/api/v1';

  /// Кэш описаний (code → description)
  final Map<String, SpecialtyDescription> _cache = {};

  /// Состояние загрузки (code → loading)
  final Map<String, bool> _loading = {};

  /// ValueNotifier для UI (code → description) — сигнал обновления
  final ValueNotifier<int> updateSignal = ValueNotifier<int>(0);

  /// Получить описание (из кэша или fallback)
  SpecialtyDescription? getDescription(String code) {
    return _cache[code] ?? _staticDescriptions[code];
  }

  /// Загрузить описание через AI
  Future<SpecialtyDescription?> loadDescription(EntSpecialty specialty) async {
    final code = specialty.code;

    // Если уже в кэше — вернуть
    if (_cache.containsKey(code)) return _cache[code]!;

    // Если уже грузится — не дублировать
    if (_loading[code] == true) return _staticDescriptions[code];

    _loading[code] = true;

    try {
      final language =
          LocaleManager().locale.value?.languageCode ?? 'ru';

      final currentUser = AuthService().currentUser.value;
      final bodyData = <String, dynamic>{
        'question':
            'Объясни простыми словами для абитуриента специальность '
            '"${specialty.titleRu}" (код ${specialty.code}). '
            'Ответ строго в JSON формате:\n'
            '{\n'
            '  "descriptionRu": "1-2 предложения простым языком что это за специальность",\n'
            '  "descriptionKk": "то же на казахском",\n'
            '  "descriptionEn": "то же на английском",\n'
            '  "careerExamples": ["Профессия — 200-500К ₸", "Профессия2 — 300-600К ₸"],\n'
            '  "workplaces": ["Компания1", "Сфера2", "Компания3"]\n'
            '}\n'
            'Данные должны быть релевантны рынку труда Казахстана (hh.kz, enbek.kz). '
            'Зарплаты в тенге, диапазон. '
            'Ответь ТОЛЬКО JSON, без markdown.',
        'language': language,
      };

      if (currentUser != null) {
        bodyData['uid'] = currentUser.uid;
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(bodyData),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final answer = data['answer'] as String? ?? '';

        // Пытаемся извлечь JSON из ответа
        final parsed = _extractJson(answer);
        if (parsed != null) {
          parsed['code'] = code;
          final desc = SpecialtyDescription.fromJson(parsed);
          _cache[code] = desc;
          updateSignal.value++;
          return desc;
        }
      }
    } catch (e, stack) {
      debugPrint('SpecialtyDescriptionService error for $code: $e');
      debugPrint('$stack');
    } finally {
      _loading[code] = false;
    }

    // Fallback → статика
    return _staticDescriptions[code];
  }

  /// Извлечь JSON из строки (AI может обернуть в ```)
  Map<String, dynamic>? _extractJson(String text) {
    try {
      // Пробуем парсить напрямую
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {}

    // Ищем JSON в markdown ```json ... ```
    final jsonBlockRegex = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```');
    final match = jsonBlockRegex.firstMatch(text);
    if (match != null) {
      try {
        return jsonDecode(match.group(1)!) as Map<String, dynamic>;
      } catch (_) {}
    }

    // Ищем {...} в тексте
    final braceStart = text.indexOf('{');
    final braceEnd = text.lastIndexOf('}');
    if (braceStart != -1 && braceEnd > braceStart) {
      try {
        return jsonDecode(text.substring(braceStart, braceEnd + 1))
            as Map<String, dynamic>;
      } catch (_) {}
    }

    return null;
  }

  /// Статические описания для популярных ГОП (без AI)
  static final Map<String, SpecialtyDescription> _staticDescriptions = {
    'B057': const SpecialtyDescription(
      code: 'B057',
      descriptionRu:
          'Программисты-разработчики: создают сайты, мобильные приложения, '
          'системы на основе ИИ и автоматизации.',
      descriptionKk:
          'Бағдарламашы-жасақтаушылар: сайттар, мобильді қосымшалар, '
          'ЖИ жүйелерін жасайды.',
      descriptionEn:
          'Software developers who build websites, mobile apps, '
          'AI systems and automation.',
      careerExamples: [
        'Frontend-разработчик — 300–600К ₸',
        'Backend-разработчик — 400–800К ₸',
        'Data Engineer — 500–900К ₸',
        'Mobile-разработчик — 400–700К ₸',
      ],
      workplaces: ['Kaspi.kz', 'BTS Digital', 'Kolesa Group', 'Стартапы'],
    ),
    'B058': const SpecialtyDescription(
      code: 'B058',
      descriptionRu:
          'Защита от хакеров и кибератак. Специалисты контролируют '
          'безопасность банков, госсистем и IT-компаний.',
      descriptionKk:
          'Хакерлер мен кибершабуылдардан қорғау. Банктер, мемлекеттік '
          'жүйелер мен IT-компаниялардың қауіпсіздігін қамтамасыз етеді.',
      descriptionEn:
          'Cybersecurity experts who protect banks, government systems '
          'and companies from hackers.',
      careerExamples: [
        'Пентестер — 400–700К ₸',
        'SOC-аналитик — 350–600К ₸',
        'Инженер ИБ — 500–900К ₸',
      ],
      workplaces: ['Halyk Bank', 'eGov', 'Beeline', 'Kaspersky'],
    ),
    'B059': const SpecialtyDescription(
      code: 'B059',
      descriptionRu:
          'Связь и телекоммуникации: настройка сетей, 5G, '
          'интернет-инфраструктура и спутниковая связь.',
      descriptionKk:
          'Байланыс жүйелері: 5G, желілер, интернет-инфрақұрылым '
          'және спутниктік байланыс.',
      descriptionEn:
          'Telecommunications: network setup, 5G, internet infrastructure '
          'and satellite communications.',
      careerExamples: [
        'Сетевой инженер — 350–600К ₸',
        'RF-инженер — 400–700К ₸',
      ],
      workplaces: ['Kcell', 'Beeline', 'Казтелеком', 'Tele2'],
    ),
    'B060': const SpecialtyDescription(
      code: 'B060',
      descriptionRu:
          'Проектирование зданий, мостов и дорог. '
          'От жилых домов до небоскрёбов.',
      descriptionKk:
          'Ғимараттар, көпірлер, жолдар жобалау — тұрғын үйлерден '
          'зәулім ғимараттарға дейін.',
      descriptionEn:
          'Designing buildings, bridges and roads — from houses '
          'to skyscrapers.',
      careerExamples: [
        'Инженер-конструктор — 300–600К ₸',
        'Архитектор — 350–700К ₸',
        'BIM-специалист — 400–800К ₸',
      ],
      workplaces: ['BI Group', 'Базис-А', 'Sigma', 'QazaqStroy'],
    ),
    'B001': const SpecialtyDescription(
      code: 'B001',
      descriptionRu:
          'Учителя начальных классов, педагоги-воспитатели. '
          'Работают с детьми от 6 до 10 лет в школах.',
      descriptionKk:
          'Бастауыш сынып мұғалімдері, тәрбиешілер. '
          'Мектептерде 6-10 жас аралығындағы балалармен жұмыс істейді.',
      descriptionEn:
          'Primary school teachers and educators who work '
          'with children aged 6-10.',
      careerExamples: [
        'Учитель начальных классов — 200–350К ₸',
        'Педагог-воспитатель — 180–280К ₸',
      ],
      workplaces: ['Школы', 'Гимназии', 'Частные школы', 'НИШ'],
    ),
    'B004': const SpecialtyDescription(
      code: 'B004',
      descriptionRu:
          'Учителя физики, математики, информатики, химии и биологии '
          'в средней школе. Самые востребованные педагоги.',
      descriptionKk:
          'Орта мектептегі физика, математика, информатика, химия '
          'және биология мұғалімдері.',
      descriptionEn:
          'Secondary school teachers of physics, math, CS, '
          'chemistry and biology.',
      careerExamples: [
        'Учитель информатики — 250–400К ₸',
        'Учитель математики — 230–350К ₸',
      ],
      workplaces: ['Школы', 'НИШ', 'BilimLand', 'Онлайн-школы'],
    ),
    'B049': const SpecialtyDescription(
      code: 'B049',
      descriptionRu:
          'Юристы в сфере бизнеса и государства: составляют договоры, '
          'защищают права, консультируют компании.',
      descriptionKk:
          'Бизнес және мемлекет саласындағы заңгерлер: шарттар жасайды, '
          'құқықтарды қорғайды, компанияларға кеңес береді.',
      descriptionEn:
          'Lawyers in business and government law: draft contracts, '
          'protect rights, advise companies.',
      careerExamples: [
        'Корпоративный юрист — 400–800К ₸',
        'Адвокат — 350–700К ₸',
        'Нотариус — 300–600К ₸',
      ],
      workplaces: ['KPMG', 'Deloitte', 'Банки', 'Юридические фирмы'],
    ),
    'B044': const SpecialtyDescription(
      code: 'B044',
      descriptionRu:
          'Менеджеры и предприниматели: управляют бизнесом, '
          'запускают стартапы, руководят командами.',
      descriptionKk:
          'Менеджерлер мен кәсіпкерлер: бизнесті басқарады, '
          'стартаптар ашады, командаларды басқарады.',
      descriptionEn:
          'Managers and entrepreneurs: run businesses, '
          'launch startups, lead teams.',
      careerExamples: [
        'Менеджер проектов — 400–700К ₸',
        'Продакт-менеджер — 500–900К ₸',
        'Предприниматель — 300К–∞ ₸',
      ],
      workplaces: ['Kaspi', 'Freedom', 'Chocofamily', 'Стартапы'],
    ),
    'B042': const SpecialtyDescription(
      code: 'B042',
      descriptionRu:
          'Психологи помогают людям преодолевать трудности, '
          'работают в школах, клиниках и HR-отделах.',
      descriptionKk:
          'Психологтар адамдарға қиындықтарды жеңуге көмектеседі, '
          'мектептерде, клиникаларда және HR бөлімдерінде жұмыс істейді.',
      descriptionEn:
          'Psychologists help people overcome challenges, '
          'work in schools, clinics and HR departments.',
      careerExamples: [
        'Клинический психолог — 250–500К ₸',
        'HR-психолог — 300–500К ₸',
        'Школьный психолог — 200–350К ₸',
      ],
      workplaces: ['Клиники', 'Школы', 'HR-отделы', 'Частная практика'],
    ),
    'B047': const SpecialtyDescription(
      code: 'B047',
      descriptionRu:
          'Экономисты анализируют деньги, рынки и финансы: '
          'работают в банках, фондах и госорганах.',
      descriptionKk:
          'Экономистер ақшаны, нарықтарды талдайды: '
          'банктерде, қорларда, мемлекеттік органдарда жұмыс істейді.',
      descriptionEn:
          'Economists analyze money, markets and finance, '
          'working in banks, funds and government.',
      careerExamples: [
        'Финансовый аналитик — 350–700К ₸',
        'Экономист — 300–500К ₸',
        'Аудитор — 400–800К ₸',
      ],
      workplaces: ['Нацбанк', 'Halyk Bank', 'Big4', 'АИФР'],
    ),
    'B065': const SpecialtyDescription(
      code: 'B065',
      descriptionRu:
          'Нефтяники и газовики: работают на месторождениях, '
          'управляют добычей нефти и газа.',
      descriptionKk:
          'Мұнайшылар мен газшылар: кен орындарында жұмыс істейді, '
          'мұнай мен газ өндірісін басқарады.',
      descriptionEn:
          'Oil and gas engineers who work at fields and manage '
          'extraction operations.',
      careerExamples: [
        'Инженер по бурению — 500–1200К ₸',
        'Геолог — 400–800К ₸',
        'Технолог НПЗ — 450–900К ₸',
      ],
      workplaces: ['КазМунайГаз', 'Tengizchevroil', 'CNPC', 'Shell'],
    ),
    'B070': const SpecialtyDescription(
      code: 'B070',
      descriptionRu:
          'Врачи, которые лечат людей: от терапевтов до хирургов. '
          '6 лет учёбы + 2 года резидентуры.',
      descriptionKk:
          'Адамдарды емдейтін дәрігерлер: терапевттерден '
          'хирургтарға дейін. 6 жыл оқу + 2 жыл резидентура.',
      descriptionEn:
          'Medical doctors: from GPs to surgeons. '
          '6 years of study + 2 years residency.',
      careerExamples: [
        'Терапевт — 250–450К ₸',
        'Хирург — 400–900К ₸',
        'Анестезиолог — 500–1000К ₸',
      ],
      workplaces: ['Городские больницы', 'Частные клиники', 'НИИ'],
    ),
    'B074': const SpecialtyDescription(
      code: 'B074',
      descriptionRu:
          'Фармацевты разрабатывают и продают лекарства, '
          'работают в аптеках и фармкомпаниях.',
      descriptionKk:
          'Фармацевтер дәрі-дәрмектерді жасайды және сатады, '
          'дәріханаларда жұмыс істейді.',
      descriptionEn:
          'Pharmacists develop and sell medicines, '
          'work in pharmacies and pharma companies.',
      careerExamples: [
        'Фармацевт — 250–400К ₸',
        'Фармаколог — 350–600К ₸',
      ],
      workplaces: ['Аптеки', 'Santo', 'Nobel', 'Фармкомпании'],
    ),
    'B031': const SpecialtyDescription(
      code: 'B031',
      descriptionRu:
          'Дизайнеры создают визуальный стиль брендов, '
          'интерьеры, одежду и цифровые продукты.',
      descriptionKk:
          'Дизайнерлер брендтердің визуалды стилін, интерьерлерді, '
          'киімдерді және цифрлық өнімдерді жасайды.',
      descriptionEn:
          'Designers create brand visuals, interiors, '
          'fashion and digital products.',
      careerExamples: [
        'UI/UX дизайнер — 350–700К ₸',
        'Графический дизайнер — 250–500К ₸',
        'Дизайнер интерьера — 300–600К ₸',
      ],
      workplaces: ['Студии дизайна', 'IT-компании', 'Фриланс', 'Рекламные агентства'],
    ),
    'B046': const SpecialtyDescription(
      code: 'B046',
      descriptionRu:
          'Финансисты управляют деньгами компаний и людей: '
          'инвестиции, бухгалтерия, аудит, страхование.',
      descriptionKk:
          'Қаржыгерлер компаниялар мен адамдардың ақшасын басқарады: '
          'инвестициялар, бухгалтерия, аудит, сақтандыру.',
      descriptionEn:
          'Finance professionals manage money: investments, '
          'accounting, audit and insurance.',
      careerExamples: [
        'Финансовый аналитик — 400–800К ₸',
        'Бухгалтер — 250–400К ₸',
        'Инвестиционный аналитик — 500–1000К ₸',
      ],
      workplaces: ['Freedom Finance', 'Halyk Bank', 'PwC', 'Банки'],
    ),
  };

  /// Найти специальность по коду
  EntSpecialty? findSpecialty(String code) {
    try {
      return entSpecialties2026.firstWhere((s) => s.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Найти ГОП по названию major из Firestore
  EntSpecialty? findByMajorTitle(String majorTitle) {
    final lower = majorTitle.toLowerCase().trim();
    try {
      return entSpecialties2026.firstWhere(
        (s) =>
            s.titleRu.toLowerCase() == lower ||
            s.titleKk.toLowerCase() == lower ||
            s.titleEn.toLowerCase() == lower ||
            lower.contains(s.titleRu.toLowerCase()) ||
            s.titleRu.toLowerCase().contains(lower),
      );
    } catch (_) {
      return null;
    }
  }

  /// Есть ли описание (кэш или статика)?
  bool hasDescription(String code) {
    return _cache.containsKey(code) ||
        _staticDescriptions.containsKey(code);
  }

  /// Очистить кэш
  void clearCache() {
    _cache.clear();
    updateSignal.value++;
  }
}
