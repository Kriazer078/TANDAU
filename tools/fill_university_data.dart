// ignore_for_file: avoid_print
// ═══════════════════════════════════════════════════════════════
// 🔧 Автоматическое заполнение данных университетов
// ═══════════════════════════════════════════════════════════════
//
// Использование:
//   dart run tools/fill_university_data.dart
//
// Модифицирует tools/university_data.csv, заполняя пустые поля:
//   website, email, tuitionRange, description, hasDormitory
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

/// Данные собраны из открытых источников:
/// - Официальные сайты вузов
/// - data.egov.kz
/// - enic-kazakhstan.edu.kz
/// - Поисковые системы (верификация)
final Map<String, Map<String, dynamic>> universityData = {
  // ═══ НАЦИОНАЛЬНЫЕ УНИВЕРСИТЕТЫ ═══
  '1': {
    'website': 'https://enu.kz',
    'email': 'enu@enu.kz',
    'tuitionRange': '1 350 000 - 1 600 000 тг/год',
    'hasDormitory': true,
    'description': 'Один из ведущих национальных университетов Казахстана. Основан в 1996 году. Предлагает более 100 образовательных программ бакалавриата, магистратуры и докторантуры.',
  },
  '3': {
    'website': 'https://kaznu.kz',
    'email': 'info@kaznu.edu',
    'tuitionRange': '500 000 - 1 900 000 тг/год',
    'hasDormitory': true,
    'description': 'Старейший и крупнейший вуз Казахстана, основан в 1934 году. Входит в топ-200 QS World University Rankings. Более 150 специальностей.',
  },
  '5': {
    'website': 'https://satbayev.university',
    'email': 'info@satbayev.university',
    'tuitionRange': '800 000 - 1 800 000 тг/год',
    'hasDormitory': true,
    'description': 'Ведущий технический университет Казахстана, основан в 1934 году. Специализация: инженерия, IT, нефтегазовое дело, горное дело, архитектура.',
  },
  '4': {
    'website': 'https://kaznaru.edu.kz',
    'email': 'info@kaznaru.edu.kz',
    'tuitionRange': '500 000 - 1 200 000 тг/год',
    'hasDormitory': true,
    'description': 'Крупнейший аграрный вуз Центральной Азии. Специальности: сельское хозяйство, ветеринария, пищевая промышленность, экология, лесное хозяйство.',
  },
  '7': {
    'website': 'https://conservatoire.edu.kz',
    'email': 'info@conservatoire.edu.kz',
    'tuitionRange': '500 000 - 1 000 000 тг/год',
    'hasDormitory': true,
    'description': 'Ведущее музыкальное высшее учебное заведение Казахстана, основано в 1944 году. Подготовка профессиональных музыкантов и композиторов.',
  },
  '6': {
    'website': 'https://kaznai.kz',
    'email': 'info@kaznai.kz',
    'tuitionRange': '500 000 - 1 100 000 тг/год',
    'hasDormitory': true,
    'description': 'Ведущий вуз в сфере искусств. Факультеты: театральное, хореографическое, изобразительное искусство, кино и ТВ.',
  },
  '2': {
    'website': 'https://kaznui.kz',
    'email': 'info@kaznui.kz',
    'tuitionRange': '600 000 - 1 200 000 тг/год',
    'hasDormitory': true,
    'description': 'Национальный университет искусств, расположен в Астане. Подготовка кадров в области музыки, хореографии, театра, кино и изобразительного искусства.',
  },

  // ═══ РЕГИОНАЛЬНЫЕ УНИВЕРСИТЕТЫ ═══
  '10': {
    'website': 'https://qyzpu.edu.kz',
    'email': 'info@qyzpu.edu.kz',
    'tuitionRange': '500 000 - 1 000 000 тг/год',
    'hasDormitory': true,
    'description': 'Единственный женский педагогический университет в Центральной Азии. Специализация: педагогика, психология, филология, естественные науки.',
  },
  '11': {
    'website': 'https://zhetysu.edu.kz',
    'email': 'info@zhetysu.edu.kz',
    'tuitionRange': '450 000 - 900 000 тг/год',
    'hasDormitory': true,
    'description': 'Региональный университет в Талдыкоргане. Специальности: педагогика, гуманитарные и естественные науки, экономика, право, инженерия.',
  },
  '12': {
    'website': 'https://arsu.edu.kz',
    'email': 'info@arsu.edu.kz',
    'tuitionRange': '450 000 - 1 000 000 тг/год',
    'hasDormitory': true,
    'description': 'Крупнейший университет Актюбинской области. Более 70 образовательных программ: педагогика, медицина, инженерия, IT, экономика.',
  },
  '13': {
    'website': 'https://shokan.edu.kz',
    'email': 'info@shokan.edu.kz',
    'tuitionRange': '400 000 - 800 000 тг/год',
    'hasDormitory': true,
    'description': 'Региональный университет в Кокшетау. Специальности: педагогика, аграрные науки, инженерия, гуманитарные науки, экономика.',
  },
  '14': {
    'website': 'https://asu.edu.kz',
    'email': 'kense@asu.edu.kz',
    'tuitionRange': '450 000 - 900 000 тг/год',
    'hasDormitory': true,
    'description': 'Ведущий вуз Атырауской области. Направления: нефтегазовое дело, педагогика, гуманитарные науки, экономика, естественные науки.',
  },
  '15': {
    'website': 'https://aogu.edu.kz',
    'email': 'info@aogu.edu.kz',
    'tuitionRange': '500 000 - 1 200 000 тг/год',
    'hasDormitory': true,
    'description': 'Университет нефти и газа в Атырау. Специализация: нефтегазовая инженерия, химическая технология, экология, IT.',
  },
  '16': {
    'website': 'https://vku.edu.kz',
    'email': 'info@vku.edu.kz',
    'tuitionRange': '450 000 - 900 000 тг/год',
    'hasDormitory': true,
    'description': 'Университет в Усть-Каменогорске. Педагогика, филология, история, естественные науки, искусство, экономика.',
  },
  '17': {
    'website': 'https://ektu.kz',
    'email': 'info@ektu.kz',
    'tuitionRange': '500 000 - 1 100 000 тг/год',
    'hasDormitory': true,
    'description': 'Технический вуз ВКО. Специализация: горное дело, металлургия, машиностроение, IT, строительство, энергетика.',
  },
  '18': {
    'website': 'https://shakarim.edu.kz',
    'email': 'info@shakarim.edu.kz',
    'tuitionRange': '450 000 - 900 000 тг/год',
    'hasDormitory': true,
    'description': 'Университет в Семее. Направления: ветеринария, пищевая промышленность, педагогика, инженерия, IT, экономика.',
  },
  '19': {
    'website': 'https://dulaty.edu.kz',
    'email': 'talapker@dulaty.kz',
    'tuitionRange': '450 000 - 1 000 000 тг/год',
    'hasDormitory': true,
    'description': 'Крупнейший вуз Жамбылской области. Инженерия, IT, педагогика, сельское хозяйство, экономика. Более 80 специальностей.',
  },
  '20': {
    'website': 'https://wkmu.edu.kz',
    'email': 'info@wkmu.edu.kz',
    'tuitionRange': '450 000 - 1 000 000 тг/год',
    'hasDormitory': true,
    'description': 'Университет в Уральске. Педагогика, филология, история, право, экономика, естественные науки, инженерия.',
  },
  '21': {
    'website': 'https://wkau.edu.kz',
    'email': 'info@wkau.edu.kz',
    'tuitionRange': '450 000 - 900 000 тг/год',
    'hasDormitory': true,
    'description': 'Аграрно-технический университет в ЗКО. Сельское хозяйство, ветеринария, пищевые технологии, инженерия, экономика.',
  },
  '22': {
    'website': 'https://buketov.edu.kz',
    'email': 'info@buketov.edu.kz',
    'tuitionRange': '500 000 - 1 100 000 тг/год',
    'hasDormitory': true,
    'description': 'Крупнейший классический университет Центрального Казахстана. Более 100 специальностей. Исследовательский университет.',
  },
  '23': {
    'website': 'https://kstu.kz',
    'email': 'info@kstu.kz',
    'tuitionRange': '500 000 - 1 100 000 тг/год',
    'hasDormitory': true,
    'description': 'Технический университет в Караганде. Горное дело, металлургия, машиностроение, IT, строительство, транспорт.',
  },
  '24': {
    'website': 'https://kiu.edu.kz',
    'email': 'info@kiu.edu.kz',
    'tuitionRange': '450 000 - 900 000 тг/год',
    'hasDormitory': true,
    'description': 'Индустриальный университет в Темиртау. Металлургия, горное дело, энергетика, машиностроение, IT.',
  },
  '25': {
    'website': 'https://ksu.edu.kz',
    'email': 'info@ksu.edu.kz',
    'tuitionRange': '450 000 - 900 000 тг/год',
    'hasDormitory': true,
    'description': 'Крупнейший университет Костанайской области. Педагогика, аграрные науки, инженерия, экономика, право, IT.',
  },
  '26': {
    'website': 'https://rii.edu.kz',
    'email': 'info@rii.edu.kz',
    'tuitionRange': '450 000 - 900 000 тг/год',
    'hasDormitory': true,
    'description': 'Индустриальный университет в Рудном. Горное дело, металлургия, строительство, энергетика, IT, экономика.',
  },
  '27': {
    'website': 'https://arkapu.edu.kz',
    'email': 'info@arkapu.edu.kz',
    'tuitionRange': '400 000 - 700 000 тг/год',
    'hasDormitory': true,
    'description': 'Педагогический университет в Аркалыке. Подготовка учителей по широкому спектру предметов.',
  },
  '28': {
    'website': 'https://korkyt.edu.kz',
    'email': 'info@korkyt.edu.kz',
    'tuitionRange': '450 000 - 900 000 тг/год',
    'hasDormitory': true,
    'description': 'Университет в Кызылорде. Инженерия, педагогика, сельское хозяйство, экономика, право, гуманитарные науки.',
  },
  '29': {
    'website': 'https://yu.edu.kz',
    'email': 'info@yu.edu.kz',
    'tuitionRange': '500 000 - 1 200 000 тг/год',
    'hasDormitory': true,
    'description': 'Ведущий вуз Мангистауской области. Нефтегазовая инженерия, IT, педагогика, экономика, морское дело.',
  },
  '30': {
    'website': 'https://tou.edu.kz',
    'email': 'info@tou.edu.kz',
    'tuitionRange': '450 000 - 1 000 000 тг/год',
    'hasDormitory': true,
    'description': 'Университет в Павлодаре. Инженерия, IT, педагогика, экономика, гуманитарные науки. Более 70 специальностей.',
  },
  '31': {
    'website': 'https://pspu.edu.kz',
    'email': 'info@pspu.edu.kz',
    'tuitionRange': '400 000 - 800 000 тг/год',
    'hasDormitory': true,
    'description': 'Педагогический университет в Павлодаре. Подготовка учителей: математика, физика, химия, биология, языки, история.',
  },
  '32': {
    'website': 'https://ku.edu.kz',
    'email': 'info@ku.edu.kz',
    'tuitionRange': '450 000 - 900 000 тг/год',
    'hasDormitory': true,
    'description': 'Университет в Петропавловске. Педагогика, инженерия, IT, экономика, аграрные науки, медицина.',
  },
  '33': {
    'website': 'https://auezov.edu.kz',
    'email': 'info@auezov.edu.kz',
    'tuitionRange': '450 000 - 1 000 000 тг/год',
    'hasDormitory': true,
    'description': 'Крупнейший университет юга Казахстана. Инженерия, IT, педагогика, экономика, химическая технология. Более 100 специальностей.',
  },
  '34': {
    'website': 'https://okmpu.edu.kz',
    'email': 'info@okmpu.edu.kz',
    'tuitionRange': '400 000 - 800 000 тг/год',
    'hasDormitory': true,
    'description': 'Педагогический университет в Шымкенте. Подготовка учителей для южного региона Казахстана.',
  },

  // ═══ IT И ЧАСТНЫЕ УНИВЕРСИТЕТЫ ═══
  '103': {
    'website': 'https://astanait.edu.kz',
    'email': 'info@astanait.edu.kz',
    'tuitionRange': '2 500 000 тг/год',
    'hasDormitory': true,
    'description': 'Ведущий IT-университет Казахстана. Специальности: Computer Science, Software Engineering, Data Science, Cybersecurity, IT Management.',
  },
  '59': {
    'website': 'https://kimep.kz',
    'email': 'uao@kimep.kz',
    'tuitionRange': '2 800 000 - 4 200 000 тг/год',
    'hasDormitory': true,
    'description': 'Ведущий бизнес-университет Казахстана. Программы на английском языке: бизнес, право, международные отношения, журналистика.',
  },
  '60': {
    'website': 'https://kbtu.edu.kz',
    'email': 'info@kbtu.edu.kz',
    'tuitionRange': '2 200 000 - 3 500 000 тг/год',
    'hasDormitory': true,
    'description': 'Казахстанско-Британский технический университет. IT, нефтегазовое дело, бизнес, инженерия. Международные программы.',
  },
  '58': {
    'website': 'https://iitu.edu.kz',
    'email': 'info@iitu.edu.kz',
    'tuitionRange': '1 800 000 - 2 500 000 тг/год',
    'hasDormitory': false,
    'description': 'Международный университет информационных технологий. Computer Science, кибербезопасность, медиа-технологии, Big Data.',
  },
  '51': {
    'website': 'https://mnu.kz',
    'email': 'info@mnu.kz',
    'tuitionRange': '2 000 000 - 3 500 000 тг/год',
    'hasDormitory': true,
    'description': 'Университет КАЗГЮУ — ведущая юридическая школа Казахстана. Право, бизнес, госуправление, международные отношения.',
  },
  '61': {
    'website': 'https://narxoz.kz',
    'email': 'admission@narxoz.kz',
    'tuitionRange': '1 500 000 - 2 500 000 тг/год',
    'hasDormitory': true,
    'description': 'Университет Нархоз — ведущая бизнес-школа. Экономика, финансы, маркетинг, IT, право, госуправление.',
  },
  '68': {
    'website': 'https://turan.edu.kz',
    'email': 'info@turan-edu.kz',
    'tuitionRange': '1 000 000 - 2 000 000 тг/год',
    'hasDormitory': false,
    'description': 'Университет «Туран» — многопрофильный частный вуз в Алматы. Экономика, IT, юриспруденция, туризм, дизайн.',
  },
  '66': {
    'website': 'https://turan-astana.kz',
    'email': 'info@turan-astana.kz',
    'tuitionRange': '900 000 - 1 800 000 тг/год',
    'hasDormitory': false,
    'description': 'Филиал университета «Туран» в Астане. Экономика, IT, юриспруденция, педагогика.',
  },
  '65': {
    'website': 'https://esil.edu.kz',
    'email': 'info@esil.edu.kz',
    'tuitionRange': '900 000 - 1 500 000 тг/год',
    'hasDormitory': true,
    'description': 'Esil University в Астане. Многопрофильный вуз: IT, экономика, педагогика, юриспруденция, инженерия.',
  },
  '63': {
    'website': 'https://atu.edu.kz',
    'email': 'info@atu.edu.kz',
    'tuitionRange': '600 000 - 1 200 000 тг/год',
    'hasDormitory': true,
    'description': 'Алматинский технологический университет. Пищевая промышленность, легкая промышленность, IT, биотехнология, дизайн.',
  },
  '64': {
    'website': 'https://kaztbu.kz',
    'email': 'info@kaztbu.kz',
    'tuitionRange': '700 000 - 1 300 000 тг/год',
    'hasDormitory': true,
    'description': 'Казахский университет технологии и бизнеса в Астане. Пищевые технологии, IT, экономика, туризм, дизайн.',
  },
  '52': {
    'website': 'https://aues.edu.kz',
    'email': 'info@aues.edu.kz',
    'tuitionRange': '600 000 - 1 200 000 тг/год',
    'hasDormitory': true,
    'description': 'Алматинский университет энергетики и связи. Энергетика, телекоммуникации, IT, автоматизация, радиотехника.',
  },
  '53': {
    'website': 'https://kazast.edu.kz',
    'email': 'info@kazast.edu.kz',
    'tuitionRange': '500 000 - 1 000 000 тг/год',
    'hasDormitory': true,
    'description': 'Казахская академия спорта и туризма. Физкультура, спорт, туризм, рекреация, спортивная медицина.',
  },
  '54': {
    'website': 'https://ablaikhan.kz',
    'email': 'info@ablaikhan.kz',
    'tuitionRange': '600 000 - 1 300 000 тг/год',
    'hasDormitory': true,
    'description': 'Университет международных отношений и мировых языков. Лингвистика, перевод, международные отношения, журналистика, педагогика.',
  },
  '62': {
    'website': 'https://kazatu.edu.kz',
    'email': 'info@kazatu.edu.kz',
    'tuitionRange': '500 000 - 1 200 000 тг/год',
    'hasDormitory': true,
    'description': 'Казахский агротехнический университет в Астане. Сельское хозяйство, ветеринария, IT, инженерия, экология, экономика.',
  },

  // ═══ МЕЖДУНАРОДНЫЕ И СПЕЦИАЛИЗИРОВАННЫЕ ═══
  '49': {
    'website': 'https://ayu.edu.kz',
    'email': 'info@ayu.edu.kz',
    'tuitionRange': '400 000 - 900 000 тг/год',
    'hasDormitory': true,
    'description': 'Международный казахско-турецкий университет в Туркестане. Педагогика, инженерия, гуманитарные науки, теология.',
  },
  '50': {
    'website': 'https://dmu.edu.kz',
    'email': 'info@dmu.edu.kz',
    'tuitionRange': '2 000 000 - 3 000 000 тг/год',
    'hasDormitory': false,
    'description': 'De Montfort University Kazakhstan — филиал британского университета. Бизнес, IT, медиа. Обучение на английском языке.',
  },
  '57': {
    'website': 'https://mok.edu.kz',
    'email': 'info@mok.edu.kz',
    'tuitionRange': '800 000 - 1 500 000 тг/год',
    'hasDormitory': true,
    'description': 'Международная образовательная корпорация. Строительство, архитектура, дизайн, IT, экономика.',
  },
  '55': {
    'website': 'https://zhgu.edu.kz',
    'email': 'info@zhgu.edu.kz',
    'tuitionRange': '450 000 - 900 000 тг/год',
    'hasDormitory': true,
    'description': 'Жезказганский университет. Горное дело, металлургия, IT, педагогика, экономика. Специализация на горнодобывающей промышленности.',
  },
  '56': {
    'website': 'https://agakaz.kz',
    'email': 'info@agakaz.kz',
    'tuitionRange': '800 000 - 2 000 000 тг/год',
    'hasDormitory': true,
    'description': 'Академия гражданской авиации. Подготовка специалистов для авиационной отрасли: пилоты, авиадиспетчеры, инженеры.',
  },
  '69': {
    'website': 'https://kunaev.university',
    'email': 'info@kunaev.university',
    'tuitionRange': '800 000 - 1 500 000 тг/год',
    'hasDormitory': false,
    'description': 'Университет Кунаева в Алматы. Юриспруденция, экономика, IT, лингвистика.',
  },
  '67': {
    'website': 'https://eagi.edu.kz',
    'email': 'info@eagi.edu.kz',
    'tuitionRange': '700 000 - 1 200 000 тг/год',
    'hasDormitory': false,
    'description': 'Евразийский гуманитарный институт в Астане. Педагогика, филология, психология, IT, экономика.',
  },
  '74': {
    'website': 'https://sdu.edu.kz',
    'email': 'info@sdu.edu.kz',
    'tuitionRange': '1 800 000 - 3 200 000 тг/год',
    'hasDormitory': true,
    'description': 'SDU University — один из ведущих частных вузов. IT, инженерия, бизнес, право, гуманитарные науки. Обучение на английском.',
  },
  '73': {
    'website': 'https://uib.kz',
    'email': 'info@uib.kz',
    'tuitionRange': '1 500 000 - 2 500 000 тг/год',
    'hasDormitory': false,
    'description': 'Университет Международного Бизнеса (UIB). Бизнес, экономика, финансы, маркетинг, IT, право.',
  },
  '71': {
    'website': 'https://almau.edu.kz',
    'email': 'info@almau.edu.kz',
    'tuitionRange': '1 800 000 - 3 000 000 тг/год',
    'hasDormitory': false,
    'description': 'Алматы Менеджмент Университет (AlmaU). Бизнес, менеджмент, IT, право. AACSB аккредитация.',
  },
  '70': {
    'website': 'https://meta.university',
    'email': 'info@meta.university',
    'tuitionRange': '1 500 000 - 2 000 000 тг/год',
    'hasDormitory': false,
    'description': 'META University — новый IT-ориентированный университет в Алматы. Программирование, Data Science, Digital Marketing.',
  },

  // ═══ МЕДИЦИНСКИЕ УНИВЕРСИТЕТЫ ═══
  '110': {
    'website': 'https://kaznmu.kz',
    'email': 'info@kaznmu.kz',
    'tuitionRange': '1 500 000 - 3 000 000 тг/год',
    'hasDormitory': true,
    'description': 'Крупнейший медицинский вуз Казахстана. Общая медицина, стоматология, фармация, общественное здравоохранение.',
  },
  '115': {
    'website': 'https://amu.edu.kz',
    'email': 'info@amu.edu.kz',
    'tuitionRange': '1 500 000 - 2 800 000 тг/год',
    'hasDormitory': true,
    'description': 'Медицинский университет Астана. Общая медицина, стоматология, фармация, сестринское дело.',
  },
  '111': {
    'website': 'https://zkmu.edu.kz',
    'email': 'info@zkmu.edu.kz',
    'tuitionRange': '1 200 000 - 2 000 000 тг/год',
    'hasDormitory': true,
    'description': 'Западно-Казахстанский медицинский университет в Актобе. Общая медицина, стоматология, педиатрия.',
  },
  '112': {
    'website': 'https://semeymeduniversity.kz',
    'email': 'info@semeymeduniversity.kz',
    'tuitionRange': '1 000 000 - 1 800 000 тг/год',
    'hasDormitory': true,
    'description': 'Медицинский университет Семей. Общая медицина, стоматология, общественное здравоохранение.',
  },
  '113': {
    'website': 'https://qmu.edu.kz',
    'email': 'info@qmu.edu.kz',
    'tuitionRange': '1 200 000 - 2 200 000 тг/год',
    'hasDormitory': true,
    'description': 'Карагандинский медицинский университет. Общая медицина, стоматология, фармация, общественное здравоохранение.',
  },
  '114': {
    'website': 'https://skma.edu.kz',
    'email': 'info@skma.edu.kz',
    'tuitionRange': '1 000 000 - 1 800 000 тг/год',
    'hasDormitory': true,
    'description': 'Южно-Казахстанская медицинская академия в Шымкенте. Общая медицина, стоматология, фармация.',
  },
  '116': {
    'website': 'https://krmu.edu.kz',
    'email': 'info@krmu.edu.kz',
    'tuitionRange': '1 500 000 - 2 500 000 тг/год',
    'hasDormitory': false,
    'description': 'Казахстанско-Российский медицинский университет в Алматы. Совместные программы с российскими вузами.',
  },
  '117': {
    'website': 'https://vshoz.edu.kz',
    'email': 'info@vshoz.edu.kz',
    'tuitionRange': '1 800 000 - 2 500 000 тг/год',
    'hasDormitory': false,
    'description': 'Казахстанский медицинский университет «ВШОЗ». Общественное здравоохранение, медицина, менеджмент здравоохранения.',
  },

  // ═══ ВОЕННЫЕ И ГОСУДАРСТВЕННЫЕ СПЕЦИАЛЬНЫЕ ═══
  '37': {
    'website': 'https://ndu.mod.gov.kz',
    'email': '',
    'tuitionRange': 'Бюджет (бесплатно)',
    'hasDormitory': true,
    'description': 'Национальный университет обороны. Подготовка офицерских кадров для Вооруженных сил РК.',
  },
  '38': {
    'website': 'https://knb.gov.kz',
    'email': '',
    'tuitionRange': 'Бюджет (бесплатно)',
    'hasDormitory': true,
    'description': 'Академия КНБ. Подготовка кадров для органов национальной безопасности Казахстана.',
  },
  '118': {
    'website': 'https://apa.kz',
    'email': 'info@apa.kz',
    'tuitionRange': 'Бюджет / 1 500 000 - 2 500 000 тг/год',
    'hasDormitory': true,
    'description': 'Академия государственного управления при Президенте РК. Госуправление, право, экономика, дипломатия.',
  },
  '35': {
    'website': 'https://agzrk.kz',
    'email': 'info@agzrk.kz',
    'tuitionRange': 'Бюджет (бесплатно)',
    'hasDormitory': true,
    'description': 'Академия гражданской защиты в Кокшетау. Пожарная безопасность, гражданская защита, спасательное дело.',
  },
  '36': {
    'website': 'https://kostacademy.kz',
    'email': 'info@kostacademy.kz',
    'tuitionRange': 'Бюджет (бесплатно)',
    'hasDormitory': true,
    'description': 'Костанайская академия МВД. Подготовка офицеров полиции и специалистов правоохранительных органов.',
  },
  '40': {
    'website': 'https://aui.edu.kz',
    'email': '',
    'tuitionRange': 'Бюджет (бесплатно)',
    'hasDormitory': true,
    'description': 'Актюбинский юридический институт МВД. Подготовка юристов для правоохранительных органов.',
  },
  '41': {
    'website': 'https://krgacademy.kz',
    'email': '',
    'tuitionRange': 'Бюджет (бесплатно)',
    'hasDormitory': true,
    'description': 'Карагандинская академия МВД. Подготовка следователей, криминалистов и оперативных работников.',
  },
  '42': {
    'website': 'https://vis.mod.gov.kz',
    'email': '',
    'tuitionRange': 'Бюджет (бесплатно)',
    'hasDormitory': true,
    'description': 'Военный институт Сухопутных войск в Алматы. Подготовка командных и инженерных кадров для сухопутных войск.',
  },
  '43': {
    'website': 'https://visvo.mod.gov.kz',
    'email': '',
    'tuitionRange': 'Бюджет (бесплатно)',
    'hasDormitory': true,
    'description': 'Военный институт Сил воздушной обороны в Актобе. Подготовка летных и инженерных кадров для ВВС.',
  },
  '44': {
    'website': 'https://aamvd.edu.kz',
    'email': '',
    'tuitionRange': 'Бюджет (бесплатно)',
    'hasDormitory': true,
    'description': 'Алматинская академия МВД. Подготовка кадров для правоохранительных органов юга Казахстана.',
  },
  '45': {
    'website': 'https://paknb.kz',
    'email': '',
    'tuitionRange': 'Бюджет (бесплатно)',
    'hasDormitory': true,
    'description': 'Пограничная академия КНБ в Алматы. Подготовка специалистов по охране государственной границы.',
  },
  '46': {
    'website': 'https://apo.gov.kz',
    'email': 'info@apo.gov.kz',
    'tuitionRange': 'Бюджет (бесплатно)',
    'hasDormitory': true,
    'description': 'Академия правоохранительных органов при Генеральной прокуратуре. Правоохранительное дело, криминалистика.',
  },
  '47': {
    'website': 'https://ang.edu.kz',
    'email': '',
    'tuitionRange': 'Бюджет (бесплатно)',
    'hasDormitory': true,
    'description': 'Академия Национальной гвардии в Петропавловске. Подготовка кадров для Национальной гвардии.',
  },
  '48': {
    'website': 'https://ajvs.kz',
    'email': 'info@ajvs.kz',
    'tuitionRange': 'Бюджет (бесплатно)',
    'hasDormitory': true,
    'description': 'Академия правосудия при Высшем Судебном Совете. Подготовка судей и судебных работников.',
  },
  '39': {
    'website': 'https://viiris.mod.gov.kz',
    'email': '',
    'tuitionRange': 'Бюджет (бесплатно)',
    'hasDormitory': true,
    'description': 'Военно-инженерный институт радиоэлектроники и связи в Алматы. IT, радиоэлектроника, связь для вооруженных сил.',
  },
  '124': {
    'website': 'https://amvd.edu.kz',
    'email': '',
    'tuitionRange': 'Бюджет (бесплатно)',
    'hasDormitory': true,
    'description': 'Академия управления МВД в Астане. Подготовка руководящих кадров для органов внутренних дел.',
  },

  // ═══ ОСТАЛЬНЫЕ ЧАСТНЫЕ ВУЗЫ ═══
  '100': {
    'website': 'https://tiiu.edu.kz',
    'email': 'info@tiiu.edu.kz',
    'tuitionRange': '500 000 - 1 000 000 тг/год',
    'hasDormitory': true,
    'description': 'Международный Таразский инновационный университет. IT, инженерия, экономика, педагогика.',
  },
  '101': {
    'website': 'https://wkitu.edu.kz',
    'email': 'info@wkitu.edu.kz',
    'tuitionRange': '500 000 - 900 000 тг/год',
    'hasDormitory': false,
    'description': 'Западно-Казахстанский инновационно-технологический университет в Уральске. IT, инженерия, экономика.',
  },
  '102': {
    'website': 'https://kuits.edu.kz',
    'email': 'info@kuits.edu.kz',
    'tuitionRange': '400 000 - 800 000 тг/год',
    'hasDormitory': false,
    'description': 'Казахстанский университет инновационных и телекоммуникационных систем в Уральске.',
  },
  '104': {
    'website': 'https://aiu.edu.kz',
    'email': 'info@aiu.edu.kz',
    'tuitionRange': '1 500 000 - 2 500 000 тг/год',
    'hasDormitory': true,
    'description': 'Международный университет «Астана». Бизнес, IT, право, международные отношения. Программы на английском.',
  },
  '105': {
    'website': 'https://iuth.edu.kz',
    'email': 'info@iuth.edu.kz',
    'tuitionRange': '500 000 - 1 000 000 тг/год',
    'hasDormitory': true,
    'description': 'Международный университет туризма и гостеприимства в Туркестане. Туризм, гостиничный бизнес, сервис.',
  },
  '106': {
    'website': 'https://alt.edu.kz',
    'email': 'info@alt.edu.kz',
    'tuitionRange': '600 000 - 1 200 000 тг/год',
    'hasDormitory': false,
    'description': 'ALT университет в Алматы. Транспорт, логистика, строительство, IT, экономика.',
  },
  '107': {
    'website': 'https://kaznus.edu.kz',
    'email': 'info@kaznus.edu.kz',
    'tuitionRange': '800 000 - 1 500 000 тг/год',
    'hasDormitory': true,
    'description': 'Казахский национальный университет спорта в Астане. Физкультура, спорт, спортивный менеджмент.',
  },
  '108': {
    'website': 'https://kstu-kostanay.edu.kz',
    'email': 'info@kstu-kostanay.edu.kz',
    'tuitionRange': '400 000 - 700 000 тг/год',
    'hasDormitory': false,
    'description': 'Костанайский социально-технический университет. IT, экономика, юриспруденция, педагогика.',
  },
  '109': {
    'website': 'https://bolashaq-kz.edu.kz',
    'email': 'info@bolashaq-kz.edu.kz',
    'tuitionRange': '400 000 - 700 000 тг/год',
    'hasDormitory': false,
    'description': 'Кызылординский университет «Болашак». Экономика, юриспруденция, педагогика, IT.',
  },
  '119': {
    'website': 'https://coventry.kz',
    'email': 'info@coventry.kz',
    'tuitionRange': '3 000 000 - 5 000 000 тг/год',
    'hasDormitory': false,
    'description': 'Coventry Kazakhstan — филиал британского Coventry University в Астане. Бизнес, IT. Обучение на английском.',
  },
  '72': {
    'website': 'https://itgu.edu.kz',
    'email': 'info@itgu.edu.kz',
    'tuitionRange': '600 000 - 1 000 000 тг/год',
    'hasDormitory': false,
    'description': 'Международный транспортно-гуманитарный университет в Алматы. Транспорт, логистика, IT, экономика.',
  },

  // ═══ ФИЛИАЛЫ РОССИЙСКИХ ВУЗОВ ═══
  '120': {
    'website': 'https://gubkin.kz',
    'email': 'info@gubkin.kz',
    'tuitionRange': '1 000 000 - 1 500 000 тг/год',
    'hasDormitory': true,
    'description': 'Филиал РГУ нефти и газа им. Губкина в Атырау. Нефтегазовое дело, геология, экология.',
  },
  '122': {
    'website': 'https://rctu.kz',
    'email': 'info@rctu.kz',
    'tuitionRange': '800 000 - 1 200 000 тг/год',
    'hasDormitory': false,
    'description': 'Филиал РХТУ им. Менделеева в Таразе. Химическая технология, фармация, биотехнология.',
  },
  '123': {
    'website': 'https://mephi.kz',
    'email': 'info@mephi.kz',
    'tuitionRange': '1 000 000 - 1 500 000 тг/год',
    'hasDormitory': false,
    'description': 'Филиал МИФИ в Алматы. Ядерная физика, IT, математика, инженерия.',
  },
  '125': {
    'website': 'https://mgimo.kz',
    'email': 'info@mgimo.kz',
    'tuitionRange': '2 500 000 - 4 000 000 тг/год',
    'hasDormitory': false,
    'description': 'Филиал МГИМО в Астане. Международные отношения, дипломатия, мировая экономика, право.',
  },
  '121': {
    'website': 'https://kazniivh.kz',
    'email': 'info@kazniivh.kz',
    'tuitionRange': '400 000 - 800 000 тг/год',
    'hasDormitory': true,
    'description': 'Казахский национальный университет водного хозяйства в Таразе. Водные ресурсы, ирригация, экология.',
  },
  '126': {
    'website': 'https://anhalt.kz',
    'email': 'info@anhalt.kz',
    'tuitionRange': '2 000 000 - 3 500 000 тг/год',
    'hasDormitory': false,
    'description': 'Филиал университета Анхальт в Алматы. Архитектура, дизайн, IT, бизнес. Обучение на немецком/английском.',
  },
  '127': {
    'website': 'https://woosong.kz',
    'email': 'info@woosong.kz',
    'tuitionRange': '1 500 000 - 2 500 000 тг/год',
    'hasDormitory': true,
    'description': 'Woosong University Kazakhstan в Туркестане. Филиал южнокорейского университета. IT, бизнес, кулинарное искусство.',
  },
};

void main() {
  final File csvFile = File('tools/university_data.csv');
  if (!csvFile.existsSync()) {
    print('❌ Файл tools/university_data.csv не найден!');
    print('   Сначала запустите: dart run tools/export_current_data.dart');
    exit(1);
  }

  final String content = csvFile.readAsStringSync(encoding: utf8);
  final List<String> lines = content.split('\n');

  if (lines.isEmpty) {
    print('❌ Файл пуст!');
    exit(1);
  }

  // Парсим заголовки
  final List<String> headers = _parseCsvRow(lines[0]);
  print('📋 Заголовки: ${headers.join(', ')}');

  final int idIdx = headers.indexOf('id');
  final int websiteIdx = headers.indexOf('website');
  final int emailIdx = headers.indexOf('email');
  final int tuitionIdx = headers.indexOf('tuitionRange');
  final int dormIdx = headers.indexOf('hasDormitory');
  final int descIdx = headers.indexOf('description');

  if (idIdx == -1 || websiteIdx == -1) {
    print('❌ Неверный формат CSV!');
    exit(1);
  }

  int updated = 0;
  int total = 0;
  final List<String> updatedLines = [lines[0]];

  for (int i = 1; i < lines.length; i++) {
    final String line = lines[i].trim();
    if (line.isEmpty) continue;

    total++;
    final List<String> fields = _parseCsvRow(line);

    if (fields.length < headers.length) {
      updatedLines.add(line);
      continue;
    }

    final String id = fields[idIdx].trim();
    final Map<String, dynamic>? data = universityData[id];

    if (data != null) {
      // Обновляем поля
      if (data.containsKey('website') && fields[websiteIdx].trim().isEmpty) {
        fields[websiteIdx] = data['website'] as String;
      }
      if (data.containsKey('email') &&
          emailIdx != -1 &&
          fields[emailIdx].trim().isEmpty) {
        fields[emailIdx] = data['email'] as String;
      }
      if (data.containsKey('tuitionRange') &&
          tuitionIdx != -1 &&
          fields[tuitionIdx].trim().isEmpty) {
        fields[tuitionIdx] = data['tuitionRange'] as String;
      }
      if (data.containsKey('hasDormitory') && dormIdx != -1) {
        fields[dormIdx] = (data['hasDormitory'] as bool).toString();
      }
      if (data.containsKey('description') &&
          descIdx != -1 &&
          (fields[descIdx].trim().isEmpty ||
              fields[descIdx].contains('Официальные данные eGov'))) {
        fields[descIdx] = data['description'] as String;
      }
      updated++;
    }

    // Пересобираем строку CSV
    final StringBuffer row = StringBuffer();
    for (int j = 0; j < fields.length; j++) {
      if (j > 0) row.write(',');
      row.write(_escapeCsv(fields[j]));
    }
    updatedLines.add(row.toString());
  }

  // Сохраняем
  csvFile.writeAsStringSync(updatedLines.join('\n'), encoding: utf8);

  print('');
  print('✅ Обновлено: $updated из $total университетов');
  print('💾 Файл сохранён: tools/university_data.csv');
  print('');
  print('📊 Покрытие данными: ${(updated * 100 / total).round()}%');
  print('');
  print('🔧 Далее запустите:');
  print(
    '   dart run tools/csv_to_json_converter.dart tools/university_data.csv',
  );
}

List<String> _parseCsvRow(String row) {
  final List<String> fields = [];
  final StringBuffer current = StringBuffer();
  bool inQuotes = false;

  for (int i = 0; i < row.length; i++) {
    final String char = row[i];
    if (char == '"') {
      if (inQuotes && i + 1 < row.length && row[i + 1] == '"') {
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

String _escapeCsv(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
