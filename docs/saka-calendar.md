# Indian National Calendar (Saka)

`CalendarSystems.saka` implements the Indian National Calendar using the
Saka Era and twelve months numbered from Chaitra through Phalguna. Chaitra
starts on March 22, or March 21 in a Gregorian leap year. It has 30 or 31
days respectively. The next five months have 31 days each, and the final six
have 30 days each.

The supported span is Saka **1-01-01 through 9920-12-30**, corresponding to
Gregorian **0079-03-22 through 9999-03-21**. The same civil rules are projected
backward before adoption on 1957-03-22. Dates use midnight-based civil days.
The calculation uses arithmetic and requires no published month table.

[Government of India reference annual](https://pmindiaun.gov.in/public_files/assets/pdf/India_2020_REFERENCEANNUAL.pdf) ·
[India Meteorological Department reference dates](https://packolkata.imd.gov.in/panchang/en/eras) ·
[ICU calendar rules](https://unicode-org.github.io/icu-docs/apidoc/dev/icu4j/com/ibm/icu/util/IndianCalendar.html)

```dart
import 'package:general_datetime_core/general_datetime_core.dart';

void main() {
  final date = SakaDateTime.fromDateTime(DateTime.utc(2026, 3, 22));
  final civil = CalendarDate.fromDateTime(date);
  print(civil); // indian:1948-01-01
  print(civil.addMonths(1).gregorianDay); // 2026-04-21 00:00:00.000Z
  print(civil.toRecord().toJson()); // calendar: indian, year: 1948, ...
}
```

Use `CalendarSystems.saka.construct` or `CalendarDate` for strict validation.
`SakaDateTime` constructors normalize overflowing fields. Use
`CalendarInstant.fromDateTime` for timed records, or `CalendarDateRecord` for
all-day values. Both use the Unicode calendar identifier `indian`. Update
exhaustive `CalendarId` switches and upgrade readers before sending them Saka
records.

For Flutter, pass `SakaCalendarDelegate` with Saka bounds and selected values.
Install `DefaultSakaCalendarMaterialLocalizations.delegate` for English month
labels and `yyyy-mm-dd` input. The companion formatter supplies English and
Hindi through `SakaCalendarMaterialLocalizations.delegate`. For
`showDateRangePicker`, use `rangePickerDelegate` and pass that same instance
to `calendarDateRangePickerBuilder` when supporting Flutter 3.32.

The test suite includes the official conversion for 1 Chaitra 1948
(2026-03-22), Gregorian century leap-year boundaries, serialization, and
Material range selection at both supported endpoints.
