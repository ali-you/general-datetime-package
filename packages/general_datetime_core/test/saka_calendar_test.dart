import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:test/test.dart';

void main() {
  const saka = CalendarSystems.saka;

  test('converts official and Gregorian century boundary dates both ways', () {
    final fixtures = [
      (DateTime.utc(1957, 3, 22), (year: 1879, month: 1, day: 1)),
      (DateTime.utc(2000, 3, 20), (year: 1921, month: 12, day: 30)),
      (DateTime.utc(2000, 3, 21), (year: 1922, month: 1, day: 1)),
      (DateTime.utc(2000, 4, 20), (year: 1922, month: 1, day: 31)),
      (DateTime.utc(2000, 4, 21), (year: 1922, month: 2, day: 1)),
      (DateTime.utc(2026, 3, 22), (year: 1948, month: 1, day: 1)),
      (DateTime.utc(2100, 3, 21), (year: 2021, month: 12, day: 30)),
      (DateTime.utc(2100, 3, 22), (year: 2022, month: 1, day: 1)),
    ];
    for (final (gregorian, civil) in fixtures) {
      expect(saka.fromGregorianDay(gregorian), civil);
      expect(
          saka.toGregorianDay(civil.year, civil.month, civil.day), gregorian);
    }
    expect(saka.daysInYear(1922), 366);
    expect(saka.daysInYear(2022), 365);
    expect(saka.isValidDate(2022, 1, 31), isFalse);
    expect(() => saka.construct(2022, 1, 31), throwsArgumentError);
    expect(SakaDateTime.utc(2022, 1, 31), SakaDateTime.utc(2022, 2));
  });

  test('participates in civil arithmetic, conversion, and wire records', () {
    final leapDay = CalendarDate.fromDateTime(SakaDateTime.utc(1946, 1, 31));
    expect(leapDay.calendar, CalendarId.indian);
    expect(leapDay.monthCode, 'M01');
    final clamped = leapDay.addYears(1);
    expect((clamped.year, clamped.month, clamped.day), (1947, 1, 30));
    final newYear =
        CalendarDate.fromDateTime(SakaDateTime.utc(1947, 12, 30)).addDays(1);
    expect(newYear.gregorianDay, DateTime.utc(2026, 3, 22));
    expect(newYear.toCalendar(CalendarId.gregory).month, 3);
    final record = newYear.toRecord().toJson();
    expect(record['calendar'], 'indian');
    expect(
        CalendarDate.fromRecord(CalendarDateRecord.fromJson(record)), newYear);
    expect(() => CalendarDateRecord.fromJson({...record, 'month': 13}),
        throwsFormatException);
    expect(
        CalendarSystems.monthsOfYear(CalendarId.indian, 1948), hasLength(12));
  });

  test('retains exact instants, including far from the Unix epoch', () {
    final native = DateTime.utc(9999, 3, 21, 23, 59, 59, 999, 997);
    final value = SakaDateTime.fromDateTime(native);
    expect((value.year, value.month, value.day), (9920, 12, 30));
    expect(value.toDateTime(), native);
    expect(value.isAtSameMomentAs(native), isTrue);
    expect(value == native, isTrue);
    expect(native == value, isTrue);
    expect(value.hashCode, native.hashCode);
    expect(value.microsecond, 997);
    expect(value.subtract(const Duration(microseconds: 1)).microsecond, 996);
    final copy = CalendarDateUtils.copyWith(value, microsecond: 998);
    expect(copy, isA<SakaDateTime>());
    expect(copy.difference(value).inMicroseconds, 1);
    final record = CalendarInstant.fromDateTime(value).toJson();
    expect(record['calendar'], 'indian');
    expect(CalendarInstant.fromJson(record).instant, native);
    expect(value.toIso8601String(), '9920-12-30T23:59:59.999997Z');
    expect(() => SakaDateTime.fromDateTime(DateTime.utc(9999, 3, 22)),
        throwsRangeError);
    expect(() => SakaDateTime.fromDateTime(DateTime.utc(79, 3, 21)),
        throwsRangeError);
  });
}
