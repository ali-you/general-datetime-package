# Amanta lunisolar calendar

`AmantaDate` implements the new-moon scheme from Reingold and Dershowitz's
[Calendrica 4.0](https://github.com/EdReingold/calendar-code2/tree/9afc1f3277b839db1a70c2350d6c708ac83df78f).
It supports Vikrama years 2057–2107 (Gregorian 2000-04-05 through 2051-04-11),
and uses that reference's traditional calculation
of sunrise at Ujjain. Other regional calendars and modern astronomical
calculations can assign different lunar labels to the same Gregorian day.

```dart
final date = AmantaDate.fromGregorian(2023, 7, 22);
print(date.day); // 5: sequential civil day in the month
print(date.tithi); // 4: lunar label at sunrise in Ujjain
print(date.isRepeatedTithi); // true: the previous civil day also had tithi 4
print(date.isLeapMonth); // true

final pickerDate = AmantaDateTime.atStartOfDay(date);
const delegate = AmantaCalendarDelegate(); // package:general_datetime/delegates.dart
```

`month` is the chronological ordinal. `lunarMonth` identifies the traditional
month number, which an intercalary month shares with its regular counterpart.
Use `AmantaDate.fromLunarMonth` with the explicit leap flag when constructing
by traditional month. `toGregorian()` returns UTC midnight as a civil-day
coordinate. `AmantaDateTime.fromDateTime()` preserves a native instant and
maps its UTC or local Gregorian wall date. The tithi is a label for that
date's sunrise, independent of the clock time.

The delegate implements the existing Material picker interface. It uses
ordinal days in the grid and accepts compact `YYYY-MM-DD` input in Vikrama
year, ordinal month, and civil day. For Flutter's range picker use
`delegate.rangePickerDelegate` and, on Flutter 3.32, the existing
`calendarDateRangePickerBuilder`. The companion `AmantaDateFormat` provides
English and Hindi traditional labels and round trips compact civil dates.

Picker dates use local midnight when it exists. If the clock skips midnight,
the picker uses the native normalized time on the same day. If the host zone
skips an entire date, the picker uses UTC midnight to keep that civil date
selectable and distinct from its neighbors. Use `civilDate` for all-day values.
Explicit local clock times passed to `AmantaDateTime.fromCivilDate` still
reject a nonexistent time. `CalendarDateUtils.dateOnly` uses the same
start-of-day rule and preserves UTC input mode.

To verify the picker fallback in Node, run `flutter pub get`, then use the
commands below with `zone` set to `UTC`, `America/Sao_Paulo`, or
`Pacific/Apia`.

```sh
zone=Pacific/Apia
dart compile js "-DAMANTA_TEST_TZ=$zone" tool/validate_amanta_picker_timezones.dart -o .dart_tool/amanta-picker.js
TZ="$zone" node .dart_tool/amanta-picker.js
```

To store an all-day date, keep the Gregorian civil date or the `dayIndex`
alongside your application's calendar identifier. The built-in calendar
registry and version-1 JSON schema do not assign an Amanta identifier.

To regenerate, obtain `calendar.l` at the pinned revision linked above and
run the following from the repository root. The first command uses
[ABCL 1.9.2](https://abcl.org/) and the second uses Python 3.10 or later.

```sh
java --add-opens=java.base/java.lang=ALL-UNNAMED -jar abcl-1.9.2.jar --noinform --noinit --batch --load tool/generate_amanta.lisp -- calendar.l days.csv
python tool/pack_amanta.py days.csv packages/general_datetime_core/lib/src/calendars/amanta/amanta_calendar_data.dart
```

The table is calculated from the Apache-2.0 reference implementation.
Copyright in the upstream reference code belongs to Edward M. Reingold and
Nachum Dershowitz.
