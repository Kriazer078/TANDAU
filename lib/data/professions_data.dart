import '../models/profession.dart';

/// 📊 Данные по профессиям — реальные зарплаты Казахстана
/// Источник: hh.kz, 2024–2025, стартовые позиции без опыта
/// Стоимость обучения: средние данные по топ-вузам Казахстана
const List<Profession> kProfessionsData = [
  Profession(
    id: 'programmer',
    name: 'Программист',
    nameKz: 'Бағдарламашы',
    startSalary: 300000, // hh.kz: junior developer, Almaty/Astana
    tuitionPerYear: 1200000, // IITU, Narxoz, KIMEP avg
    studyYears: 4,
    emoji: '💻',
  ),
  Profession(
    id: 'doctor',
    name: 'Врач',
    nameKz: 'Дәрігер',
    startSalary: 180000, // hh.kz: intern/resident, state hospital
    tuitionPerYear: 1000000, // KazNMU, Astana Medical University
    studyYears: 6,
    emoji: '🏥',
  ),
  Profession(
    id: 'lawyer',
    name: 'Юрист',
    nameKz: 'Заңгер',
    startSalary: 200000, // hh.kz: junior lawyer, legal firm
    tuitionPerYear: 800000, // KazGUU, ENU
    studyYears: 4,
    emoji: '⚖️',
  ),
  Profession(
    id: 'engineer',
    name: 'Инженер',
    nameKz: 'Инженер',
    startSalary: 220000, // hh.kz: junior engineer, manufacturing
    tuitionPerYear: 900000, // AUPET, Satbayev University
    studyYears: 4,
    emoji: '⚙️',
  ),
  Profession(
    id: 'teacher',
    name: 'Учитель',
    nameKz: 'Мұғалім',
    startSalary: 150000, // hh.kz: school teacher + state bonus
    tuitionPerYear: 600000, // KazNPU, regional pedagogical
    studyYears: 4,
    emoji: '📚',
  ),
  Profession(
    id: 'economist',
    name: 'Экономист',
    nameKz: 'Экономист',
    startSalary: 200000, // hh.kz: junior economist, finance sector
    tuitionPerYear: 800000, // Narxoz, Al-Farabi, ENU
    studyYears: 4,
    emoji: '📊',
  ),
  Profession(
    id: 'architect',
    name: 'Архитектор',
    nameKz: 'Сәулетші',
    startSalary: 250000, // hh.kz: junior architect, design bureau
    tuitionPerYear: 1000000, // KazNTU, AUPET
    studyYears: 5,
    emoji: '🏛️',
  ),
  Profession(
    id: 'psychologist',
    name: 'Психолог',
    nameKz: 'Психолог',
    startSalary: 160000, // hh.kz: psychologist, education/clinic
    tuitionPerYear: 700000, // Al-Farabi, ENU
    studyYears: 4,
    emoji: '🧠',
  ),
  Profession(
    id: 'manager',
    name: 'Менеджер',
    nameKz: 'Менеджер',
    startSalary: 220000, // hh.kz: junior manager, corporate
    tuitionPerYear: 750000, // Narxoz, Al-Farabi, IAB
    studyYears: 4,
    emoji: '📋',
  ),
  Profession(
    id: 'designer',
    name: 'Дизайнер',
    nameKz: 'Дизайнер',
    startSalary: 200000, // hh.kz: junior designer, agency/freelance
    tuitionPerYear: 850000, // Almaty art college, KazNTU
    studyYears: 4,
    emoji: '🎨',
  ),
];
