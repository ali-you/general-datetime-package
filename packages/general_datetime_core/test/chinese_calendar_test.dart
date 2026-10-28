import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:test/test.dart';

CalendarDate c(int year, int month, int day) => CalendarDate(
    calendar: CalendarId.chinese, year: year, month: month, day: day);

void main() {
  test('published anchors, repeated month identity and the 2033 leap month',
      () {
    for (final fixture in [
      (DateTime.utc(1901, 2, 19), 1901, 1, 1, false),
      (DateTime.utc(2024, 2, 10), 2024, 1, 1, false),
      (DateTime.utc(2025, 7, 25), 2025, 6, 1, true),
      (DateTime.utc(2033, 12, 22), 2033, 11, 1, true),
      // The pinned .NET table intentionally differs from HKO on this day.
      (DateTime.utc(2057, 9, 28), 2057, 8, 30, false),
      (DateTime.utc(2100, 2, 8), 2099, 12, 30, false),
    ]) {
      final value = ChineseDateTime.fromDateTime(fixture.$1);
      expect((value.year, value.lunarMonth, value.day, value.isLeapMonth),
          (fixture.$2, fixture.$3, fixture.$4, fixture.$5));
      expect(
          ChineseDateTime.fromLunar(
              year: value.year,
              lunarMonth: value.lunarMonth,
              day: value.day,
              isLeapMonth: value.isLeapMonth,
              isUtc: true),
          fixture.$1);
    }
    final leap = ChineseDateTime.utc(2025, 7);
    expect(leap.monthOrdinal, 7);
    expect(leap.monthCode, 'M06L');
    expect(ChineseDateTime.utc(2025, 8).monthCode, 'M07');
    expect(
        () => ChineseDateTime.fromLunar(
            year: 2024, lunarMonth: 6, day: 1, isLeapMonth: true),
        throwsArgumentError);
    expect(() => ChineseDateTime.fromLunar(year: 2025, lunarMonth: 6, day: 31),
        throwsArgumentError);
  });

  test(
      'month/year periods preserve actual month order and traditional identity',
      () {
    expect(c(2025, 6, 1).addMonths(1), c(2025, 7, 1));
    expect(c(2025, 7, 1).addMonths(1), c(2025, 8, 1));
    expect(c(2025, 7, 1).addMonths(-1), c(2025, 6, 1));
    expect(c(2025, 13, 1).addMonths(1), c(2026, 1, 1));
    expect(c(2025, 7, 1).addYears(1), c(2026, 6, 1));
    expect(c(2025, 8, 1).addYears(1), c(2026, 7, 1));
    expect(c(2025, 7, 1).addYears(0, missingMonth: MissingMonthPolicy.reject),
        c(2025, 7, 1));
    expect(
        () =>
            c(2025, 7, 1).addYears(1, missingMonth: MissingMonthPolicy.reject),
        throwsArgumentError);
    final full = c(2025, 6, 30);
    expect(full.addMonths(1), c(2025, 7, 29));
    expect(() => full.addMonths(1, policy: CalendarOverflow.reject),
        throwsArgumentError);
    expect(full.addMonths(1, policy: CalendarOverflow.overflow), c(2025, 8, 1));
    expect(() => full.addMonths(9007199254740991), throwsRangeError);
    expect(() => full.addYears(-9007199254740991), throwsRangeError);
    expect(c(2025, 7, 1).monthCode, 'M06L');
    expect(c(2025, 7, 1).isLeapMonth, isTrue);
  });

  test('finite bounds, normalized constructors, ISO parsing and exact instants',
      () {
    expect(ChineseDateTime.minimumGregorianDate, DateTime.utc(1901, 2, 19));
    expect(ChineseDateTime.maximumGregorianDate, DateTime.utc(2100, 2, 8));
    expect(ChineseDateTime.utc(2025, 14), ChineseDateTime.utc(2026));
    expect(ChineseDateTime.utc(2026, 0), ChineseDateTime.utc(2025, 13));
    expect(
        ChineseDateTime.utc(2100, 1, 0).toDateTime(), DateTime.utc(2100, 2, 8));
    expect(() => ChineseDateTime.utc(1901, 1, 0), throwsRangeError);
    expect(() => ChineseDateTime.utc(2100), throwsRangeError);
    expect(() => ChineseDateTime.utc(2025, 9007199254740991), throwsRangeError);
    expect(ChineseDateTime.tryParse('2025-07-01T12:34:56.123456Z')?.monthCode,
        'M06L');
    expect(ChineseDateTime.tryParse('1899-01-01'), isNull);
    final native = DateTime.utc(2025, 7, 25, 12, 34, 56, 123, 456);
    final value = ChineseDateTime.fromDateTime(native);
    expect(value.toDateTime(), native);
    expect(value.toUtc().microsecond, 456);
    expect(value.toLocal().toUtc(), native);
    expect(value.add(const Duration(microseconds: 1)),
        native.add(const Duration(microseconds: 1)));
    expect(ChineseDateTime.parse(value.toIso8601String()), native);
    expect(
        ChineseDateTime.fromMicrosecondsSinceEpoch(
            native.microsecondsSinceEpoch,
            isUtc: true),
        native);
    expect(CalendarDateUtils.copyWith(value, day: 2),
        ChineseDateTime.utc(2025, 7, 2, 12, 34, 56, 123, 456));
    expect(CalendarDateUtils.dateOnly(value), ChineseDateTime.utc(2025, 7));
    expect(
        ChineseDateTime.isSupportedDateTime(DateTime.utc(2100, 2, 9)), isFalse);
  });

  test('civil and instant JSON preserve the leap month without changing schema',
      () {
    final value = ChineseDateTime.utc(2025, 7);
    final record = CalendarDateRecord.fromDateTime(value);
    expect(record.toJson(), {
      'version': 1,
      'kind': 'calendar-date',
      'calendar': 'chinese',
      'year': 2025,
      'month': 7,
      'day': 1
    });
    final date =
        CalendarDate.fromRecord(CalendarDateRecord.fromJson(record.toJson()));
    expect(date.monthCode, 'M06L');
    expect(date.toCalendar(CalendarId.gregory).gregorianDay,
        DateTime.utc(2025, 7, 25));
    final instant =
        CalendarInstant.fromJson(CalendarInstant.fromDateTime(value).toJson());
    expect(instant.calendar, CalendarId.chinese);
    expect(instant.instant, value.toDateTime());
    expect(
        () => CalendarDateRecord.fromJson(
            {...record.toJson(), 'year': 2024, 'month': 13}),
        throwsFormatException);
  });
}
