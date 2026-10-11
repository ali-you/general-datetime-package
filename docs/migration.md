# Migration and release alignment

[Documentation index](README.md)

## Version metadata in this checkout

The [wrapper manifest](../pubspec.yaml) declares `general_datetime` **3.0.0**.
The [root README](../README.md) and [changelog](../CHANGELOG.md) describe a
**4.0.0** wrapper. The [core manifest](../packages/general_datetime_core/pubspec.yaml)
declares `general_datetime_core` **1.0.0**. These guides document implemented
source behavior without resolving that release-label discrepancy.

Before publishing, align the wrapper manifest, README installation examples,
changelog, and companion formatter constraint around the chosen release version.
Check the actual hosted package contents before assuming checkout features are
available in an existing version.

The root README records that `general_date_format` 3.0.0 depends on
`general_datetime ^3.0.0`, which excludes 4.0.0. If releasing the wrapper as
4.0.0, update and validate the companion constraint in its own repository.

## Core extraction and imports

Existing public Flutter chronology imports continue to work:

```dart
import 'package:general_datetime/general_datetime.dart';
```

Pure Dart consumers can import:

```dart
import 'package:general_datetime_core/general_datetime_core.dart';
```

These imports resolve to the same core class identities. Keep Material delegates
and localizations in the Flutter wrapper. Replace imports of removed wrapper
`src` chronology/shared forwarding libraries with public imports; internal paths
are not a supported integration boundary.

## Audit existing behavior assumptions

| Existing assumption | Required integration change |
| --- | --- |
| Any Persian or Islamic date can be calculated indefinitely | Validate supported bounds and handle explicit range failures |
| All Persian dates have published official data | Check data coverage separately from calculation support |
| Hijri means any arithmetic/observational Islamic calendar | Treat this implementation as the specific Umm al-Qura chronology |
| Calendar ISO strings can be stored as Gregorian timestamps | Use `CalendarInstant` or explicitly convert to native Gregorian UTC |
| An all-day date is a timestamp at midnight | Use `CalendarDate` and `CalendarDateRecord` |
| `DateTime.copyWith` or Flutter Gregorian helpers preserve custom calendars | Use `CalendarDateUtils` on `DateTime`-typed values |
| A Gregorian date is accepted by a Persian/Hijri delegate | Convert via the target calendar's `fromDateTime` factory |
| Negative fractional epoch seconds truncate toward zero | Account for floor rounding to the containing second |
| Named-zone objects retain their zone rules after conversion | Preserve the zone ID and apply zone rules in the application layer |
| Adding one day means tomorrow at the same local clock time | Distinguish elapsed `Duration` from civil-date navigation |

Normalizing date-time constructors remain available. Use strict calendar systems
or civil dates for validation. Offset parsing validates the final UTC date;
unsupported results fail rather than using a different chronology.

## Update picker integrations

Keep chronology and localization aligned for each dialog. For bounded range
pickers, use `.rangePickerDelegate` with `calendarDateRangePickerBuilder` and
the same delegate instance. Keep scoped localization inside the builder's
optional wrapper. Supply a matching `currentDate` to standalone `YearPicker`.
The [Flutter guide](flutter-integration.md) contains complete function examples.

When switching calendars, convert stored selections or clear them before opening
the picker. Recheck initial-range ordering and supported bounds.

## Validate before release

Resolve hosted cores and test consumers without local development overrides.
Local source success does not establish that a published core includes the same
API. Release dependency order documented by the repository is:

1. `general_datetime_core`.
2. `general_datetime` and the companion `general_date_format_core`.
3. The companion `general_date_format` wrapper.

Run the checks in [development](development.md), including the minimum SDK and
platform gates relevant to the release. Consult the [changelog](../CHANGELOG.md)
for the full set of chronology corrections relative to older versions.
