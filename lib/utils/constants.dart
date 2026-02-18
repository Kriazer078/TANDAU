class AppConstants {
  static const List<String> educationOptions = ['11 класс', 'Колледж'];

  static const List<String> cities = [
    'Алматы',
    'Астана',
    'Шымкент',
    'Караганда',
    'Актобе',
    'Усть-Каменогорск',
    'Костанай',
    'Семей',
    'Павлодар',
    'Атырау',
    'Кызылорда',
    'Тараз',
    'Уральск',
    'Актау',
    'Петропавловск',
    'Кокшетау',
    'Талдыкорган',
    'Темиртау',
    'Туркестан',
    'Другой',
  ];

  static final List<String> ageOptions = List.generate(
    17,
    (i) => (i + 14).toString(),
  );
}
