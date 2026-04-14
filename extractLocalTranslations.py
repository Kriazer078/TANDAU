import re
import json
from pathlib import Path

files = ['lib/data/klimov_test_data.dart', 'lib/data/holland_test_data.dart']
strings = set()

for f in files:
    content = Path(f).read_text(encoding='utf-8')
    matches = re.findall(r"text:\s*'([^']+)'", content)
    strings.update(matches)
    matches2 = re.findall(r"'(.*?[а-яА-ЯёЁ].*?)'", content)
    strings.update(matches2)

print(json.dumps(list(strings), ensure_ascii=False, indent=2))
