# Getting started

[Documentation index](README.md)

## Choose the package

| Package | Use it for | SDK requirements in this checkout |
| --- | --- | --- |
| `general_datetime_core` | Chronology, conversion, civil dates, and JSON on servers, CLIs, or Flutter | Dart `>=3.4.0 <4.0.0` |
| `general_datetime` | The same core types plus Material calendar delegates and default localizations | Dart `>=3.4.0 <4.0.0`, Flutter `>=3.32.0` |

The Flutter package re-exports the core classes. Importing a class through both
packages does not create distinct runtime types.

Localized patterns, translated month names, digit systems, and strict localized
parsing belong to the companion `general_date_format` and
`general_date_format_core` packages. They are maintained separately. Check their
dependency constraints when combining wrapper versions; see [migration](migration.md).

## Install and import

For a pure Dart application:

```yaml
dependencies:
  general_datetime_core: ^2.0.0
```

Run `dart pub get`, then import:

```dart
import 'package:general_datetime_core/general_datetime_core.dart';
```

To develop against this Flutter checkout from a sibling application:

```yaml
dependencies:
  general_datetime:
    path: ../general_date
```

Adjust the relative path to your application and run `flutter pub get`. The
wrapper itself declares `general_datetime_core: ^2.0.0` from the package host;
this path dependency alone does not select the core source in this repository.
See [development](development.md) for testing local core changes.

Use the public Flutter libraries:

```dart
import 'package:general_datetime/general_datetime.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/default_localizations.dart';
```

The prepared hosted wrapper constraint is `general_datetime: ^4.0.0`.
These release versions are aligned in source; they have not been published
as part of this work. Use development overrides until hosted releases are
available. See [migration](migration.md) for the complete package matrix.

## Convert an instant

This complete program uses only the Dart core:

```dart
import 'package:general_datetime_core/general_datetime_core.dart';

void main() {
  final native = DateTime.utc(2024, 3, 20, 12, 34, 56, 789, 123);
  final persian = PersianDateTime.fromDateTime(native);
  final hijri = HijriDateTime.fromDateTime(native);

  print(persian.toIso8601String()); // 1403-01-01T12:34:56.789123Z
  print(hijri.toIso8601String()); // 1445-09-10T12:34:56.789123Z
  print(persian.isAtSameMomentAs(hijri)); // true
  print(persian.toDateTime().toIso8601String());
  // 2024-03-20T12:34:56.789123Z
}
```

`fromDateTime` preserves the epoch and UTC/local mode. In contrast,
`PersianDateTime(1403, 1, 1)` interprets its arguments as local Persian wall
fields. Use `.utc(...)` for UTC wall fields.

Native `DateTime` is the Gregorian implementation. The Persian and Hijri classes
extend `DateTime`, exposing their own calendar fields while retaining native
instant semantics.

## Choose the value model

| Requirement | Value |
| --- | --- |
| Timed event, elapsed duration, or epoch conversion | `DateTime`, `PersianDateTime`, or `HijriDateTime` |
| All-day date or month/year navigation | `CalendarDate` |
| Strict calendar/clock construction | `CalendarSystems.forId(id).construct(...)` |
| Persist a timed event | `CalendarInstant` |
| Persist an all-day date | `CalendarDateRecord` |
| Replace calendar fields on a `DateTime`-typed variable | `CalendarDateUtils.copyWith(...)` |

Continue with [calendar operations](calendar-operations.md),
[JSON storage](serialization.md), or [Flutter integration](flutter-integration.md).
