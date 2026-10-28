"""Validate the .NET Chinese chronology against HKO daily text tables.

Run with Python 3: python tool/validate_chinese_hko.py
Downloads are cached in the ignored tool/.chinese-cache directory. --offline
validates from that cache. Source SHA-256 values are committed separately.
Only complete lunar years are included: 1901..2099. The tables end in Gregorian
2100, so the final complete lunar year ends on 2100-02-08.
"""
import argparse
import concurrent.futures
import datetime as dt
import hashlib
import json
from pathlib import Path
import re
import time
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / 'tool/.chinese-cache'
URL = 'https://www.hko.gov.hk/en/gts/time/calendar/text/files/T{}e.txt'


def fetch(year, offline):
    path = CACHE / f'T{year}e.txt'
    if not path.exists():
        if offline:
            raise RuntimeError(f'Missing cached source: {path}')
        for attempt in range(4):
            try:
                with urllib.request.urlopen(URL.format(year), timeout=45) as response:
                    raw = response.read()
                if not re.search(rf'{year}/0?1/0?1\s', raw.decode('utf-8-sig', errors='replace')):
                    raise ValueError(f'Invalid HKO response for {year}')
                path.write_bytes(raw)
                break
            except Exception:
                if attempt == 3:
                    raise
                time.sleep(attempt + 1)
    return year, path.read_bytes()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--offline', action='store_true')
    parser.add_argument('--check', action='store_true', help='Fail if the recorded comparison or source manifest changed')
    args = parser.parse_args()
    CACHE.mkdir(parents=True, exist_ok=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        sources = sorted(pool.map(lambda y: fetch(y, args.offline), range(1901, 2101)))
    lock_path = ROOT / 'tool/chinese_hko_sources.json'
    if lock_path.exists():
        locked = json.loads(lock_path.read_text())
        for year, raw in sources:
            if hashlib.sha256(raw).hexdigest() != locked[str(year)]['sha256']:
                raise ValueError(f'HKO source hash mismatch: {year}')
    starts = []
    daily = []
    for year, raw in sources:
        count = 0
        for line in raw.decode('utf-8-sig', errors='replace').splitlines():
            match = re.match(r'^(\d{4})/(\d{1,2})/(\d{1,2})\s+(.+?)\s{2,}', line)
            if not match:
                continue
            date = dt.date(*map(int, match.group(1, 2, 3)))
            label = match[4].strip()
            count += 1
            month = re.search(r'(\d+)(?:st|nd|rd|th) Lunar Month', label, re.IGNORECASE)
            if month:
                number = int(month[1])
                leap = bool(starts and starts[-1][1] == number)
                starts.append((date, number, leap))
                daily.append((date, 1))
            else:
                daily.append((date, int(label)))
        if year == 2069:
            # HKO's text omits Dec 30. The same year's published PDF gives
            # lunar day 17 (Dec 31 is day 18); no month boundary is missing.
            daily.append((dt.date(2069, 12, 30), 17))
            count += 1
        assert count == (dt.date(year + 1, 1, 1) - dt.date(year, 1, 1)).days, year
    rows, fixtures = [], []
    epoch = dt.date(1970, 1, 1)
    for year in range(1901, 2100):
        first = next(i for i, (date, number, leap) in enumerate(starts)
                     if date.year == year and number == 1 and not leap)
        end = next(i for i in range(first + 1, len(starts))
                   if starts[i][1:] == (1, False))
        months = starts[first:end]
        lengths = [(starts[i + 1][0] - starts[i][0]).days for i in range(first, end)]
        assert len(months) in (12, 13)
        assert all(length in (29, 30) for length in lengths)
        leap = next((number for _, number, is_leap in months if is_leap), 0)
        assert [n for _, n, is_leap in months if not is_leap] == list(range(1, 13))
        assert sum(is_leap for _, _, is_leap in months) == len(months) - 12
        mask = sum((length - 29) << i for i, length in enumerate(lengths))
        rows.append(f'  ({(months[0][0] - epoch).days}, {leap}, 0x{mask:04x}), // {year}')
        for ordinal, ((date, number, is_leap), length) in enumerate(zip(months, lengths), 1):
            fixtures.append([str(date), year, ordinal, number, is_leap, length])
    # Every downloaded daily label must agree with the derived month boundaries.
    by_day = dict(daily)
    for date, year, ordinal, number, leap, length in fixtures:
        start = dt.date.fromisoformat(date)
        for day in range(length):
            assert by_day[start + dt.timedelta(days=day)] == day + 1
    # HKO website material remains in the ignored local cache. No HKO table
    # or full fixture compilation is redistributed with the runtime package.
    reference = json.loads((ROOT / 'packages/general_datetime_core/test/fixtures/chinese_dotnet_months.json').read_text())
    actual = {}
    for date, year, ordinal, number, leap, length in reference:
        start = dt.date.fromisoformat(date)
        for day in range(length):
            actual[start + dt.timedelta(days=day)] = [year, number, leap, day + 1]
    mismatches = []
    total = 0
    for date, year, ordinal, number, leap, length in fixtures:
        start = dt.date.fromisoformat(date)
        for day in range(length):
            date = start + dt.timedelta(days=day)
            expected = [year, number, leap, day + 1]
            if actual[date] != expected:
                mismatches.append({'date': str(date), 'hko': expected, 'dotnet': actual[date]})
            total += 1
    report = {'checkedDays': total, 'mismatchDays': len(mismatches), 'mismatches': mismatches}
    report_path = ROOT / 'docs/chinese-hko-comparison.json'
    manifest = {str(year): {'url': URL.format(year), 'sha256': hashlib.sha256(raw).hexdigest()}
                for year, raw in sources}
    manifest_path = ROOT / 'tool/chinese_hko_sources.json'
    if args.check:
        if json.loads(report_path.read_text()) != report:
            raise ValueError('Chinese HKO comparison differs from the recorded baseline')
        if json.loads(manifest_path.read_text()) != manifest:
            raise ValueError('Chinese HKO source manifest changed')
    else:
        report_path.write_text(json.dumps(report, indent=2) + '\n')
        manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Compared {total} days with HKO: {len(mismatches)} differences.')


if __name__ == '__main__':
    main()
