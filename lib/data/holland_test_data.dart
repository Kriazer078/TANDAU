// 🧭 Тест Голланда (RIASEC) — 42 пары вопросов
//
// Научная база: John L. Holland, "Self-Directed Search" (SDS), 1959/1997
// Адаптация: стандартная русскоязычная версия
//
// Каждый вопрос — пара из двух вариантов деятельности.
// Для каждого варианта указан тип RIASEC (R, I, A, S, E, C).
// Пользователь выбирает один из двух вариантов.

/// Вариант ответа в паре вопросов
class HollandOption {
  final String text;
  final String type; // R, I, A, S, E, C

  const HollandOption({required this.text, required this.type});
}

/// Пара вопросов Голланда
class HollandQuestion {
  final int id;
  final HollandOption optionA;
  final HollandOption optionB;

  const HollandQuestion({
    required this.id,
    required this.optionA,
    required this.optionB,
  });
}

/// 42 пары вопросов (стандартная методика Голланда)
const List<HollandQuestion> hollandQuestions = [
  // 1-7: R vs I
  HollandQuestion(
    id: 1,
    optionA: HollandOption(text: 'Ремонтировать технику и механизмы', type: 'R'),
    optionB: HollandOption(text: 'Проводить научные эксперименты', type: 'I'),
  ),
  HollandQuestion(
    id: 2,
    optionA: HollandOption(text: 'Строить здания и сооружения', type: 'R'),
    optionB: HollandOption(text: 'Анализировать данные и статистику', type: 'I'),
  ),
  HollandQuestion(
    id: 3,
    optionA: HollandOption(text: 'Управлять станками и оборудованием', type: 'R'),
    optionB: HollandOption(text: 'Исследовать химические реакции', type: 'I'),
  ),
  HollandQuestion(
    id: 4,
    optionA: HollandOption(text: 'Работать с деревом или металлом', type: 'R'),
    optionB: HollandOption(text: 'Изучать законы природы', type: 'I'),
  ),
  HollandQuestion(
    id: 5,
    optionA: HollandOption(text: 'Выращивать растения, ухаживать за животными', type: 'R'),
    optionB: HollandOption(text: 'Решать математические задачи', type: 'I'),
  ),
  HollandQuestion(
    id: 6,
    optionA: HollandOption(text: 'Собирать и настраивать компьютеры', type: 'R'),
    optionB: HollandOption(text: 'Программировать и писать алгоритмы', type: 'I'),
  ),
  HollandQuestion(
    id: 7,
    optionA: HollandOption(text: 'Водить транспорт', type: 'R'),
    optionB: HollandOption(text: 'Проектировать системы навигации', type: 'I'),
  ),

  // 8-14: A vs S
  HollandQuestion(
    id: 8,
    optionA: HollandOption(text: 'Рисовать, фотографировать', type: 'A'),
    optionB: HollandOption(text: 'Помогать людям решать проблемы', type: 'S'),
  ),
  HollandQuestion(
    id: 9,
    optionA: HollandOption(text: 'Играть на музыкальных инструментах', type: 'A'),
    optionB: HollandOption(text: 'Обучать и воспитывать детей', type: 'S'),
  ),
  HollandQuestion(
    id: 10,
    optionA: HollandOption(text: 'Писать стихи, рассказы, сценарии', type: 'A'),
    optionB: HollandOption(text: 'Консультировать людей по личным вопросам', type: 'S'),
  ),
  HollandQuestion(
    id: 11,
    optionA: HollandOption(text: 'Создавать дизайн интерьера или одежды', type: 'A'),
    optionB: HollandOption(text: 'Работать в медицине, помогать больным', type: 'S'),
  ),
  HollandQuestion(
    id: 12,
    optionA: HollandOption(text: 'Снимать кино или видеоролики', type: 'A'),
    optionB: HollandOption(text: 'Организовывать мероприятия для людей', type: 'S'),
  ),
  HollandQuestion(
    id: 13,
    optionA: HollandOption(text: 'Заниматься актёрским мастерством', type: 'A'),
    optionB: HollandOption(text: 'Быть волонтёром, помогать нуждающимся', type: 'S'),
  ),
  HollandQuestion(
    id: 14,
    optionA: HollandOption(text: 'Придумывать рекламу и логотипы', type: 'A'),
    optionB: HollandOption(text: 'Работать с детьми или пожилыми', type: 'S'),
  ),

  // 15-21: E vs C
  HollandQuestion(
    id: 15,
    optionA: HollandOption(text: 'Руководить командой, принимать решения', type: 'E'),
    optionB: HollandOption(text: 'Вести финансовый учёт и отчёты', type: 'C'),
  ),
  HollandQuestion(
    id: 16,
    optionA: HollandOption(text: 'Открыть своё дело, стартап', type: 'E'),
    optionB: HollandOption(text: 'Работать с базами данных и таблицами', type: 'C'),
  ),
  HollandQuestion(
    id: 17,
    optionA: HollandOption(text: 'Вести переговоры и заключать сделки', type: 'E'),
    optionB: HollandOption(text: 'Проверять документы на соответствие', type: 'C'),
  ),
  HollandQuestion(
    id: 18,
    optionA: HollandOption(text: 'Продвигать товары и услуги', type: 'E'),
    optionB: HollandOption(text: 'Составлять графики и расписания', type: 'C'),
  ),
  HollandQuestion(
    id: 19,
    optionA: HollandOption(text: 'Выступать публично, делать презентации', type: 'E'),
    optionB: HollandOption(text: 'Работать с архивами и каталогами', type: 'C'),
  ),
  HollandQuestion(
    id: 20,
    optionA: HollandOption(text: 'Управлять проектами и людьми', type: 'E'),
    optionB: HollandOption(text: 'Проводить инвентаризацию и учёт', type: 'C'),
  ),
  HollandQuestion(
    id: 21,
    optionA: HollandOption(text: 'Организовывать бизнес-процессы', type: 'E'),
    optionB: HollandOption(text: 'Обрабатывать почту и корреспонденцию', type: 'C'),
  ),

  // 22-28: R vs A
  HollandQuestion(
    id: 22,
    optionA: HollandOption(text: 'Чинить электроприборы', type: 'R'),
    optionB: HollandOption(text: 'Рисовать портреты и пейзажи', type: 'A'),
  ),
  HollandQuestion(
    id: 23,
    optionA: HollandOption(text: 'Работать на ферме или в саду', type: 'R'),
    optionB: HollandOption(text: 'Играть в театре или кино', type: 'A'),
  ),
  HollandQuestion(
    id: 24,
    optionA: HollandOption(text: 'Строить мебель своими руками', type: 'R'),
    optionB: HollandOption(text: 'Сочинять музыку', type: 'A'),
  ),
  HollandQuestion(
    id: 25,
    optionA: HollandOption(text: 'Ремонтировать автомобили', type: 'R'),
    optionB: HollandOption(text: 'Оформлять витрины и выставки', type: 'A'),
  ),
  HollandQuestion(
    id: 26,
    optionA: HollandOption(text: 'Монтировать электропроводку', type: 'R'),
    optionB: HollandOption(text: 'Заниматься танцами', type: 'A'),
  ),
  HollandQuestion(
    id: 27,
    optionA: HollandOption(text: 'Готовить и работать на кухне', type: 'R'),
    optionB: HollandOption(text: 'Писать статьи и блоги', type: 'A'),
  ),
  HollandQuestion(
    id: 28,
    optionA: HollandOption(text: 'Тренировать спортсменов', type: 'R'),
    optionB: HollandOption(text: 'Фотографировать красивые места', type: 'A'),
  ),

  // 29-35: I vs E
  HollandQuestion(
    id: 29,
    optionA: HollandOption(text: 'Читать научные журналы и статьи', type: 'I'),
    optionB: HollandOption(text: 'Запустить рекламную кампанию', type: 'E'),
  ),
  HollandQuestion(
    id: 30,
    optionA: HollandOption(text: 'Исследовать космос или океан', type: 'I'),
    optionB: HollandOption(text: 'Создать и продвигать бренд', type: 'E'),
  ),
  HollandQuestion(
    id: 31,
    optionA: HollandOption(text: 'Работать в лаборатории', type: 'I'),
    optionB: HollandOption(text: 'Управлять финансами компании', type: 'E'),
  ),
  HollandQuestion(
    id: 32,
    optionA: HollandOption(text: 'Изучать иностранные языки', type: 'I'),
    optionB: HollandOption(text: 'Продавать товары и услуги', type: 'E'),
  ),
  HollandQuestion(
    id: 33,
    optionA: HollandOption(text: 'Разрабатывать теории и модели', type: 'I'),
    optionB: HollandOption(text: 'Открыть свой интернет-магазин', type: 'E'),
  ),
  HollandQuestion(
    id: 34,
    optionA: HollandOption(text: 'Писать программный код', type: 'I'),
    optionB: HollandOption(text: 'Руководить IT-компанией', type: 'E'),
  ),
  HollandQuestion(
    id: 35,
    optionA: HollandOption(text: 'Анализировать социальные процессы', type: 'I'),
    optionB: HollandOption(text: 'Организовать благотворительный фонд', type: 'E'),
  ),

  // 36-42: S vs C
  HollandQuestion(
    id: 36,
    optionA: HollandOption(text: 'Преподавать в школе или вузе', type: 'S'),
    optionB: HollandOption(text: 'Работать бухгалтером', type: 'C'),
  ),
  HollandQuestion(
    id: 37,
    optionA: HollandOption(text: 'Быть психологом или коучем', type: 'S'),
    optionB: HollandOption(text: 'Работать банковским операционистом', type: 'C'),
  ),
  HollandQuestion(
    id: 38,
    optionA: HollandOption(text: 'Ухаживать за больными в больнице', type: 'S'),
    optionB: HollandOption(text: 'Оформлять страховые полисы', type: 'C'),
  ),
  HollandQuestion(
    id: 39,
    optionA: HollandOption(text: 'Проводить тренинги и семинары', type: 'S'),
    optionB: HollandOption(text: 'Заполнять налоговые декларации', type: 'C'),
  ),
  HollandQuestion(
    id: 40,
    optionA: HollandOption(text: 'Работать социальным работником', type: 'S'),
    optionB: HollandOption(text: 'Систематизировать информацию', type: 'C'),
  ),
  HollandQuestion(
    id: 41,
    optionA: HollandOption(text: 'Помогать людям с ограниченными возможностями', type: 'S'),
    optionB: HollandOption(text: 'Проверять качество продукции', type: 'C'),
  ),
  HollandQuestion(
    id: 42,
    optionA: HollandOption(text: 'Проводить экскурсии для туристов', type: 'S'),
    optionB: HollandOption(text: 'Вести документооборот', type: 'C'),
  ),
];

/// 🔗 Маппинг RIASEC типов → коды ГОП (группы образовательных программ)
///
/// Этот маппинг расширяемый — можно добавлять новые ГОП
/// или уточнять существующие связи.
///
/// Основан на анализе содержимого ГОП из ent_specialties_2026.dart
/// и описании типов RIASEC.
const Map<String, List<String>> riasecToGopMapping = {
  // 🔧 R (Реалистичный) — работа с техникой, природой, инструментами
  'R': [
    'B063', // Электротехника и энергетика
    'B064', // Механика и металлообработка
    'B065', // Автотранспортные средства
    'B068', // Горное дело
    'B071', // Транспортная техника
    'B074', // Градостроительство, строительные работы
    'B069', // Нефтяная инженерия
    'B077', // Растениеводство
    'B079', // Ветеринария
    'B060', // Производство продуктов питания
    'B075', // Физическая культура и спорт
    'B010', // Подготовка учителей физики
  ],

  // 🔬 I (Исследовательский) — интеллектуальный анализ, наука
  'I': [
    'B057', // Информационные технологии
    'B058', // Информационная безопасность
    'B054', // Математика и статистика
    'B055', // Физика
    'B050', // Биологические науки
    'B051', // Химические науки
    'B052', // Науки о Земле
    'B061', // Химическая инженерия и процессы
    'B070', // Материаловедение
    'B001', // Медицина (общая)
    'B003', // Фармация
    'B014', // Подготовка учителей информатики
  ],

  // 🎨 A (Артистичный) — творчество, самовыражение
  'A': [
    'B031', // Дизайн
    'B029', // Музыкальное искусство
    'B030', // Изобразительное искусство
    'B073', // Архитектура
    'B035', // Журналистика и масс-медиа
    'B034', // Филология (казахская / русская)
    'B036', // Переводческое дело
    'B037', // Филология (иностранная)
    'B048', // Маркетинг и реклама
  ],

  // 🤝 S (Социальный) — работа с людьми, помощь
  'S': [
    'B005', // Педагогика и психология
    'B006', // Подготовка учителей начальных классов
    'B007', // Дефектология
    'B017', // Подготовка учителей истории
    'B018', // Подготовка учителей иностранного языка
    'B020', // Подготовка учителей казахского/русского языка
    'B011', // Подготовка учителей математики
    'B040', // Психология
    'B076', // Социальная работа
    'B001', // Медицина
    'B002', // Стоматология
    'B004', // Общественное здравоохранение
    'B078', // Сестринское дело
    'B012', // Подготовка учителей химии
    'B013', // Подготовка учителей биологии
    'B015', // Подготовка учителей географии
  ],

  // 📈 E (Предприимчивый) — лидерство, бизнес, управление
  'E': [
    'B044', // Экономика
    'B045', // Менеджмент и управление
    'B046', // Финансы, банковское и страховое дело
    'B042', // Юриспруденция
    'B041', // Международные отношения
    'B043', // Политология
    'B049', // Правоохранительная деятельность
    'B038', // Государственное и местное управление
    'B048', // Маркетинг и реклама
    'B053', // Туризм
  ],

  // 📊 C (Конвенциональный) — точность, порядок, данные
  'C': [
    'B047', // Учёт и аудит
    'B046', // Финансы, банковское и страховое дело
    'B044', // Экономика
    'B057', // Информационные технологии
    'B058', // Информационная безопасность
    'B059', // Коммуникации и коммуникационные технологии
    'B054', // Математика и статистика
    'B033', // Библиотечное дело
    'B080', // Экология
  ],
};

/// Профессии для каждого типа RIASEC (для UI)
const Map<String, List<String>> riasecProfessions = {
  'R': [
    'Инженер',
    'Механик',
    'Строитель',
    'Электрик',
    'Фермер',
    'Технолог',
  ],
  'I': [
    'Учёный',
    'Программист',
    'Врач',
    'Аналитик',
    'Фармацевт',
    'Биолог',
  ],
  'A': [
    'Дизайнер',
    'Архитектор',
    'Журналист',
    'Музыкант',
    'Художник',
    'Переводчик',
  ],
  'S': [
    'Учитель',
    'Психолог',
    'Врач',
    'Социальный работник',
    'Тренер',
    'Медсестра',
  ],
  'E': [
    'Менеджер',
    'Юрист',
    'Предприниматель',
    'Маркетолог',
    'Политик',
    'Дипломат',
  ],
  'C': [
    'Бухгалтер',
    'Экономист',
    'Аудитор',
    'Программист',
    'Библиотекарь',
    'Статистик',
  ],
};
