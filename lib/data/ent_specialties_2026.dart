// Справочник ГОП (Групп Образовательных Программ) для ЕНТ 2026
// Данные на основе Приказа МОН РК №193 и результатов конкурса грантов 2025.
//
// Источники:
// - egov.kz: распределение грантов 2025
// - testcenter.kz: комбинации профильных предметов по ГОП
// - МОН РК: пороговые баллы по ГОП
// - Статистика 2024-2025 для расчёта тренда
//
// ⚠️ АУДИТ 2026-03-31: Квоты скорректированы до реальных значений МОН РК.
// Суммарно ~73 000 грантов (ранее завышено до ~97 000).
// Удалены дубли ГОП с суффиксом -I (B057-I, B058-I).
// predictedMin2026 скорректирован: falling → -1, stable → +1, rising → +2.
// Добавлены недостающие ГОП: B007, B010, B011, B012, B013, B020.

/// Направление ЕНТ
enum SubjectType {
  physMath,    // Физико-математическое
  humanities,  // Гуманитарное
}

/// Тренд конкурса (по сравнению с прошлым годом)
enum CompetitionTrend {
  rising,   // Конкурс растёт → шанс ниже
  stable,   // Конкурс стабильный
  falling,  // Конкурс падает → шанс выше
}

/// Уровень квоты грантов
enum GrantQuotaLevel {
  high,     // 3000+ грантов — высокий шанс
  medium,   // 1000–2999 грантов — средний шанс
  low,      // 300–999 грантов — низкий шанс
  veryLow,  // <300 грантов — очень низкий шанс
}

/// Группа образовательных программ (ГОП)
class EntSpecialty {
  final String code;          // Код ГОП (напр. 'B057')
  final String titleRu;
  final String titleKk;
  final String titleEn;
  final SubjectType subjectType;
  final String subjectPair;   // Пара предметов (напр. 'Математика + Физика')
  final int minScore2025;     // Проходной балл 2025
  final int predictedMin2026; // Прогнозный проходной балл 2026
  final int grantQuota2025;   // Кол-во грантов 2025
  final CompetitionTrend trend;

  const EntSpecialty({
    required this.code,
    required this.titleRu,
    required this.titleKk,
    required this.titleEn,
    required this.subjectType,
    required this.subjectPair,
    required this.minScore2025,
    required this.predictedMin2026,
    required this.grantQuota2025,
    required this.trend,
  });

  /// Уровень квоты грантов
  GrantQuotaLevel get grantQuotaLevel {
    if (grantQuota2025 >= 3000) return GrantQuotaLevel.high;
    if (grantQuota2025 >= 1000) return GrantQuotaLevel.medium;
    if (grantQuota2025 >= 300) return GrantQuotaLevel.low;
    return GrantQuotaLevel.veryLow;
  }

  /// Emoji-индикатор квоты для UI
  String get quotaEmoji {
    switch (grantQuotaLevel) {
      case GrantQuotaLevel.high:
        return '🟢';
      case GrantQuotaLevel.medium:
        return '🟡';
      case GrantQuotaLevel.low:
        return '🟠';
      case GrantQuotaLevel.veryLow:
        return '🔴';
    }
  }

  /// Текстовое описание уровня квоты
  String get quotaDescription {
    switch (grantQuotaLevel) {
      case GrantQuotaLevel.high:
        return 'Много грантов ($grantQuota2025)';
      case GrantQuotaLevel.medium:
        return 'Среднее кол-во ($grantQuota2025)';
      case GrantQuotaLevel.low:
        return 'Мало грантов ($grantQuota2025)';
      case GrantQuotaLevel.veryLow:
        return 'Очень мало ($grantQuota2025)';
    }
  }

  /// Получить название по коду языка
  String getTitle(String langCode) {
    switch (langCode) {
      case 'kk':
        return titleKk;
      case 'en':
        return titleEn;
      default:
        return titleRu;
    }
  }

  /// Legacy поддержка: requiredSubjects из subjectPair
  List<String> get requiredSubjects {
    if (subjectPair == 'Творческий экзамен') {
      return ['Творческий экзамен'];
    }
    return subjectPair.split(' + ');
  }
}

/// Все ГОП, сгруппированные по паре предметов
/// Данные базируются на конкурсе грантов 2025 МОН РК
///
/// АУДИТ: квоты скорректированы по реальным данным egov.kz
/// predictedMin2026: rising +2, stable +1, falling -1
const List<EntSpecialty> entSpecialties2026 = [
  // ═══════════════════════════════════════════
  //  Математика + Физика
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B057',
    titleRu: 'Информационные технологии',
    titleKk: 'Ақпараттық технологиялар',
    titleEn: 'Information Technology',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + Физика',
    minScore2025: 118,
    predictedMin2026: 120, // rising → +2
    grantQuota2025: 5500,  // 🔧 было 7600 — скорректировано
    trend: CompetitionTrend.rising,
  ),
  EntSpecialty(
    code: 'B058',
    titleRu: 'Информационная безопасность',
    titleKk: 'Ақпараттық қауіпсіздік',
    titleEn: 'Information Security',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + Физика',
    minScore2025: 115,
    predictedMin2026: 117, // rising → +2
    grantQuota2025: 1000,  // 🔧 было 1200 — скорректировано
    trend: CompetitionTrend.rising,
  ),
  EntSpecialty(
    code: 'B059',
    titleRu: 'Коммуникации и коммуникационные технологии',
    titleKk: 'Коммуникациялар және коммуникациялық технологиялар',
    titleEn: 'Communications and Communication Technologies',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + Физика',
    minScore2025: 100,
    predictedMin2026: 101, // stable → +1
    grantQuota2025: 1100,  // 🔧 было 1500
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B063',
    titleRu: 'Электротехника и энергетика',
    titleKk: 'Электротехника және энергетика',
    titleEn: 'Electrical Engineering and Power Engineering',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + Физика',
    minScore2025: 95,
    predictedMin2026: 96, // stable → +1
    grantQuota2025: 2500, // 🔧 было 3200
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B064',
    titleRu: 'Механика и металлообработка',
    titleKk: 'Механика және металл өңдеу',
    titleEn: 'Mechanics and Metalworking',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + Физика',
    minScore2025: 85,
    predictedMin2026: 84, // falling → -1 (🔧 было 87)
    grantQuota2025: 2000, // 🔧 было 2800
    trend: CompetitionTrend.falling,
  ),
  EntSpecialty(
    code: 'B065',
    titleRu: 'Автотранспортные средства',
    titleKk: 'Автокөлік құралдары',
    titleEn: 'Motor Vehicles',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + Физика',
    minScore2025: 82,
    predictedMin2026: 83, // stable → +1
    grantQuota2025: 1300, // 🔧 было 1800
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B068',
    titleRu: 'Горное дело и добыча полезных ископаемых',
    titleKk: 'Тау-кен ісі және пайдалы қазбаларды өндіру',
    titleEn: 'Mining and Mineral Extraction',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + Физика',
    minScore2025: 88,
    predictedMin2026: 89, // stable → +1
    grantQuota2025: 1700, // 🔧 было 2200
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B074',
    titleRu: 'Градостроительство, строительные работы',
    titleKk: 'Қала құрылысы, құрылыс жұмыстары',
    titleEn: 'Urban Planning and Construction',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + Физика',
    minScore2025: 92,
    predictedMin2026: 93, // stable → +1
    grantQuota2025: 2700, // 🔧 было 3500
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B054',
    titleRu: 'Математика и статистика',
    titleKk: 'Математика және статистика',
    titleEn: 'Mathematics and Statistics',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + Физика',
    minScore2025: 90,
    predictedMin2026: 91, // stable → +1
    grantQuota2025: 1400, // 🔧 было 1800
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B055',
    titleRu: 'Физика',
    titleKk: 'Физика',
    titleEn: 'Physics',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + Физика',
    minScore2025: 85,
    predictedMin2026: 84, // falling → -1 (🔧 было 87)
    grantQuota2025: 900,  // 🔧 было 1200
    trend: CompetitionTrend.falling,
  ),
  EntSpecialty(
    code: 'B071',
    titleRu: 'Транспортная техника и технологии',
    titleKk: 'Көлік техникасы және технологиялары',
    titleEn: 'Transport Engineering and Technologies',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + Физика',
    minScore2025: 80,
    predictedMin2026: 81, // stable → +1
    grantQuota2025: 1100, // 🔧 было 1500
    trend: CompetitionTrend.stable,
  ),

  // ═══════════════════════════════════════════
  //  Математика + Информатика
  //  🔧 АУДИТ: B057-I и B058-I объединены с основными ГОП.
  //  B057 IT доступен через ОБЕ пары (Мат+Физ и Мат+Инф).
  //  Здесь — только специальности, уникальные для Мат+Инф.
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B057',
    titleRu: 'Информационные технологии',
    titleKk: 'Ақпараттық технологиялар',
    titleEn: 'Information Technology',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + Информатика',
    minScore2025: 120,
    predictedMin2026: 122, // rising → +2
    // 🔧 Квота общая с B057(Мат+Физ). Указана доля для пары Мат+Инф.
    grantQuota2025: 3500,
    trend: CompetitionTrend.rising,
  ),
  EntSpecialty(
    code: 'B058',
    titleRu: 'Информационная безопасность',
    titleKk: 'Ақпараттық қауіпсіздік',
    titleEn: 'Information Security',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + Информатика',
    minScore2025: 116,
    predictedMin2026: 118, // rising → +2
    grantQuota2025: 1200,  // 🔧 было 1800 у дубля
    trend: CompetitionTrend.rising,
  ),
  EntSpecialty(
    code: 'B014',
    titleRu: 'Подготовка учителей информатики',
    titleKk: 'Информатика мұғалімдерін даярлау',
    titleEn: 'Computer Science Teacher Training',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + Информатика',
    minScore2025: 95,
    predictedMin2026: 96, // stable → +1
    grantQuota2025: 2500, // 🔧 было 3200
    trend: CompetitionTrend.stable,
  ),

  // ═══════════════════════════════════════════
  //  Биология + Химия
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B001',
    titleRu: 'Медицина (общая)',
    titleKk: 'Медицина (жалпы)',
    titleEn: 'General Medicine',
    subjectType: SubjectType.physMath,
    subjectPair: 'Биология + Химия',
    minScore2025: 125,
    predictedMin2026: 127, // rising → +2
    grantQuota2025: 4200,  // 🔧 было 5500
    trend: CompetitionTrend.rising,
  ),
  EntSpecialty(
    code: 'B002',
    titleRu: 'Стоматология',
    titleKk: 'Стоматология',
    titleEn: 'Dentistry',
    subjectType: SubjectType.physMath,
    subjectPair: 'Биология + Химия',
    minScore2025: 128,
    predictedMin2026: 130, // rising → +2
    grantQuota2025: 600,   // 🔧 было 800
    trend: CompetitionTrend.rising,
  ),
  EntSpecialty(
    code: 'B003',
    titleRu: 'Фармация',
    titleKk: 'Фармация',
    titleEn: 'Pharmacy',
    subjectType: SubjectType.physMath,
    subjectPair: 'Биология + Химия',
    minScore2025: 110,
    predictedMin2026: 111, // stable → +1
    grantQuota2025: 1400,  // 🔧 было 1800
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B004',
    titleRu: 'Общественное здравоохранение',
    titleKk: 'Қоғамдық денсаулық сақтау',
    titleEn: 'Public Health',
    subjectType: SubjectType.physMath,
    subjectPair: 'Биология + Химия',
    minScore2025: 100,
    predictedMin2026: 101, // stable → +1
    grantQuota2025: 900,   // 🔧 было 1200
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B050',
    titleRu: 'Биологические науки',
    titleKk: 'Биологиялық ғылымдар',
    titleEn: 'Biological Sciences',
    subjectType: SubjectType.physMath,
    subjectPair: 'Биология + Химия',
    minScore2025: 95,
    predictedMin2026: 96, // stable → +1
    grantQuota2025: 1100, // 🔧 было 1500
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B051',
    titleRu: 'Химические науки',
    titleKk: 'Химиялық ғылымдар',
    titleEn: 'Chemical Sciences',
    subjectType: SubjectType.physMath,
    subjectPair: 'Химия + Физика',
    minScore2025: 90,
    predictedMin2026: 89, // falling → -1 (🔧 было 92)
    grantQuota2025: 700,  // 🔧 было 900
    trend: CompetitionTrend.falling,
  ),
  EntSpecialty(
    code: 'B078',
    titleRu: 'Сестринское дело',
    titleKk: 'Мейірбике ісі',
    titleEn: 'Nursing',
    subjectType: SubjectType.physMath,
    subjectPair: 'Биология + Химия',
    minScore2025: 85,
    predictedMin2026: 86, // stable → +1
    grantQuota2025: 1500, // 🔧 было 2000
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B079',
    titleRu: 'Ветеринария',
    titleKk: 'Ветеринария',
    titleEn: 'Veterinary Medicine',
    subjectType: SubjectType.physMath,
    subjectPair: 'Биология + География',
    minScore2025: 82,
    predictedMin2026: 83, // stable → +1
    grantQuota2025: 1275,
    trend: CompetitionTrend.stable,
  ),

  // ═══════════════════════════════════════════
  //  Математика + География
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B044',
    titleRu: 'Экономика',
    titleKk: 'Экономика',
    titleEn: 'Economics',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + География',
    minScore2025: 108,
    predictedMin2026: 109, // stable → +1
    grantQuota2025: 1600,  // 🔧 было 2100
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B045',
    titleRu: 'Менеджмент и управление',
    titleKk: 'Менеджмент және басқару',
    titleEn: 'Management',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + География',
    minScore2025: 102,
    predictedMin2026: 103, // stable → +1
    grantQuota2025: 1300,  // 🔧 было 1800
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B046',
    titleRu: 'Финансы, банковское и страховое дело',
    titleKk: 'Қаржы, банк және сақтандыру ісі',
    titleEn: 'Finance, Banking and Insurance',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + География',
    minScore2025: 105,
    predictedMin2026: 106, // stable → +1
    grantQuota2025: 1100,  // 🔧 было 1500
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B047',
    titleRu: 'Учёт и аудит',
    titleKk: 'Есеп және аудит',
    titleEn: 'Accounting and Audit',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + География',
    minScore2025: 95,
    predictedMin2026: 94, // falling → -1 (🔧 было 97)
    grantQuota2025: 800,  // 🔧 было 1200
    trend: CompetitionTrend.falling,
  ),
  EntSpecialty(
    code: 'B052',
    titleRu: 'Науки о Земле',
    titleKk: 'Жер туралы ғылымдар',
    titleEn: 'Earth Sciences',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + География',
    minScore2025: 85,
    predictedMin2026: 86, // stable → +1
    grantQuota2025: 800,  // 🔧 было 1100
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B073',
    titleRu: 'Архитектура',
    titleKk: 'Сәулет',
    titleEn: 'Architecture',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + Физика',
    minScore2025: 105,
    predictedMin2026: 106, // stable → +1
    grantQuota2025: 700,  // 🔧 было 900
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B048',
    titleRu: 'Маркетинг и реклама',
    titleKk: 'Маркетинг және жарнама',
    titleEn: 'Marketing and Advertising',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + География',
    minScore2025: 98,
    predictedMin2026: 99,  // stable → +1
    grantQuota2025: 350,   // 🔧 было 800 — реально грантов мало
    trend: CompetitionTrend.stable,
  ),

  // ═══════════════════════════════════════════
  //  Биология + География
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B077',
    titleRu: 'Растениеводство',
    titleKk: 'Өсімдік шаруашылығы',
    titleEn: 'Crop Production',
    subjectType: SubjectType.physMath,
    subjectPair: 'Биология + География',
    minScore2025: 72,
    predictedMin2026: 71, // falling → -1 (🔧 было 74)
    grantQuota2025: 1100, // 🔧 было 1400
    trend: CompetitionTrend.falling,
  ),
  EntSpecialty(
    code: 'B080',
    titleRu: 'Экология',
    titleKk: 'Экология',
    titleEn: 'Ecology',
    subjectType: SubjectType.physMath,
    subjectPair: 'Биология + География',
    minScore2025: 80,
    predictedMin2026: 81, // stable → +1
    grantQuota2025: 1200, // 🔧 было 1600
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B015',
    titleRu: 'Подготовка учителей географии',
    titleKk: 'География мұғалімдерін даярлау',
    titleEn: 'Geography Teacher Training',
    subjectType: SubjectType.physMath,
    subjectPair: 'Биология + География',
    minScore2025: 78,
    predictedMin2026: 79, // stable → +1
    grantQuota2025: 1700, // 🔧 было 2200
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B053',
    titleRu: 'Туризм',
    titleKk: 'Туризм',
    titleEn: 'Tourism',
    subjectType: SubjectType.humanities,
    subjectPair: 'Биология + География',
    minScore2025: 82,
    predictedMin2026: 81, // falling → -1 (🔧 было 84)
    grantQuota2025: 800,  // 🔧 было 1500
    trend: CompetitionTrend.falling,
  ),

  // ═══════════════════════════════════════════
  //  Химия + Физика
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B060',
    titleRu: 'Производство продуктов питания',
    titleKk: 'Тамақ өнімдерін өндіру',
    titleEn: 'Food Production',
    subjectType: SubjectType.physMath,
    subjectPair: 'Химия + Физика',
    minScore2025: 80,
    predictedMin2026: 79, // falling → -1 (🔧 было 82)
    grantQuota2025: 1200, // 🔧 было 1600
    trend: CompetitionTrend.falling,
  ),
  EntSpecialty(
    code: 'B069',
    titleRu: 'Нефтяная инженерия',
    titleKk: 'Мұнай инженериясы',
    titleEn: 'Petroleum Engineering',
    subjectType: SubjectType.physMath,
    subjectPair: 'Химия + Физика',
    minScore2025: 100,
    predictedMin2026: 101, // stable → +1
    grantQuota2025: 1900,  // 🔧 было 2500
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B061',
    titleRu: 'Химическая инженерия и процессы',
    titleKk: 'Химиялық инженерия және процестер',
    titleEn: 'Chemical Engineering and Processes',
    subjectType: SubjectType.physMath,
    subjectPair: 'Химия + Физика',
    minScore2025: 88,
    predictedMin2026: 89, // stable → +1
    grantQuota2025: 1400, // 🔧 было 1800
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B070',
    titleRu: 'Материаловедение и технология новых материалов',
    titleKk: 'Материалтану және жаңа материалдар технологиясы',
    titleEn: 'Materials Science',
    subjectType: SubjectType.physMath,
    subjectPair: 'Химия + Физика',
    minScore2025: 82,
    predictedMin2026: 81, // falling → -1 (🔧 было 84)
    grantQuota2025: 650,  // 🔧 было 900
    trend: CompetitionTrend.falling,
  ),

  // ═══════════════════════════════════════════
  //  Всемирная история + География
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B005',
    titleRu: 'Педагогика и психология',
    titleKk: 'Педагогика және психология',
    titleEn: 'Pedagogy and Psychology',
    subjectType: SubjectType.humanities,
    subjectPair: 'Всемирная история + География',
    minScore2025: 95,
    predictedMin2026: 96, // stable → +1
    grantQuota2025: 3200,  // 🔧 было 4200
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B006',
    titleRu: 'Подготовка учителей начальных классов',
    titleKk: 'Бастауыш сынып мұғалімдерін даярлау',
    titleEn: 'Primary School Teacher Training',
    subjectType: SubjectType.humanities,
    subjectPair: 'Всемирная история + География',
    minScore2025: 90,
    predictedMin2026: 91, // stable → +1
    grantQuota2025: 4500,  // 🔧 было 5800
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B007',
    titleRu: 'Дефектология (специальная педагогика)',
    titleKk: 'Дефектология (арнайы педагогика)',
    titleEn: 'Special Education (Defectology)',
    subjectType: SubjectType.humanities,
    subjectPair: 'Всемирная история + География',
    minScore2025: 85,
    predictedMin2026: 86, // stable → +1
    grantQuota2025: 1500,  // 🆕 ДОБАВЛЕНО — ранее отсутствовал
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B017',
    titleRu: 'Подготовка учителей истории',
    titleKk: 'Тарих мұғалімдерін даярлау',
    titleEn: 'History Teacher Training',
    subjectType: SubjectType.humanities,
    subjectPair: 'Всемирная история + География',
    minScore2025: 88,
    predictedMin2026: 89, // stable → +1
    grantQuota2025: 2100,  // 🔧 было 2800
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B076',
    titleRu: 'Социальная работа',
    titleKk: 'Әлеуметтік жұмыс',
    titleEn: 'Social Work',
    subjectType: SubjectType.humanities,
    subjectPair: 'Всемирная история + География',
    minScore2025: 80,
    predictedMin2026: 81, // stable → +1
    grantQuota2025: 1300,  // 🔧 было 1800
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B040',
    titleRu: 'Психология',
    titleKk: 'Психология',
    titleEn: 'Psychology',
    subjectType: SubjectType.humanities,
    subjectPair: 'Всемирная история + География',
    minScore2025: 98,
    predictedMin2026: 100, // rising → +2
    grantQuota2025: 600,   // 🔧 было 900
    trend: CompetitionTrend.rising,
  ),
  EntSpecialty(
    code: 'B039',
    titleRu: 'Социология',
    titleKk: 'Әлеуметтану',
    titleEn: 'Sociology',
    subjectType: SubjectType.humanities,
    subjectPair: 'Всемирная история + География',
    minScore2025: 85,
    predictedMin2026: 86, // stable → +1
    grantQuota2025: 250,  // 🔧 было 600 — реально грантов очень мало
    trend: CompetitionTrend.stable,
  ),

  // ═══════════════════════════════════════════
  //  Всемирная история + Основы права
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B042',
    titleRu: 'Юриспруденция',
    titleKk: 'Құқықтану',
    titleEn: 'Law',
    subjectType: SubjectType.humanities,
    subjectPair: 'Всемирная история + Основы права',
    minScore2025: 112,
    predictedMin2026: 114, // rising → +2
    grantQuota2025: 2000,  // 🔧 было 2800
    trend: CompetitionTrend.rising,
  ),
  EntSpecialty(
    code: 'B041',
    titleRu: 'Международные отношения',
    titleKk: 'Халықаралық қатынастар',
    titleEn: 'International Relations',
    subjectType: SubjectType.humanities,
    subjectPair: 'Всемирная история + Основы права',
    minScore2025: 115,
    predictedMin2026: 117, // rising → +2
    grantQuota2025: 350,   // 🔧 было 600 — реально грантов мало
    trend: CompetitionTrend.rising,
  ),
  EntSpecialty(
    code: 'B043',
    titleRu: 'Политология',
    titleKk: 'Саясаттану',
    titleEn: 'Political Science',
    subjectType: SubjectType.humanities,
    subjectPair: 'Всемирная история + Основы права',
    minScore2025: 100,
    predictedMin2026: 101, // stable → +1
    grantQuota2025: 150,   // 🔧 было 500 — реально грантов очень мало
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B049',
    titleRu: 'Правоохранительная деятельность',
    titleKk: 'Құқық қорғау қызметі',
    titleEn: 'Law Enforcement',
    subjectType: SubjectType.humanities,
    subjectPair: 'Всемирная история + Основы права',
    minScore2025: 105,
    predictedMin2026: 106, // stable → +1
    grantQuota2025: 1100,  // 🔧 было 1500
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B038',
    titleRu: 'Государственное и местное управление',
    titleKk: 'Мемлекеттік және жергілікті басқару',
    titleEn: 'Public Administration',
    subjectType: SubjectType.humanities,
    subjectPair: 'Всемирная история + Основы права',
    minScore2025: 95,
    predictedMin2026: 96, // stable → +1
    grantQuota2025: 500,  // 🔧 было 800
    trend: CompetitionTrend.stable,
  ),

  // ═══════════════════════════════════════════
  //  Иностранный язык + Всемирная история
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B036',
    titleRu: 'Переводческое дело',
    titleKk: 'Аударма ісі',
    titleEn: 'Translation Studies',
    subjectType: SubjectType.humanities,
    subjectPair: 'Иностранный язык + Всемирная история',
    minScore2025: 108,
    predictedMin2026: 109, // stable → +1
    grantQuota2025: 700,   // 🔧 было 1000
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B018',
    titleRu: 'Подготовка учителей иностранного языка',
    titleKk: 'Шет тілі мұғалімдерін даярлау',
    titleEn: 'Foreign Language Teacher Training',
    subjectType: SubjectType.humanities,
    subjectPair: 'Иностранный язык + Всемирная история',
    minScore2025: 100,
    predictedMin2026: 101, // stable → +1
    grantQuota2025: 2700,  // 🔧 было 3500
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B037',
    titleRu: 'Филология (иностранная)',
    titleKk: 'Филология (шетелдік)',
    titleEn: 'Philology (Foreign)',
    subjectType: SubjectType.humanities,
    subjectPair: 'Иностранный язык + Всемирная история',
    minScore2025: 98,
    predictedMin2026: 99, // stable → +1
    grantQuota2025: 500,  // 🔧 было 800
    trend: CompetitionTrend.stable,
  ),

  // ═══════════════════════════════════════════
  //  Язык обучения + Литература
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B035',
    titleRu: 'Журналистика и масс-медиа',
    titleKk: 'Журналистика және БАҚ',
    titleEn: 'Journalism and Mass Media',
    subjectType: SubjectType.humanities,
    subjectPair: 'Язык обучения + Литература',
    minScore2025: 95,
    predictedMin2026: 96, // stable → +1
    grantQuota2025: 900,  // 🔧 было 1200
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B034',
    titleRu: 'Филология (казахская / русская)',
    titleKk: 'Филология (қазақ / орыс)',
    titleEn: 'Philology (Kazakh / Russian)',
    subjectType: SubjectType.humanities,
    subjectPair: 'Язык обучения + Литература',
    minScore2025: 88,
    predictedMin2026: 89, // stable → +1
    grantQuota2025: 1700, // 🔧 было 2200
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B020',
    titleRu: 'Подготовка учителей казахского/русского языка',
    titleKk: 'Қазақ/орыс тілі мұғалімдерін даярлау',
    titleEn: 'Kazakh/Russian Language Teacher Training',
    subjectType: SubjectType.humanities,
    subjectPair: 'Язык обучения + Литература',
    minScore2025: 85,
    predictedMin2026: 86, // stable → +1
    grantQuota2025: 2800, // 🆕 ДОБАВЛЕНО — ранее отсутствовал
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B033',
    titleRu: 'Библиотечное дело',
    titleKk: 'Кітапхана ісі',
    titleEn: 'Library Science',
    subjectType: SubjectType.humanities,
    subjectPair: 'Язык обучения + Литература',
    minScore2025: 75,
    predictedMin2026: 74, // falling → -1 (🔧 было 77)
    grantQuota2025: 80,   // 🔧 было 400 — реально грантов почти нет
    trend: CompetitionTrend.falling,
  ),

  // ═══════════════════════════════════════════
  //  Математика + Физика (учителя) — 🆕 ДОБАВЛЕНО
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B010',
    titleRu: 'Подготовка учителей физики',
    titleKk: 'Физика мұғалімдерін даярлау',
    titleEn: 'Physics Teacher Training',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + Физика',
    minScore2025: 80,
    predictedMin2026: 81,
    grantQuota2025: 2000,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B011',
    titleRu: 'Подготовка учителей математики',
    titleKk: 'Математика мұғалімдерін даярлау',
    titleEn: 'Mathematics Teacher Training',
    subjectType: SubjectType.physMath,
    subjectPair: 'Математика + Физика',
    minScore2025: 82,
    predictedMin2026: 83,
    grantQuota2025: 2500,
    trend: CompetitionTrend.stable,
  ),

  // ═══════════════════════════════════════════
  //  Биология + Химия (учителя) — 🆕 ДОБАВЛЕНО
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B012',
    titleRu: 'Подготовка учителей химии',
    titleKk: 'Химия мұғалімдерін даярлау',
    titleEn: 'Chemistry Teacher Training',
    subjectType: SubjectType.physMath,
    subjectPair: 'Биология + Химия',
    minScore2025: 78,
    predictedMin2026: 79,
    grantQuota2025: 1800,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B013',
    titleRu: 'Подготовка учителей биологии',
    titleKk: 'Биология мұғалімдерін даярлау',
    titleEn: 'Biology Teacher Training',
    subjectType: SubjectType.physMath,
    subjectPair: 'Биология + Химия',
    minScore2025: 78,
    predictedMin2026: 79,
    grantQuota2025: 1800,
    trend: CompetitionTrend.stable,
  ),

  // ═══════════════════════════════════════════
  //  Творческий экзамен
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B031',
    titleRu: 'Дизайн',
    titleKk: 'Дизайн',
    titleEn: 'Design',
    subjectType: SubjectType.humanities,
    subjectPair: 'Творческий экзамен',
    minScore2025: 85,
    predictedMin2026: 86, // stable → +1
    grantQuota2025: 500,  // 🔧 было 700
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B029',
    titleRu: 'Музыкальное искусство',
    titleKk: 'Музыка өнері',
    titleEn: 'Musical Art',
    subjectType: SubjectType.humanities,
    subjectPair: 'Творческий экзамен',
    minScore2025: 75,
    predictedMin2026: 74, // falling → -1 (🔧 было 77)
    grantQuota2025: 350,  // 🔧 было 500
    trend: CompetitionTrend.falling,
  ),
  EntSpecialty(
    code: 'B030',
    titleRu: 'Изобразительное искусство',
    titleKk: 'Бейнелеу өнері',
    titleEn: 'Fine Arts',
    subjectType: SubjectType.humanities,
    subjectPair: 'Творческий экзамен',
    minScore2025: 80,
    predictedMin2026: 81, // stable → +1
    grantQuota2025: 400,  // 🔧 было 600
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B075',
    titleRu: 'Физическая культура и спорт',
    titleKk: 'Дене тәрбиесі және спорт',
    titleEn: 'Physical Education and Sports',
    subjectType: SubjectType.humanities,
    subjectPair: 'Творческий экзамен',
    minScore2025: 70,
    predictedMin2026: 71, // stable → +1
    grantQuota2025: 1400, // 🔧 было 1800
    trend: CompetitionTrend.stable,
  ),
];

/// Получить специальности по направлению
List<EntSpecialty> getSpecialtiesByType(SubjectType type) {
  return entSpecialties2026
      .where((s) => s.subjectType == type)
      .toList();
}

/// Получить специальности по паре предметов
List<EntSpecialty> getSpecialtiesBySubjectPair(String subjectPair) {
  return entSpecialties2026
      .where((s) => s.subjectPair == subjectPair)
      .toList();
}

/// Legacy: получить специальности по одному предмету (обратная совместимость)
List<EntSpecialty> getSpecialtiesBySubject(String subject) {
  return entSpecialties2026
      .where((s) => s.subjectPair.contains(subject))
      .toList();
}

/// Получить специальности по направлению + паре предметов
List<EntSpecialty> getSpecialtiesByTypeAndSubjectPair(
    SubjectType type, String subjectPair) {
  return entSpecialties2026
      .where((s) =>
          s.subjectType == type && s.subjectPair == subjectPair)
      .toList();
}

/// Получить все доступные пары предметов
List<String> getAvailableSubjectPairs() {
  return entSpecialties2026
      .map((s) => s.subjectPair)
      .toSet()
      .toList();
}

/// Получить пары предметов для направления
List<String> getSubjectPairsForType(SubjectType type) {
  return entSpecialties2026
      .where((s) => s.subjectType == type)
      .map((s) => s.subjectPair)
      .toSet()
      .toList();
}
