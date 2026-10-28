import 'dart:convert';

import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:test/test.dart';

void main() {
  final system = CalendarSystems.chinese;
  final minimum = ChineseDateTime.minimumGregorianDate;
  final maximum = ChineseDateTime.maximumGregorianDate;

  test('local lunar construction and field copies retain mode and identity',
      () {
    final value = ChineseDateTime.fromLunar(
        year: 2025,
        lunarMonth: 6,
        day: 1,
        isLeapMonth: true,
        hour: 23,
        minute: 59,
        millisecond: 123,
        microsecond: 456);
    expect(value.toDateTime(), DateTime(2025, 7, 25, 23, 59, 0, 123, 456));
    expect(value.isUtc, isFalse);
    expect(value.name, 'Chinese');
    expect(value.monthLength, 29);
    expect(value.hasOfficialCalendarData, isFalse);
    expect(system.hasPublishedData(2025), isFalse);
    expect(value.copyWith(day: 2, minute: 60).toDateTime(),
        DateTime(2025, 7, 27, 0, 0, 0, 123, 456));
    final DateTime untyped = value;
    final copy = CalendarDateUtils.copyWith(untyped, day: 2, minute: 60);
    expect(copy, isA<ChineseDateTime>());
    expect(copy.isUtc, isFalse);
    expect(copy, value.copyWith(day: 2, minute: 60));
    final utc = value.copyWith(isUtc: true);
    expect(utc.toDateTime(), DateTime.utc(2025, 7, 25, 23, 59, 0, 123, 456));
    expect(utc.copyWith(isUtc: false), value);
    expect(
        ChineseDateTime.fromMicrosecondsSinceEpoch(
            value.microsecondsSinceEpoch),
        value);
    expect(
        ChineseDateTime.fromMillisecondsSinceEpoch(
            value.millisecondsSinceEpoch),
        value.subtract(const Duration(microseconds: 456)));
    expect(ChineseDateTime.parse(value.toString()), value);
    expect(value.toString(), '2025-07-01 23:59:00.123456');
  });

  test(
      'clock factories register Chinese and expose the requested UTC/local mode',
      () {
    final before = DateTime.now();
    final local = ChineseDateTime.now();
    final utc = ChineseDateTime.timestamp();
    final generic = GeneralDateTimeInterface.now<ChineseDateTime>();
    final after = DateTime.now();
    expect(local.isUtc, isFalse);
    expect(utc.isUtc, isTrue);
    expect(generic.isUtc, isFalse);
    for (final value in [local, utc, generic]) {
      expect(value.isBefore(before), isFalse);
      expect(value.isAfter(after), isFalse);
      expect(value.timeZoneName, value.toDateTime().timeZoneName);
    }
  });

  test('strict constructors reject every invalid field without normalization',
      () {
    for (final year in [-9007199254740991, 0, 1900, 2100, 9007199254740991]) {
      expect(ChineseDateTime.isValidDate(year, 1, 1), isFalse);
      expect(() => ChineseDateTime.monthsOfYear(year), throwsRangeError);
      expect(() => system.construct(year, 1, 1), throwsArgumentError);
    }
    for (final month in [-9007199254740991, -1, 0, 14, 9007199254740991]) {
      expect(ChineseDateTime.isValidDate(2025, month, 1), isFalse);
      expect(() => ChineseDateTime.daysInMonth(2025, month), throwsRangeError);
      expect(() => system.construct(2025, month, 1), throwsArgumentError);
    }
    for (final day in [-9007199254740991, 0, 30, 9007199254740991]) {
      expect(ChineseDateTime.isValidDate(2025, 7, day), isFalse);
      expect(
          () => ChineseDateTime.fromLunar(
              year: 2025, lunarMonth: 6, day: day, isLeapMonth: true),
          throwsArgumentError);
    }
    for (final number in [0, 13, 9007199254740991]) {
      expect(
          () => ChineseDateTime.ordinalMonth(2025, number), throwsRangeError);
    }
    for (final clock in [
      {'hour': -1},
      {'hour': 24},
      {'minute': -1},
      {'minute': 60},
      {'second': -1},
      {'second': 60},
      {'millisecond': -1},
      {'millisecond': 1000},
      {'microsecond': -1},
      {'microsecond': 1000},
    ]) {
      expect(
          () => system.construct(2025, 7, 1,
              hour: clock['hour'] ?? 0,
              minute: clock['minute'] ?? 0,
              second: clock['second'] ?? 0,
              millisecond: clock['millisecond'] ?? 0,
              microsecond: clock['microsecond'] ?? 0),
          throwsArgumentError);
      expect(
          () => ChineseDateTime.fromLunar(
              year: 2025,
              lunarMonth: 6,
              day: 1,
              isLeapMonth: true,
              hour: clock['hour'] ?? 0,
              minute: clock['minute'] ?? 0,
              second: clock['second'] ?? 0,
              millisecond: clock['millisecond'] ?? 0,
              microsecond: clock['microsecond'] ?? 0),
          throwsArgumentError);
    }
  });

  test('normalization preserves cancellation and every clock carry and borrow',
      () {
    final start = DateTime.utc(2025, 7, 25);
    for (final fields in [
      [0, 0, 0, 0, -1],
      [0, 0, 0, -1, 0],
      [0, 0, -1, 0, 0],
      [0, -1, 0, 0, 0],
      [-1, 0, 0, 0, 0],
      [24, 0, 0, 0, 0],
      [0, 1440, 0, 0, 0],
      [0, 0, 86400, 0, 0],
      [100000000, -6000000000, 0, 0, 123],
    ]) {
      // Native Duration sums can round large cancelling components on JS.
      // Calculate the independent expectation exactly before native addition.
      final micros = BigInt.from(fields[0]) * BigInt.from(3600000000) +
          BigInt.from(fields[1]) * BigInt.from(60000000) +
          BigInt.from(fields[2]) * BigInt.from(1000000) +
          BigInt.from(fields[3]) * BigInt.from(1000) +
          BigInt.from(fields[4]);
      final expected = start.add(Duration(microseconds: micros.toInt()));
      expect(
          ChineseDateTime.utc(2025, 7, 1, fields[0], fields[1], fields[2],
                  fields[3], fields[4])
              .toDateTime(),
          expected);
    }
    expect(ChineseDateTime.utc(2025, 7, 100000001, -2400000000),
        ChineseDateTime.utc(2025, 7));
    for (final day in [-9007199254740991, 9007199254740991]) {
      expect(() => ChineseDateTime.utc(2025, 7, day), throwsRangeError);
    }
  });

  test(
      'every endpoint microsecond and offset normalization respects wall bounds',
      () {
    final lastInstant = maximum.add(const Duration(
        hours: 23,
        minutes: 59,
        seconds: 59,
        milliseconds: 999,
        microseconds: 999));
    for (final native in [
      minimum,
      minimum.add(const Duration(microseconds: 1)),
      lastInstant.subtract(const Duration(microseconds: 1)),
      lastInstant
    ]) {
      final date = ChineseDateTime.fromDateTime(native);
      expect(date.toDateTime(), native);
      expect(ChineseDateTime.parse(date.toIso8601String()), native);
      expect(system.fromInstant(native), native);
    }
    for (final native in [
      minimum.subtract(const Duration(microseconds: 1)),
      lastInstant.add(const Duration(microseconds: 1))
    ]) {
      expect(ChineseDateTime.isSupportedDateTime(native), isFalse);
      expect(() => ChineseDateTime.fromDateTime(native), throwsRangeError);
    }
    expect(ChineseDateTime.parse('1901-01-00T23:00:00-01:00').toDateTime(),
        minimum);
    expect(ChineseDateTime.parse('2100-01-01T00:30:00+01:00').toDateTime(),
        maximum.add(const Duration(hours: 23, minutes: 30)));
    for (final input in [
      '1901-01-01T00:00:00+00:01',
      '2099-13-30T23:59:59.999999-00:01',
      '2025-07-01T00:00+24:00',
      '2025-07-01T00:00+00:60',
      '2025-07-01T00:00Zjunk',
      '',
      '2025-M06L-01'
    ]) {
      expect(ChineseDateTime.tryParse(input), isNull, reason: input);
      expect(() => ChineseDateTime.parse(input), throwsFormatException,
          reason: input);
    }
  });

  test(
      'negative epochs, hashes, comparisons and every registered calendar retain instants',
      () {
    for (final native in [
      DateTime.utc(1901, 2, 19, 12),
      DateTime.fromMicrosecondsSinceEpoch(-1000001, isUtc: true),
      DateTime.fromMicrosecondsSinceEpoch(-1, isUtc: true),
      DateTime.utc(2025, 7, 25, 23, 59, 59, 999, 999)
    ]) {
      final date = ChineseDateTime.fromDateTime(native);
      final floorSeconds = (native.microsecondsSinceEpoch -
              native.microsecondsSinceEpoch % 1000000) ~/
          1000000;
      expect(date.secondsSinceEpoch, floorSeconds);
      expect(
          ChineseDateTime.fromSecondsSinceEpoch(floorSeconds, isUtc: true)
              .difference(date)
              .inMicroseconds
              .abs(),
          lessThan(1000000));
      expect(
          ChineseDateTime.fromMillisecondsSinceEpoch(
                  native.millisecondsSinceEpoch,
                  isUtc: true)
              .millisecond,
          native.millisecond);
      expect(native == date && date == native, isTrue);
      expect({native: 'same instant'}[date], 'same instant');
      for (final id in CalendarId.values) {
        final other = CalendarSystems.forId(id).fromInstant(native);
        expect(ChineseDateTime.fromDateTime(other), native);
        expect(date.compareTo(other), 0);
        expect(date.difference(other), Duration.zero);
        expect(date.isAtSameMomentAs(other), isTrue);
        expect(date.isAfter(other), isFalse);
        expect(date.isBefore(other), isFalse);
      }
    }
  });

  test(
      'JSON rejects malformed Chinese dates and preserves fractions and leap identity',
      () {
    final record =
        CalendarDateRecord.fromDateTime(ChineseDateTime.utc(2025, 7)).toJson();
    for (final patch in <Map<String, Object?>>[
      {'version': 1.5},
      {'version': 2},
      {'kind': 'instant'},
      {'calendar': 'Chinese'},
      {'year': 2025.5},
      {'year': '2025'},
      {'year': 2100},
      {'year': null},
      {'month': 0},
      {'month': 14},
      {'month': 7.5},
      {'day': 0},
      {'day': 30},
      {'monthCode': 'M06L'},
      {'isLeapMonth': true},
      {'timeZone': 'UTC'},
    ]) {
      expect(() => CalendarDateRecord.fromJson({...record, ...patch}),
          throwsFormatException,
          reason: '$patch');
    }
    for (final key in record.keys) {
      expect(() => CalendarDateRecord.fromJson({...record}..remove(key)),
          throwsFormatException);
    }
    final value = ChineseDateTime.utc(2025, 7, 29, 23, 59, 59, 999, 123);
    final instant =
        CalendarInstant.fromDateTime(value, timeZone: 'Asia/Shanghai');
    final restored =
        CalendarInstant.fromJson(jsonDecode(jsonEncode(instant.toJson())));
    expect(restored.instant, value.toDateTime());
    expect(restored.timeZone, 'Asia/Shanghai');
    expect(ChineseDateTime.fromDateTime(restored.instant).monthCode, 'M06L');
    expect(CalendarId.values.map((id) => id.identifier),
        ['gregory', 'persian', 'islamic-umalqura', 'hebrew', 'chinese']);
  });

  test('VM storage rejects double-typed fields even when integer-valued', () {
    final record =
        CalendarDateRecord.fromDateTime(ChineseDateTime.utc(2025, 7)).toJson();
    for (final patch in [
      {'version': 1.0},
      {'year': 2025.0},
      {'month': 7.0},
      {'day': 1.0}
    ]) {
      expect(() => CalendarDateRecord.fromJson({...record, ...patch}),
          throwsFormatException);
    }
  }, testOn: 'vm');
}
