// 🔬 ДДО Климова — 20 пар вопросов
//
// Дифференциально-диагностический опросник (ДДО) Е.А. Климова.
// Типы профессий: Человек-Природа, Человек-Техника, Человек-Человек, 
// Человек-Знаковая система, Человек-Художественный образ.

class KlimovOption {
  final String text;
  final String type; // nature, tech, signs, art, human

  const KlimovOption({required this.text, required this.type});
}

class KlimovQuestion {
  final int id;
  final KlimovOption optionA;
  final KlimovOption optionB;

  const KlimovQuestion({
    required this.id,
    required this.optionA,
    required this.optionB,
  });
}

const List<KlimovQuestion> klimovQuestions = [
  KlimovQuestion(
    id: 1,
    optionA: KlimovOption(text: 'Ухаживать за животными', type: 'nature'),
    optionB: KlimovOption(text: 'Обслуживать машины, приборы (следить, регулировать)', type: 'tech'),
  ),
  KlimovQuestion(
    id: 2,
    optionA: KlimovOption(text: 'Помогать больным людям, лечить их', type: 'human'),
    optionB: KlimovOption(text: 'Составлять таблицы, схемы, программы вычислительных машин', type: 'signs'),
  ),
  KlimovQuestion(
    id: 3,
    optionA: KlimovOption(text: 'Следить за качеством книжных иллюстраций, плакатов, открыток, CD', type: 'art'),
    optionB: KlimovOption(text: 'Следить за состоянием, развитием растений', type: 'nature'),
  ),
  KlimovQuestion(
    id: 4,
    optionA: KlimovOption(text: 'Обрабатывать материалы (дерево, ткань, металл, пластмассу)', type: 'tech'),
    optionB: KlimovOption(text: 'Доводить товары до потребителя, рекламировать, продавать', type: 'human'),
  ),
  KlimovQuestion(
    id: 5,
    optionA: KlimovOption(text: 'Обсуждать научно-популярные книги, статьи', type: 'signs'),
    optionB: KlimovOption(text: 'Обсуждать художественные книги, пьесы, концерты', type: 'art'),
  ),
  KlimovQuestion(
    id: 6,
    optionA: KlimovOption(text: 'Выращивать молодняк (животных)', type: 'nature'),
    optionB: KlimovOption(text: 'Тренировать ровесников или младших в выполнении каких-либо действий', type: 'human'),
  ),
  KlimovQuestion(
    id: 7,
    optionA: KlimovOption(text: 'Копировать рисунки, изображения (или настраивать муз. инструменты)', type: 'art'),
    optionB: KlimovOption(text: 'Управлять легковым или грузовым автомобилем, трактором', type: 'tech'),
  ),
  KlimovQuestion(
    id: 8,
    optionA: KlimovOption(text: 'Сообщать, разъяснять людям нужные им сведения', type: 'human'),
    optionB: KlimovOption(text: 'Оформлять выставки, витрины или участвовать в подготовке пьес, концертов', type: 'art'),
  ),
  KlimovQuestion(
    id: 9,
    optionA: KlimovOption(text: 'Ремонтировать вещи, изделия, жилища', type: 'tech'),
    optionB: KlimovOption(text: 'Искать и исправлять ошибки в текстах, таблицах, рисунках', type: 'signs'),
  ),
  KlimovQuestion(
    id: 10,
    optionA: KlimovOption(text: 'Лечить животных', type: 'nature'),
    optionB: KlimovOption(text: 'Выполнять вычисления, расчёты', type: 'signs'),
  ),
  KlimovQuestion(
    id: 11,
    optionA: KlimovOption(text: 'Выводить новые сорта растений', type: 'nature'),
    optionB: KlimovOption(text: 'Конструировать, проектировать новые виды промышленных изделий', type: 'tech'),
  ),
  KlimovQuestion(
    id: 12,
    optionA: KlimovOption(text: 'Разбирать споры, ссоры между людьми, убеждать, объяснять', type: 'human'),
    optionB: KlimovOption(text: 'Разбираться в чертежах, схемах, таблицах (проверять, уточнять, приводить в порядок)', type: 'signs'),
  ),
  KlimovQuestion(
    id: 13,
    optionA: KlimovOption(text: 'Наблюдать, изучать работу кружков художественной самодеятельности', type: 'art'),
    optionB: KlimovOption(text: 'Наблюдать, изучать жизнь микробов', type: 'nature'),
  ),
  KlimovQuestion(
    id: 14,
    optionA: KlimovOption(text: 'Обслуживать, налаживать медицинские приборы, аппараты', type: 'tech'),
    optionB: KlimovOption(text: 'Оказывать людям медицинскую помощь при контузиях, ранениях', type: 'human'),
  ),
  KlimovQuestion(
    id: 15,
    optionA: KlimovOption(text: 'Составлять точные описания-отчеты о наблюдаемых явлениях', type: 'signs'),
    optionB: KlimovOption(text: 'Художественно описывать, изображать события', type: 'art'),
  ),
  KlimovQuestion(
    id: 16,
    optionA: KlimovOption(text: 'Делать лабораторные анализы в больнице', type: 'nature'),
    optionB: KlimovOption(text: 'Принимать, осматривать больных, беседовать с ними, назначать лечение', type: 'human'),
  ),
  KlimovQuestion(
    id: 17,
    optionA: KlimovOption(text: 'Красить или расписывать стены помещений, поверхность изделий', type: 'art'),
    optionB: KlimovOption(text: 'Осуществлять монтаж или сборку машин, приборов', type: 'tech'),
  ),
  KlimovQuestion(
    id: 18,
    optionA: KlimovOption(text: 'Организовывать культпоходы ровесников или младших в театры, музеи', type: 'human'),
    optionB: KlimovOption(text: 'Играть на сцене, принимать участие в концертах', type: 'art'),
  ),
  KlimovQuestion(
    id: 19,
    optionA: KlimovOption(text: 'Изготовлять по чертежам детали, изделия (строить здания)', type: 'tech'),
    optionB: KlimovOption(text: 'Заниматься черчением, копировать чертежи, карты', type: 'signs'),
  ),
  KlimovQuestion(
    id: 20,
    optionA: KlimovOption(text: 'Вести борьбу с болезнями растений, вредителями леса, сада', type: 'nature'),
    optionB: KlimovOption(text: 'Работать на клавишных машинах (компьютере)', type: 'signs'),
  ),
];

// Маппинг Климова на ГОП (Примеры, аналогично матрице Голланда)
const Map<String, List<String>> klimovGopGropus = {
  'nature': [
    ...['B050', 'B051', 'B052'], // Биология, экология
    ...['B068', 'B069', 'B070', 'B071', 'B072', 'B073', 'B074', 'B075', 'B076'], // Сельское и водное хозяйство, АПК
    ...['B084', 'B085', 'B086', 'B087', 'B088', 'B089'], // Ветеринария, Здравоохранение (мед)
    ...['B053', 'B054'], // География, физика (естественные науки)
  ],
  'tech': [
    ...['B057', 'B058', 'B059', 'B060', 'B061', 'B062', 'B063', 'B064', 'B065', 'B066', 'B067'], // Инженерия, строительство, транспорт, архитектура, авиация
    ...['B071', 'B072'], // Механизация, технологии
  ],
  'human': [
    ...['B001', 'B002', 'B003', 'B004', 'B005', 'B006', 'B007', 'B008', 'B009', 'B010', 'B011', 'B012', 'B013', 'B014', 'B015', 'B016', 'B017', 'B018', 'B019', 'B020'], // Педагогика
    ...['B030', 'B031', 'B032', 'B033', 'B034', 'B038'], // Психология, Менеджмент, HR, Право, Туризм
    ...['B084', 'B085', 'B086', 'B087', 'B088'], // Здравоохранение, Сестринское дело
    ...['B090', 'B091', 'B092', 'B093'], // Социология, соцработа
  ],
  'signs': [
    ...['B055', 'B056', 'B057'], // Математика, информатика, IT
    ...['B044', 'B045', 'B046', 'B047', 'B048'], // Финансы, учет, аудит, налоги
    ...['B160', 'B161'], // Статистика
    ...['B034', 'B035', 'B036', 'B037', 'B038'], // Право, Юриспруденция
    ...['B033'], // Журналистика (частично)
  ],
  'art': [
    ...['B021', 'B022', 'B023', 'B024', 'B025', 'B026', 'B027', 'B028', 'B029'], // Искусство, аудиовизуальные средства
    ...['B033'], // Журналистика, мода
    ...['B042'], // Дизайн
    ...['B043'], // Архитектура (творческая часть)
    ...['B015', 'B016'], // Подготовка учителей худ. труда
  ],
};

// Примеры профессий для типов Климова
const Map<String, List<String>> klimovProfessions = {
  'nature': [
    'Эколог', 'Биолог', 'Ветеринар', 'Агроном', 
    'Зоолог', 'Геолог', 'Кинолог', 'Лесник', 'Врач (некоторые специализации)'
  ],
  'tech': [
    'Инженер', 'Программист', 'Архитектор', 'Механик', 
    'Технолог', 'Строитель', 'Пилот', 'Робототехник', 'Слесарь'
  ],
  'human': [
    'Учитель/Преподаватель', 'Психолог', 'Врач', 'Менеджер', 
    'Юрист', 'Социальный работник', 'Турменеджер', 'Специалист по кадрам'
  ],
  'signs': [
    'Бухгалтер', 'Программист', 'Экономист', 'Переводчик', 
    'Аналитик', 'Редактор', 'Картограф', 'Статистик'
  ],
  'art': [
    'Дизайнер', 'Художник', 'Музыкант', 'Актер', 
    'Журналист', 'Писатель', 'Режиссер', 'Архитектор'
  ],
};
