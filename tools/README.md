# 🛠️ Инструменты для сбора данных университетов TANDAU

## Рабочий процесс (без парсинга)

```
Google Sheets → Экспорт CSV → csv_to_json_converter.dart → JSON → Firestore
```

## Шаг 1: Создайте Google Spreadsheet

1. Откройте Google Sheets → Создать новую таблицу
2. Импортируйте шаблон: `Файл → Импорт → university_data_template.csv`
3. Или скопируйте заголовки вручную:

| Колонка | Тип | Обязательный | Пример |
|---------|-----|-------------|--------|
| id | текст | ✅ | 1 |
| name | текст | ✅ | ЕНУ им. Гумилёва |
| city | текст | ✅ | Астана |
| website | URL | | https://enu.kz |
| email | email | | info@enu.kz |
| contactPhone | текст | | 8 7172 70 95 00 |
| address | текст | | 010000, г.Астана... |
| studentCount | число | | 11197 |
| tuitionRange | текст | | 500 000 - 1 200 000 ₸ |
| hasDormitory | true/false | | true |
| hasGrants | true/false | | true |
| hasMilitaryDepartment | true/false | | false |
| logoUrl | URL | | (загрузите в Firebase Storage) |
| description | текст | | Один из ведущих... |
| majors | текст (;) | | IT;Медицина;Право |
| specialtyCodes | текст (;) | | B057;B042;B044 |
| passingScore | число | | 50 |
| applicationDeadline | текст | | 15-25 Июля |
| requirements | текст (;) | | ЕНТ |

> ⚠️ Списки разделяйте **точкой с запятой (;)**, НЕ запятой!

## Шаг 2: Заполните данные

### Откуда брать:

| Поле | Источник |
|------|----------|
| name, city, address, phone, students | Уже есть (eGov) |
| website | Поиск в Google: "название вуза официальный сайт" |
| email | Раздел "Контакты" на сайте вуза |
| tuitionRange | Раздел "Приёмная комиссия" / "Стоимость обучения" |
| hasDormitory | Раздел "Студенческая жизнь" / "Общежития" |
| hasMilitaryDepartment | Раздел "Военная кафедра" |
| logoUrl | Загрузить в Firebase Storage |
| description | Раздел "О университете" (2-3 предложения) |
| majors | Раздел "Факультеты" / "Направления подготовки" |
| specialtyCodes | Сопоставить с кодами ГОП из ent_specialties_2026.dart |

## Шаг 3: Экспортируйте CSV

1. В Google Sheets: `Файл → Скачать → Значения, разделённые запятыми (.csv)`
2. Сохраните как `tools/university_data.csv`

## Шаг 4: Конвертируйте в JSON

```bash
dart run tools/csv_to_json_converter.dart tools/university_data.csv
```

Скрипт покажет статистику заполненности и создаст `tools/university_data_output.json`

## Шаг 5: Загрузите в Firestore

Откройте приложение → Admin Panel → Миграция данных (использует DataMigrationHelper)

Или напрямую из JSON через обновлённый скрипт в приложении.

---

## Полезные ссылки

- **data.egov.kz** — OpenData API (нужен apiKey)
- **enic-kazakhstan.edu.kz** — реестры аккредитованных вузов
- **testcenter.kz** — пороговые баллы ЕНТ
