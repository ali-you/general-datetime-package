import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:test/test.dart';

void main() {
  final fixtures = <CalendarId, List<DateTime>>{
    CalendarId.chinese: [
      DateTime.utc(1902),
      DateTime.utc(1969),
      DateTime.utc(2025),
      DateTime.utc(2099)
    ],
    CalendarId.persian: [
      DateTime.utc(600),
      DateTime.utc(1600),
      DateTime.utc(2024),
      DateTime.utc(2300),
      DateTime.utc(3000)
    ],
    CalendarId.islamicUmalqura: [
      DateTime.utc(1883),
      DateTime.utc(2024),
      DateTime.utc(2174)
    ],
    CalendarId.hebrew: [
      DateTime.utc(-3760, 10),
      DateTime.utc(1600),
      DateTime.utc(2024),
      DateTime.utc(2300),
      DateTime.utc(6000)
    ],
  };
  for (final entry in fixtures.entries) {
    final system = CalendarSystems.forId(entry.key);
    final days = [
      ...entry.value,
      for (final bound in [system.minimumDate, system.maximumDate])
        system.toGregorianDay(bound.year, bound.month, bound.day),
    ];
    for (final utc in [true, false]) {
      test('${entry.key.identifier} preserves split precision, UTC=$utc', () {
        for (final day in days) {
          for (final micros in [1, 7, 123, 455, 456, 457, 999]) {
            // The last microsecond of a second exposes epoch rounding/carry.
            final native = utc
                ? DateTime.utc(
                    day.year, day.month, day.day, 12, 34, 59, 999, micros)
                : DateTime(
                    day.year, day.month, day.day, 12, 34, 59, 999, micros);
            final value = system.fromInstant(native, isUtc: utc);
            expect(value.microsecond, native.microsecond);
            expect(value.millisecondsSinceEpoch, native.millisecondsSinceEpoch);
            expect(value, native);
            expect(native, value);
            expect(value.hashCode, native.hashCode);
            expect({native: 'native'}[value], 'native');
            expect({value: 'calendar'}[native], 'calendar');
            expect(value.timeZoneOffset, native.timeZoneOffset);
            expect(value.timeZoneName, native.timeZoneName);
            expect(value.difference(native), Duration.zero);
            expect(native.difference(value), Duration.zero);
            final next = native.add(const Duration(microseconds: 1));
            expect(value.add(const Duration(microseconds: 1)), next);
            expect(value.isBefore(next), isTrue);
            expect(next.isAfter(value), isTrue);
            expect(value.compareTo(next), -1);
            expect(value.subtract(const Duration(microseconds: 1)),
                native.subtract(const Duration(microseconds: 1)));
            expect(CalendarDateUtils.toGregorian(value), native);
            expect(CalendarDateUtils.toGregorian(native), native);
            expect(CalendarSystems.gregorian.fromInstant(value, isUtc: utc),
                native);
            expect(value.toUtc(), native.toUtc());
            expect(value.toLocal(), native.toLocal());
            final direct = system.construct(value.year, value.month, value.day,
                hour: 12,
                minute: 34,
                second: 59,
                millisecond: 999,
                microsecond: native.microsecond,
                isUtc: utc);
            expect(direct, native);
            final wholeSecond = native.subtract(Duration(
                milliseconds: native.millisecond,
                microseconds: native.microsecond));
            final seconds = wholeSecond.millisecondsSinceEpoch ~/ 1000;
            expect(
                (value as GeneralDateTimeInterface).secondsSinceEpoch, seconds);
            expect((value as GeneralDateTimeInterface).toDateTime(), native);
            if (native.year >= 0 && native.year <= 9999) {
              final instant = CalendarInstant.fromDateTime(value);
              expect(CalendarInstant.fromJson(instant.toJson()).instant,
                  native.toUtc());
            }
          }
        }
      });
    }
  }
}
