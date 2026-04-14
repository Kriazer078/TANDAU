import re
import json
from pathlib import Path
from deep_translator import GoogleTranslator

# setup translator
translator_kk = GoogleTranslator(source='ru', target='kk')
translator_en = GoogleTranslator(source='ru', target='en')

def translate_safely(text, target):
    try:
        t = GoogleTranslator(source='ru', target=target).translate(text)
        return t if t else text
    except:
        return text

# files to process
data_files = [
    'lib/data/klimov_test_data.dart',
    'lib/data/holland_test_data.dart'
]

translations = {}

for file in data_files:
    file_path = Path(file)
    if not file_path.exists(): continue
    text = file_path.read_text(encoding='utf-8')
    
    # find all string literals with russian characters
    matches = re.findall(r"'([^'\\\n\r]*[а-яА-ЯёЁ][^'\\\n\r]*)'", text)
    matches = list(set(matches))
    print(f"File: {file}, found {len(matches)} strings")
    for m in matches:
        if m not in translations:
            kk = translate_safely(m, 'kk')
            en = translate_safely(m, 'en')
            translations[m] = {'kk': kk, 'en': en}

# Now generate a dart dictionary file
dart_dict = """import 'package:flutter/widgets.dart';

// Auto-generated testing translations dictionary
const Map<String, Map<String, String>> testTranslations = {
"""
for ru, locs in translations.items():
    ru_esc = ru.replace("'", "\\'")
    kk_esc = locs['kk'].replace("'", "\\'")
    en_esc = locs['en'].replace("'", "\\'")
    dart_dict += f"  '{ru_esc}': {{\n    'kk': '{kk_esc}',\n    'en': '{en_esc}',\n  }},\n"

dart_dict += """};

String trTest(BuildContext context, String ruText) {
  final langCode = Localizations.localeOf(context).languageCode;
  if (langCode == 'ru') return ruText;
  return testTranslations[ruText]?[langCode] ?? ruText;
}
"""

Path('lib/data/test_translations.dart').write_text(dart_dict, encoding='utf-8')
print("Generated test_translations.dart")
