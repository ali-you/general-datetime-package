# Chronology release preparation

The coordinated Chinese releases are now published: chronology core **3.0.1**,
chronology wrapper **5.0.1**, formatter core **3.1.0**, formatter wrapper **4.1.0**,
and calendar **1.1.1**. See the [publication record](chinese-publication-2026-11-11.md).
The historical preparation steps below have been superseded by that record.

## Chinese completion — 2026-11-11

Chronology core 3.0.0 / wrapper 5.0.0 and general_calendar 1.1.0 are already
published. Prepare formatter core 3.1.0 followed by formatter wrapper 4.1.0
for Chinese localized formatting/parsing and translated Material adapters.
Formatter core 3.0.0 / wrapper 4.0.0 are compatible with this chronology but
explicitly reject Chinese formatting.

Verify the formatter core against hosted chronology 3.0.0, publish it, then
resolve/test the wrapper without formatter-core overrides before publication.
The demo requires formatter core ^3.1.0. Pre-publication CI uses the reviewed
Chinese formatter commit da1013d1aceb4ae82ffe8c6c50fbe2885551e2c7 through
`.github/actions/use-local-core`; advance that immutable bootstrap pin to the
new formatter release commit after it is available remotely.

Chinese support appends CalendarId.chinese, uses related years 1901-2099,
ordinal numeric months and explicit leap identity. Documented HKO/ICU
differences remain unchanged. See [the completion report](chinese-release-readiness-2026-11-11.md)
for current verification and [the guide](chinese-calendar.md) for API semantics.

The historical Hebrew release information below records the previous majors.

## Coordinated Hebrew release

Status on 2026-10-28: all four coordinated releases below have been published
and their hosted archives verified. See the current
[validation and publication report](hebrew-release-validation-2026-10-28.md)
for exhaustive reference checks, hosted-dependency tests, and archive checksums.

[Documentation index](README.md)

The Hebrew source release is prepared with these aligned versions:

| Package | Version | Required package minimums |
| --- | --- | --- |
| `general_datetime_core` | **2.0.0** | None |
| `general_datetime` | **4.0.0** | Chronology core `^2.0.0` |
| `general_date_format_core` | **2.0.0** | Chronology core `^2.0.0` |
| `general_date_format` | **3.0.0** | Formatter core `^2.0.0`, chronology wrapper `^4.0.0` |

The example and demo consumers use these same minimums. Sample application
versions are unchanged because they are not published packages. Dart remains
`>=3.4.0 <4.0.0`, and Flutter wrappers require Flutter `>=3.32.0`.
This update sets metadata and documentation; it does not publish or create tags.

## Release behavior

Chronology core 2.0.0 adds fixed midnight-based Hebrew dates for AM 1–9999,
calendar systems, helpers, civil arithmetic and version-1 JSON. Stable month
slots preserve identity through leap/common years: Adar I=6, Adar/Adar II=7.
Chronology wrapper 4.0.0 adds Hebrew Material arithmetic and English labels.

Formatter core 2.0.0 adds CLDR 48 Hebrew names across all 120 locale identifiers,
strict/loose year-aware parsing, native digits and six-digit fractions. Formatter
wrapper 3.0.0 adds translated Hebrew Material labels, compact input and ranges.
Quarter patterns remain unsupported for Hebrew. Gregorian formatting belongs
to the consuming application's `intl.DateFormat`.

The core major versions cover the added public enum case and the formatter's
breaking changes. See [migration](migration.md) for exhaustive-switch updates,
Gregorian selectors, locale initialization and parsing-clock migration.
Persian/Hijri calendar behavior and existing storage payloads are preserved.

## Dependency order and local development

Publish in dependency order:

1. `general_datetime_core` 2.0.0.
2. `general_datetime` 4.0.0 and `general_date_format_core` 2.0.0.
3. `general_date_format` 3.0.0.

Keep development overrides while these hosted versions are unavailable. The
chronology root/example select their local core; the demo also needs the local
formatter core. See [development setup](development.md#dependency-resolution).
The formatter repository's `tool/resolve_calendar_pair.py` configures its root,
example and core. A parent override does not apply to an independent package root.

Before publishing each consumer, test an isolated checkout without development
overrides against the already-published dependencies and run
`dart pub publish --dry-run` from each core / `flutter pub publish --dry-run`
from each wrapper. Inspect the archive and preserve data-license notices.
Those commands do not publish; actual publication is a separate authorized action.

After committing the chronology release metadata, update the formatter's
`.github/calendar_pair.json` to that exact commit. The existing pin remains the
known Hebrew implementation commit `31cdbdb3792142d6cf6a09dccc3d552af64641e2`;
it has not been replaced with an invented revision. Source overrides permit
pre-publication CI. The chronology demo CI also needs the formatter core 2.0.0
hosted release or an explicitly configured local formatter checkout.

## Recorded verification

The source-pair checks on 2026-10-12 passed 30 chronology core tests,
75 formatter core tests, 328 chronology Flutter tests, 509 formatter Flutter
tests, 11 demo tests and 6 formatter example tests: **959 native cases** after
the coexistence suite was added. Node timezone selections passed 64 cases in
each of Lord Howe, Monrovia and Tehran. Chrome JavaScript and WebAssembly
integration tests passed for both packages. Android debug APK builds passed.

An independent .NET comparison matched 239,612 Hebrew days in both directions.
850,228 pre-/post-Hebrew records matched for Persian and Hijri. An optimized
Persian/Hijri formatter sample grew by 32,231 JavaScript bytes / 7,277 gzip bytes;
this is one program, not an application-wide size estimate.

See [package validation](hebrew-package-validation-2026-10-12.md) and
[existing-calendar regression](hebrew-existing-calendar-regression-2026-10-12.md)
for commands, SDKs and evidence. Minimum SDK execution, iOS, physical Android
execution, release-mode mobile builds and hosted dependency checks remain
separate release gates. Previous test results do not certify publication.
