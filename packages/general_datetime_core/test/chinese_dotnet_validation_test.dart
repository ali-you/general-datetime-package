@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:general_datetime_core/src/calendars/chinese/chinese_calendar_calculation.dart';
import 'package:test/test.dart';

void main() {
  final rows = jsonDecode(
          File('test/fixtures/chinese_dotnet_months.json').readAsStringSync())
      as List;
  test('every supported civil day agrees with the .NET runtime oracle', () {
    var total = 0;
    DateTime? previous;
    for (final row in rows) {
      final start = DateTime.parse('${row[0]}T00:00:00Z');
      final year = row[1] as int, month = row[2] as int, length = row[5] as int;
      expect(ChineseDateTime.daysInMonth(year, month), length);
      for (var day = 1; day <= length; day++) {
        final native = start.add(Duration(days: day - 1));
        if (previous != null) expect(native.difference(previous).inDays, 1);
        previous = native;
        final date = ChineseDateTime.fromDateTime(native);
        expect((
          date.year,
          date.month,
          date.lunarMonth,
          date.isLeapMonth,
          date.day
        ), (
          year,
          month,
          row[3],
          row[4],
          day
        ), reason: native.toIso8601String());
        expect(ChineseDateTime.utc(year, month, day).toDateTime(), native);
        expect(date.weekday, native.weekday);
        expect(date.julianDay,
            native.difference(DateTime.utc(1970)).inDays + 2440588);
        expect(ChineseCalendarCalculation.toDayIndex(year, month, day),
            native.difference(DateTime.utc(1970)).inDays);
        expect(
            date.dayOfYear,
            native.difference(ChineseDateTime.utc(year).toDateTime()).inDays +
                1);
        total++;
      }
      final first = CalendarDate(
          calendar: CalendarId.chinese, year: year, month: month, day: 1);
      if (row != rows.last) {
        final next = first.addMonths(1);
        expect(next.addMonths(-1), first);
        expect(next.gregorianDay, start.add(Duration(days: length)));
      }
    }
    expect(
        total,
        ChineseDateTime.maximumGregorianDate
                .difference(ChineseDateTime.minimumGregorianDate)
                .inDays +
            1);
  });

  test(
      'all month identities, year lengths and constructors match the runtime oracle',
      () {
    expect(rows.length, 2461);
    for (final fields in [
      (1900, 1, 1),
      (2100, 1, 1),
      (2024, 13, 1),
      (2025, 0, 1),
      (2025, 7, 0),
      (2025, 7, 30)
    ]) {
      expect(
          () => ChineseCalendarCalculation.toDayIndex(
              fields.$1, fields.$2, fields.$3),
          throwsArgumentError);
    }
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final year = row[1] as int, month = row[2] as int;
      final native = DateTime.parse('${row[0]}T00:00:00Z');
      final date = ChineseDateTime.utc(year, month);
      expect(ChineseDateTime.monthIndex(year, month), index);
      expect(
          ChineseDateTime.fromLunar(
                  year: year,
                  lunarMonth: row[3] as int,
                  day: 1,
                  isLeapMonth: row[4] as bool,
                  isUtc: true)
              .toDateTime(),
          native);
      expect(
          ChineseDateTime.ordinalMonth(year, row[3] as int,
              isLeapMonth: row[4] as bool),
          month);
      expect(date.monthCode,
          'M${(row[3] as int).toString().padLeft(2, '0')}${row[4] == true ? 'L' : ''}');
      expect(CalendarDate.fromDateTime(date).monthCode, date.monthCode);
      if (month == 1) {
        final yearRows = rows.where((r) => r[1] == year).toList();
        final leapRows = yearRows.where((r) => r[4] == true).toList();
        expect(ChineseDateTime.monthsInYear(year), yearRows.length);
        expect(ChineseDateTime.leapMonthOfYear(year),
            leapRows.isEmpty ? 0 : leapRows.single[3]);
        expect(ChineseDateTime.monthsOfYear(year),
            yearRows.map((r) => r[2]).toList());
        final length = yearRows.fold<int>(0, (sum, r) => sum + (r[5] as int));
        expect(date.yearLength, length);
        expect(date.isLeapYear, yearRows.length == 13);
        expect(CalendarSystems.chinese.daysInYear(year), length);
      }
    }
  });

  test(
      'month arithmetic in both directions and all overflow policies match independent anchors',
      () {
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      for (final day in [1, row[5] as int]) {
        final source = CalendarDate(
            calendar: CalendarId.chinese,
            year: row[1] as int,
            month: row[2] as int,
            day: day);
        for (final offset in [
          -2461,
          -235,
          -13,
          -12,
          -1,
          0,
          1,
          12,
          13,
          235,
          2461
        ]) {
          final target = index + offset;
          if (target < 0 || target >= rows.length) {
            expect(() => source.addMonths(offset), throwsRangeError);
            continue;
          }
          _expectPeriod(source, day, rows[target],
              (policy) => source.addMonths(offset, policy: policy));
        }
      }
    }
  });

  test(
      'year arithmetic preserves each traditional identity across different leap-month positions',
      () {
    for (final row in rows) {
      final sourceYear = row[1] as int;
      for (final year in {
        1901,
        sourceYear - 1,
        sourceYear,
        sourceYear + 1,
        2099
      }) {
        if (year < 1901 || year > 2099) continue;
        final candidates =
            rows.where((r) => r[1] == year && r[3] == row[3]).toList();
        final exact = candidates.where((r) => r[4] == row[4]).toList();
        final target = exact.isEmpty
            ? candidates.firstWhere((r) => r[4] == false)
            : exact.single;
        for (final day in [1, row[5] as int]) {
          final source = CalendarDate(
              calendar: CalendarId.chinese,
              year: sourceYear,
              month: row[2] as int,
              day: day);
          _expectPeriod(source, day, target,
              (policy) => source.addYears(year - sourceYear, policy: policy));
          if (exact.isEmpty) {
            expect(
                () => source.addYears(year - sourceYear,
                    missingMonth: MissingMonthPolicy.reject),
                throwsArgumentError);
          } else {
            expect(
                source.addYears(year - sourceYear,
                    missingMonth: MissingMonthPolicy.reject),
                source.addYears(year - sourceYear));
          }
        }
      }
    }
  });
}

void _expectPeriod(CalendarDate source, int day, List<dynamic> row,
    CalendarDate Function(CalendarOverflow) operation) {
  final length = row[5] as int;
  final start = DateTime.parse('${row[0]}T00:00:00Z');
  final clamped = day > length ? length : day;
  expect(operation(CalendarOverflow.clamp).gregorianDay,
      start.add(Duration(days: clamped - 1)),
      reason: '$source -> $row');
  if (day > length) {
    expect(() => operation(CalendarOverflow.reject), throwsArgumentError);
  } else {
    expect(operation(CalendarOverflow.reject).gregorianDay,
        start.add(Duration(days: day - 1)));
  }
  final overflow = start.add(Duration(days: day - 1));
  if (overflow.isAfter(ChineseDateTime.maximumGregorianDate)) {
    expect(() => operation(CalendarOverflow.overflow), throwsRangeError);
  } else {
    expect(operation(CalendarOverflow.overflow).gregorianDay, overflow);
  }
}
