"""Resolve both repositories to one explicit local chronology/formatter pair."""
import argparse
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--chronology', type=Path, required=True)
parser.add_argument('--formatter', type=Path, required=True)
args = parser.parse_args()
chronology, formatter = args.chronology.resolve(), args.formatter.resolve()
for root in [chronology, formatter]:
    if not (root / 'pubspec.yaml').is_file():
        raise SystemExit(f'Missing repository: {root}')
core = chronology / 'packages/general_datetime_core'
format_core = formatter / 'packages/general_date_format_core'


def write(directory, dependencies):
    if not (directory / 'pubspec.yaml').exists():
        return
    # Quote paths for spaces, ':' and Windows separators in YAML.
    content = 'dependency_overrides:\n' + ''.join(
        f"  {name}:\n    path: '{path.as_posix().replace(chr(39), chr(39) * 2)}'\n"
        for name, path in dependencies.items())
    (directory / 'pubspec_overrides.yaml').write_text(content, encoding='utf-8')


all_dependencies = {'general_datetime': chronology, 'general_datetime_core': core,
                    'general_date_format_core': format_core, 'general_date_format': formatter}
for directory in [chronology, chronology / 'example', formatter, formatter / 'example', chronology / 'apps/calendar_demo']:
    write(directory, all_dependencies)
for directory in [format_core]:
    write(directory, {'general_datetime_core': core})
print(f'Chronology: {chronology}\nFormatter: {formatter}')
