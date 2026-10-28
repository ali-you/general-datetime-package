"""Run Chinese chronology under real Node timezone rules without changing OS settings.

python tool/validate_chinese_timezones.py --dart /path/to/dart [--node node]
"""
import argparse
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / 'packages/general_datetime_core'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dart', default='dart')
    parser.add_argument('--node', default='node')
    args = parser.parse_args()
    output = CORE / '.dart_tool/chinese-timezones.js'
    for zone in ['UTC', 'America/New_York', 'Asia/Tehran', 'Asia/Shanghai', 'Pacific/Apia']:
        subprocess.run([args.dart, 'compile', 'js', f'-DCALENDAR_TEST_TZ={zone}',
                        'tool/validate_chinese_timezones.dart', '-o', str(output)],
                       cwd=CORE, check=True, stdout=subprocess.DEVNULL)
        environment = dict(os.environ, TZ=zone)
        subprocess.run([args.node, '-e', 'globalThis.self=globalThis;require(process.argv[1]);',
                        str(output)], env=environment, cwd=CORE, check=True)


if __name__ == '__main__':
    main()
