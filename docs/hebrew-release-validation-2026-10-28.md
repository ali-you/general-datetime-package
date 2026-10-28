# Hebrew release validation — 2026-10-28

The prepared Hebrew chronology and formatter implementations pass the validation
below. No production arithmetic or formatting defect was found. Release versions
are `general_datetime_core` 2.0.0, `general_datetime` 4.0.0,
`general_date_format_core` 2.0.0, and `general_date_format` 3.0.0.
`general_calendar` 1.0.0 already exists on pub.dev and needs no Hebrew code change.

## Independent full-range comparison

An external installation of `@hebcal/hdate` **0.23.1** generated reference year
starts and month lengths using its Rata Die implementation. The Dart oracle
validator compared **all 3,652,078 days**, **123,671 months**, and **9,999 years**
in both conversion directions, including weekdays. Every comparison passed.
The same exhaustive comparison also passed in a compiled native executable.
The reference package is used only as a development oracle; its implementation
is not copied into or depended on by the Dart libraries.

A fresh `.NET 10.0.11 System.Globalization.HebrewCalendar` reference also passed
for every day in complete Hebrew years **5344–5999**: **239,612 days** and
**8,114 months**, in both directions.

Node 22.16.0's ICU 77.1 `Intl` Hebrew formatter was investigated as a third
reference. Its year starts disagree with both Hebcal and .NET in some years
(55 within AM 1–9999); it must not be treated as the correctness oracle.
For example, 1 Tishri 5807 is Gregorian **2046-10-01** according to Hebcal,
.NET, and this library, while that runtime's Intl reports the following day.
Regression fixtures now include years 5462, 5560, and 5807 to retain these
independently checked postponement cases.

To reproduce the full-range comparison from the repository root:

```console
npm install --prefix .dart_tool/hebrew_oracle --ignore-scripts --no-audit --no-fund @hebcal/hdate@0.23.1
node tool/generate_hebrew_oracle.mjs .dart_tool/hebrew_oracle .dart_tool/hebrew_oracle/reference.json
cd packages/general_datetime_core
dart run tool/validate_hebrew_oracle.dart ../../.dart_tool/hebrew_oracle/reference.json
```

Reference sources: [Hebcal](https://github.com/hebcal/hdate-js),
[Hebcal converter](https://www.hebcal.com/converter?cfg=json&gy=2046&gm=10&gd=1&g2h=1),
and [.NET HebrewCalendar](https://learn.microsoft.com/dotnet/api/system.globalization.hebrewcalendar).

## Package and portability checks

Host: Windows, Flutter **3.47.6**, Dart **3.13.5**, Node **22.16.0**.

| Check | Result |
| --- | --- |
| Chronology core complete VM suite | 36 passed |
| Formatter core complete VM suite | 76 passed |
| Chronology Flutter complete suite | 328 passed |
| Formatter Flutter complete suite | 509 passed |
| Calendar widget complete suite | 86 passed |
| Calendar application demo | 11 passed |
| Formatter example | 6 passed |
| Calendar widget example | 16 passed |
| Chronology core portable Node suites | 31 passed |
| Chrome JavaScript and WebAssembly | 9 chronology and 10 formatter cases passed per compiler |
| Formatter Node timezone suites | 67 passed each: Tehran, Lord Howe, Monrovia |
| Minimum Dart 3.4 core suites | 36 chronology and 76 formatter tests passed |
| All three repository analyses | No issues |
| Pinned Persian/Hijri/Hebrew CLDR data | Verified all 110 source locales per calendar |
| Chronology and formatter CI formatting targets | No changes |

The eight complete native suites total **1,068 passing cases**. Formatter Hebrew
coverage includes all 120 locale identifiers, both Adars, absent-month rejection,
strict/loose parsing, digit policy, fractions, year windows, and translated pickers.
The additional Node suites exercise DST and historical second-resolution offsets.

The Windows Flutter test runner required temporary CanvasKit junctions inside
the test directories and a root-level forwarding entry for the nested Hebrew
picker suite. The original tests ran unchanged; these temporary paths were
removed after validation. The installed SDK was not modified.

Release-archive results are recorded in the accompanying command logs.
Local evidence, independent oracle inputs, and command exit records are
retained under `.dart_tool/validation/2026-10-28/` (ignored by Git).

The existing two uncommitted chronology example configuration edits were
preserved and are excluded from the release commits. Physical-device execution,
iOS, and a local Flutter 3.32 installation are not covered by these results;
the repository CI defines the Flutter minimum-version and device jobs.
