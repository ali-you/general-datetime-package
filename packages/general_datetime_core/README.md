# General DateTime Core

Pure Dart chronology, conversion, instant arithmetic, field helpers, and JSON
serialization for Gregorian, Persian, and Umm al-Qura dates. No Flutter SDK,
picker, or localization dependency is required.

This is the single implementation used by the Flutter `general_datetime`
package. Its re-exports retain the same class identities, so values can cross
the Dart/Flutter boundary without conversion or a second calendar engine.

## Local use before publication

```yaml
dependencies:
  general_datetime_core:
    path: ../general_date/packages/general_datetime_core
```

```dart
import 'package:general_datetime_core/general_datetime_core.dart';

final instant = DateTime.utc(2024, 3, 20);
final persian = PersianDateTime.fromDateTime(instant); // 1403-01-01
final hijri = HijriDateTime.fromDateTime(instant); // 1445-09-10
final storage = CalendarInstant.fromDateTime(persian).toJson();
```

From this package directory, use only Dart commands:

```sh
dart pub get
dart analyze
dart test
dart run example/cli.dart
dart compile exe example/cli.dart -o .dart_tool/calendar_cli
```

Version 1.0.0 is prepared locally and has not been published. The Flutter
wrapper requires `general_datetime_core: ^1.0.0`; its tracked override template
selects this checkout during development. Publish this package before the
wrapper and the formatting core.

## Contract and integration

Persian supports SH -61 through 3177, including year zero; Umm al-Qura supports
AH 1300 through 1600. The extraction retains the corrected chronology, exact
constructor normalization, UTC/host-local time, microsecond precision, equality,
and finite-range policies. It adds no named timezone or scheduling support.

`CalendarDateUtils` preserves calendar fields for date-only/copy operations and
converts to native Gregorian instants for external helpers. `CalendarInstant`
stores native Gregorian UTC; `CalendarDateRecord` stores tagged civil fields.
Calendar-specific ISO output still requires a matching calendar parser.

For Material pickers, use `general_datetime`, `delegates.dart`, and
`default_localizations.dart` from the Flutter wrapper. For localized formatting
in a server or CLI, use `general_date_format_core`.

The parent repository's exhaustive reference tests exercise this same engine
through the wrapper. This package's Dart tests additionally verify independent
date fixtures, serialization, bounds, and the absence of Flutter in the resolved
dependency graph.

BSD 3-Clause; see [LICENSE](LICENSE). Calendar data attribution is retained in
the source and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
