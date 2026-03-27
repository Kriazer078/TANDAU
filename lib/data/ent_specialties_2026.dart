// Справочник ГОП (Групп Образовательных Программ) для ЕНТ 2026
// Данные на основе Приказов МОН РК и результатов конкурса грантов 2025 года.
//
// Источники:
// - egov.kz: распределение грантов 2025
// - МОН РК: пороговые баллы по ГОП
// - Статистика 2024-2025 для расчёта тренда

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

/// Группа образовательных программ (ГОП)
class EntSpecialty {
  final String code;          // Код ГОП (напр. 'B057')
  final String titleRu;
  final String titleKk;
  final String titleEn;
  final SubjectType subjectType;
  final List<String> requiredSubjects; // Профильные предметы
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
    required this.requiredSubjects,
    required this.minScore2025,
    required this.predictedMin2026,
    required this.grantQuota2025,
    required this.trend,
  });

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
}

/// Все ГОП, сгруппированные по направлению и предметам
/// Данные базируются на конкурсе грантов 2025 МОН РК
const List<EntSpecialty> entSpecialties2026 = [
  // ═══════════════════════════════════════════
  //  ФИЗМАТ: Математика + Физика
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B057',
    titleRu: 'Информационные технологии',
    titleKk: 'Ақпараттық технологиялар',
    titleEn: 'Information Technology',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Математика', 'Физика'],
    minScore2025: 118,
    predictedMin2026: 120,
    grantQuota2025: 7600,
    trend: CompetitionTrend.rising,
  ),
  EntSpecialty(
    code: 'B058',
    titleRu: 'Информационная безопасность',
    titleKk: 'Ақпараттық қауіпсіздік',
    titleEn: 'Information Security',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Математика', 'Физика'],
    minScore2025: 115,
    predictedMin2026: 117,
    grantQuota2025: 1200,
    trend: CompetitionTrend.rising,
  ),
  EntSpecialty(
    code: 'B059',
    titleRu: 'Коммуникации и коммуникационные технологии',
    titleKk: 'Коммуникациялар және коммуникациялық технологиялар',
    titleEn: 'Communications and Communication Technologies',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Математика', 'Физика'],
    minScore2025: 100,
    predictedMin2026: 102,
    grantQuota2025: 1500,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B063',
    titleRu: 'Электротехника и энергетика',
    titleKk: 'Электротехника және энергетика',
    titleEn: 'Electrical Engineering and Power Engineering',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Математика', 'Физика'],
    minScore2025: 95,
    predictedMin2026: 97,
    grantQuota2025: 3200,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B064',
    titleRu: 'Механика и металлообработка',
    titleKk: 'Механика және металл өңдеу',
    titleEn: 'Mechanics and Metalworking',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Математика', 'Физика'],
    minScore2025: 85,
    predictedMin2026: 87,
    grantQuota2025: 2800,
    trend: CompetitionTrend.falling,
  ),
  EntSpecialty(
    code: 'B065',
    titleRu: 'Автотранспортные средства',
    titleKk: 'Автокөлік құралдары',
    titleEn: 'Motor Vehicles',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Математика', 'Физика'],
    minScore2025: 82,
    predictedMin2026: 84,
    grantQuota2025: 1800,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B068',
    titleRu: 'Горное дело и добыча полезных ископаемых',
    titleKk: 'Тау-кен ісі және пайдалы қазбаларды өндіру',
    titleEn: 'Mining and Mineral Extraction',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Математика', 'Физика'],
    minScore2025: 88,
    predictedMin2026: 90,
    grantQuota2025: 2200,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B074',
    titleRu: 'Градостроительство, строительные работы',
    titleKk: 'Қала құрылысы, құрылыс жұмыстары',
    titleEn: 'Urban Planning and Construction',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Математика', 'Физика'],
    minScore2025: 92,
    predictedMin2026: 94,
    grantQuota2025: 3500,
    trend: CompetitionTrend.stable,
  ),

  // ═══════════════════════════════════════════
  //  ФИЗМАТ: Математика + Информатика
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B057-I',
    titleRu: 'IT и программная инженерия',
    titleKk: 'IT және бағдарламалық инженерия',
    titleEn: 'IT and Software Engineering',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Математика', 'Информатика'],
    minScore2025: 120,
    predictedMin2026: 122,
    grantQuota2025: 4500,
    trend: CompetitionTrend.rising,
  ),

  // ═══════════════════════════════════════════
  //  ФИЗМАТ: Биология + Химия
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B001',
    titleRu: 'Медицина (общая)',
    titleKk: 'Медицина (жалпы)',
    titleEn: 'General Medicine',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Биология', 'Химия'],
    minScore2025: 125,
    predictedMin2026: 127,
    grantQuota2025: 5500,
    trend: CompetitionTrend.rising,
  ),
  EntSpecialty(
    code: 'B002',
    titleRu: 'Стоматология',
    titleKk: 'Стоматология',
    titleEn: 'Dentistry',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Биология', 'Химия'],
    minScore2025: 128,
    predictedMin2026: 130,
    grantQuota2025: 800,
    trend: CompetitionTrend.rising,
  ),
  EntSpecialty(
    code: 'B003',
    titleRu: 'Фармация',
    titleKk: 'Фармация',
    titleEn: 'Pharmacy',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Биология', 'Химия'],
    minScore2025: 110,
    predictedMin2026: 112,
    grantQuota2025: 1800,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B004',
    titleRu: 'Общественное здравоохранение',
    titleKk: 'Қоғамдық денсаулық сақтау',
    titleEn: 'Public Health',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Биология', 'Химия'],
    minScore2025: 100,
    predictedMin2026: 102,
    grantQuota2025: 1200,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B050',
    titleRu: 'Биологические науки',
    titleKk: 'Биологиялық ғылымдар',
    titleEn: 'Biological Sciences',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Биология', 'Химия'],
    minScore2025: 95,
    predictedMin2026: 97,
    grantQuota2025: 1500,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B051',
    titleRu: 'Химические науки',
    titleKk: 'Химиялық ғылымдар',
    titleEn: 'Chemical Sciences',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Биология', 'Химия'],
    minScore2025: 90,
    predictedMin2026: 92,
    grantQuota2025: 900,
    trend: CompetitionTrend.falling,
  ),

  // ═══════════════════════════════════════════
  //  ФИЗМАТ: Математика + География
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B052',
    titleRu: 'Науки о Земле',
    titleKk: 'Жер туралы ғылымдар',
    titleEn: 'Earth Sciences',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Математика', 'География'],
    minScore2025: 85,
    predictedMin2026: 87,
    grantQuota2025: 1100,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B073',
    titleRu: 'Архитектура',
    titleKk: 'Сәулет',
    titleEn: 'Architecture',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Математика', 'География'],
    minScore2025: 105,
    predictedMin2026: 107,
    grantQuota2025: 900,
    trend: CompetitionTrend.stable,
  ),

  // ═══════════════════════════════════════════
  //  ФИЗМАТ: Математика + Химия
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B060',
    titleRu: 'Производство продуктов питания',
    titleKk: 'Тамақ өнімдерін өндіру',
    titleEn: 'Food Production',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Математика', 'Химия'],
    minScore2025: 80,
    predictedMin2026: 82,
    grantQuota2025: 1600,
    trend: CompetitionTrend.falling,
  ),
  EntSpecialty(
    code: 'B069',
    titleRu: 'Нефтяная инженерия',
    titleKk: 'Мұнай инженериясы',
    titleEn: 'Petroleum Engineering',
    subjectType: SubjectType.physMath,
    requiredSubjects: ['Математика', 'Химия'],
    minScore2025: 100,
    predictedMin2026: 102,
    grantQuota2025: 2500,
    trend: CompetitionTrend.stable,
  ),

  // ═══════════════════════════════════════════
  //  ГУМАНИТАРИЙ: Всемирная история
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B005',
    titleRu: 'Педагогика и психология',
    titleKk: 'Педагогика және психология',
    titleEn: 'Pedagogy and Psychology',
    subjectType: SubjectType.humanities,
    requiredSubjects: ['Всемирная история'],
    minScore2025: 95,
    predictedMin2026: 97,
    grantQuota2025: 4200,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B006',
    titleRu: 'Подготовка учителей начальных классов',
    titleKk: 'Бастауыш сынып мұғалімдерін даярлау',
    titleEn: 'Primary School Teacher Training',
    subjectType: SubjectType.humanities,
    requiredSubjects: ['Всемирная история'],
    minScore2025: 90,
    predictedMin2026: 92,
    grantQuota2025: 5800,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B017',
    titleRu: 'Подготовка учителей истории',
    titleKk: 'Тарих мұғалімдерін даярлау',
    titleEn: 'History Teacher Training',
    subjectType: SubjectType.humanities,
    requiredSubjects: ['Всемирная история'],
    minScore2025: 88,
    predictedMin2026: 90,
    grantQuota2025: 2800,
    trend: CompetitionTrend.stable,
  ),

  // ═══════════════════════════════════════════
  //  ГУМАНИТАРИЙ: Человек. Общество. Право
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B042',
    titleRu: 'Юриспруденция',
    titleKk: 'Құқықтану',
    titleEn: 'Law',
    subjectType: SubjectType.humanities,
    requiredSubjects: ['Человек. Общество. Право'],
    minScore2025: 112,
    predictedMin2026: 114,
    grantQuota2025: 2800,
    trend: CompetitionTrend.rising,
  ),
  EntSpecialty(
    code: 'B041',
    titleRu: 'Международные отношения',
    titleKk: 'Халықаралық қатынастар',
    titleEn: 'International Relations',
    subjectType: SubjectType.humanities,
    requiredSubjects: ['Человек. Общество. Право'],
    minScore2025: 115,
    predictedMin2026: 117,
    grantQuota2025: 600,
    trend: CompetitionTrend.rising,
  ),
  EntSpecialty(
    code: 'B043',
    titleRu: 'Политология',
    titleKk: 'Саясаттану',
    titleEn: 'Political Science',
    subjectType: SubjectType.humanities,
    requiredSubjects: ['Человек. Общество. Право'],
    minScore2025: 100,
    predictedMin2026: 102,
    grantQuota2025: 500,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B044',
    titleRu: 'Экономика',
    titleKk: 'Экономика',
    titleEn: 'Economics',
    subjectType: SubjectType.humanities,
    requiredSubjects: ['Человек. Общество. Право'],
    minScore2025: 108,
    predictedMin2026: 110,
    grantQuota2025: 2100,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B045',
    titleRu: 'Менеджмент и управление',
    titleKk: 'Менеджмент және басқару',
    titleEn: 'Management',
    subjectType: SubjectType.humanities,
    requiredSubjects: ['Человек. Общество. Право'],
    minScore2025: 102,
    predictedMin2026: 104,
    grantQuota2025: 1800,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B046',
    titleRu: 'Финансы, банковское и страховое дело',
    titleKk: 'Қаржы, банк және сақтандыру ісі',
    titleEn: 'Finance, Banking and Insurance',
    subjectType: SubjectType.humanities,
    requiredSubjects: ['Человек. Общество. Право'],
    minScore2025: 105,
    predictedMin2026: 107,
    grantQuota2025: 1500,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B047',
    titleRu: 'Учёт и аудит',
    titleKk: 'Есеп және аудит',
    titleEn: 'Accounting and Audit',
    subjectType: SubjectType.humanities,
    requiredSubjects: ['Человек. Общество. Право'],
    minScore2025: 95,
    predictedMin2026: 97,
    grantQuota2025: 1200,
    trend: CompetitionTrend.falling,
  ),

  // ═══════════════════════════════════════════
  //  ГУМАНИТАРИЙ: Иностранный язык
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B036',
    titleRu: 'Переводческое дело',
    titleKk: 'Аударма ісі',
    titleEn: 'Translation Studies',
    subjectType: SubjectType.humanities,
    requiredSubjects: ['Иностранный язык'],
    minScore2025: 108,
    predictedMin2026: 110,
    grantQuota2025: 1000,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B018',
    titleRu: 'Подготовка учителей иностранного языка',
    titleKk: 'Шет тілі мұғалімдерін даярлау',
    titleEn: 'Foreign Language Teacher Training',
    subjectType: SubjectType.humanities,
    requiredSubjects: ['Иностранный язык'],
    minScore2025: 100,
    predictedMin2026: 102,
    grantQuota2025: 3500,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B037',
    titleRu: 'Филология (иностранная)',
    titleKk: 'Филология (шетелдік)',
    titleEn: 'Philology (Foreign)',
    subjectType: SubjectType.humanities,
    requiredSubjects: ['Иностранный язык'],
    minScore2025: 98,
    predictedMin2026: 100,
    grantQuota2025: 800,
    trend: CompetitionTrend.stable,
  ),

  // ═══════════════════════════════════════════
  //  ГУМАНИТАРИЙ: География
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B053',
    titleRu: 'Туризм',
    titleKk: 'Туризм',
    titleEn: 'Tourism',
    subjectType: SubjectType.humanities,
    requiredSubjects: ['География'],
    minScore2025: 82,
    predictedMin2026: 84,
    grantQuota2025: 1500,
    trend: CompetitionTrend.falling,
  ),
  EntSpecialty(
    code: 'B076',
    titleRu: 'Социальная работа',
    titleKk: 'Әлеуметтік жұмыс',
    titleEn: 'Social Work',
    subjectType: SubjectType.humanities,
    requiredSubjects: ['География'],
    minScore2025: 80,
    predictedMin2026: 82,
    grantQuota2025: 1800,
    trend: CompetitionTrend.stable,
  ),

  // ═══════════════════════════════════════════
  //  ГУМАНИТАРИЙ: Литература
  // ═══════════════════════════════════════════
  EntSpecialty(
    code: 'B035',
    titleRu: 'Журналистика и масс-медиа',
    titleKk: 'Журналистика және БАҚ',
    titleEn: 'Journalism and Mass Media',
    subjectType: SubjectType.humanities,
    requiredSubjects: ['Литература'],
    minScore2025: 95,
    predictedMin2026: 97,
    grantQuota2025: 1200,
    trend: CompetitionTrend.stable,
  ),
  EntSpecialty(
    code: 'B034',
    titleRu: 'Филология (казахская / русская)',
    titleKk: 'Филология (қазақ / орыс)',
    titleEn: 'Philology (Kazakh / Russian)',
    subjectType: SubjectType.humanities,
    requiredSubjects: ['Литература'],
    minScore2025: 88,
    predictedMin2026: 90,
    grantQuota2025: 2200,
    trend: CompetitionTrend.stable,
  ),
];

/// Получить специальности по направлению
List<EntSpecialty> getSpecialtiesByType(SubjectType type) {
  return entSpecialties2026
      .where((s) => s.subjectType == type)
      .toList();
}

/// Получить специальности, доступные по выбранному предмету
List<EntSpecialty> getSpecialtiesBySubject(String subject) {
  return entSpecialties2026
      .where((s) => s.requiredSubjects.contains(subject))
      .toList();
}

/// Получить специальности по направлению + предмету
List<EntSpecialty> getSpecialtiesByTypeAndSubject(
    SubjectType type, String subject) {
  return entSpecialties2026
      .where((s) =>
          s.subjectType == type && s.requiredSubjects.contains(subject))
      .toList();
}
