# Migration and release alignment

[Documentation index](README.md)

## Prepared release versions

The manifests, installation examples and changelogs now use this release matrix:

| Package | Prepared version | Package dependencies |
| --- | --- | --- |
| `general_datetime_core` | **2.0.0** | No runtime dependencies |
| `general_datetime` | **4.0.0** | `general_datetime_core ^2.0.0` |
| `general_date_format_core` | **2.0.0** | `general_datetime_core ^2.0.0` |
| `general_date_format` | **3.0.0** | Formatter core `^2.0.0`, chronology wrapper `^4.0.0` |

Hebrew support is included throughout this pair. Dart remains `>=3.4.0 <4.0.0`;
Flutter wrappers require Flutter `>=3.32.0`. Version alignment is complete in
source; no publication is performed by this update. Until matching hosted
versions are available, use the [local setup](development.md#dependency-resolution).
See [release preparation](release-preparation.md) for release order and checks.

## Hebrew and core 2.0.0 compatibility

`CalendarId.hebrew` adds a fourth enum value. Update exhaustive switches and
code that assumes `CalendarId.values` has three entries. Existing enum indices
and Persian/Hijri version-1 JSON payloads stay unchanged. Older core 1.x decoders
reject a Hebrew record; upgrade decoders before sharing records with Hebrew.

Hebrew uses stable slots 1–13, with Adar I=6 absent in common years and
Adar/Adar II=7. Use `CalendarSystems.monthsOfYear` for iteration. Civil month
addition counts actual months, and `MissingMonthPolicy` handles Adar I when
adding years. Keep day overflow policy separate. These changes preserve
existing Persian/Hijri arithmetic and formatting behavior.

The companion formatter core 2.0.0 also removes Gregorian selectors and the
unused locale initialization hook. Use application-owned `intl.DateFormat`
for Gregorian dates; bundled calendar symbols need no initialization call.
Use `GeneralDateFormat.now` to control two-digit-year parsing. Hebrew quarter
patterns are unsupported; Persian/Hijri quarters retain their existing behavior.

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
