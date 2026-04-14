import re
from pathlib import Path
import json

root = Path('.')
mapping = json.loads((root / 'localization_auto_mapping.json').read_text(encoding='utf-8'))['mapping']
files = list(root.glob('lib/**/*.dart')) + list(root.glob('tandau_admin_web/lib/**/*.dart'))
exclude = ['lib/l10n', 'test/', 'build', '.dart_tool']
pattern = re.compile(r"(?P<prefix>\bconst\s+Text\(|\bText\()'(?P<str>[^'\\]*(?:[\u0080-\uFFFF][^'\\]*)*)'(?P<suffix>\))")
modified_files = []
replaced_total = 0
for p in files:
    sp = str(p)
    if any(e in sp for e in exclude):
        continue
    try:
        text = p.read_text(encoding='utf-8')
    except Exception:
        continue
    def repl(m):
        s = m.group('str')
        key = mapping.get(s)
        if not key:
            return m.group(0)
        pre = m.group('prefix')
        if pre.strip().startswith('const'):
            pre = 'Text('
        return f"{pre}AppLocalizations.of(context)!.{key}{m.group('suffix')}"
    new_text = pattern.sub(repl, text)
    if new_text != text:
        (p.with_suffix(p.suffix + '.bak')).write_text(text, encoding='utf-8')
        p.write_text(new_text, encoding='utf-8')
        modified_files.append(sp)
        replaced_total += sum(1 for _ in pattern.finditer(text))

report = {'modified_files_count': len(modified_files), 'modified_files': modified_files, 'replaced_estimate': replaced_total}
(root / 'localization_replacement_report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print('Done; report at localization_replacement_report.json')
