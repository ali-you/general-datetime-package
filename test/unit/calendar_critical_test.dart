import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/general_datetime.dart';

import '../support/calendar_test_case.dart';

void main() {
  for (final CalendarTestCase calendar in calendarTestCases) {
    group('${calendar.name} critical date-time contracts', () {
      test('strict validity agrees with every reference month boundary', () {
        for (int year = calendar.fixtureMinimumYear;
            year <= calendar.fixtureMaximumYear;
            year++) {
          for (int month = 1; month <= 12; month++) {
            final int length = calendar.referenceMonthLength(year, month);
            final String context = '$year-$month';
            expect(calendar.isValidDate(year, month, 1), isTrue,
                reason: context);
            expect(calendar.isValidDate(year, month, length), isTrue,
                reason: context);
            expect(calendar.isValidDate(year, month, 0), isFalse,
                reason: context);
            expect(calendar.isValidDate(year, month, length + 1), isFalse,
                reason: context);
          }
        }
      });

      test('seeded normalization matches the independent fixture and UTC clock',
          () {
        final Random random = Random(0xCA1E);
        for (int sample = 0; sample < 1000; sample++) {
          final int year = calendar.fixtureMinimumYear +
              8 +
              random.nextInt(calendar.fixtureMaximumYear -
                  calendar.fixtureMinimumYear -
                  15);
          final int month = random.nextInt(97) - 48;
          final int day = random.nextInt(1001) - 500;
          final int hour = random.nextInt(241) - 120;
          final int minute = random.nextInt(361) - 180;
          final int second = random.nextInt(361) - 180;
          final int millisecond = random.nextInt(4001) - 2000;
          final int microsecond = random.nextInt(4001) - 2000;
          // Only universal year/month normalization uses DateTime here;
          // Gregorian day lengths must not determine custom month lengths.
          final DateTime normalizedMonth = DateTime.utc(year, month);
          final DateTime expected = calendar
              .referenceGregorian(
                  normalizedMonth.year, normalizedMonth.month, 1)
              .add(Duration(
                days: day - 1,
                hours: hour,
                minutes: minute,
                seconds: second,
                milliseconds: millisecond,
                microseconds: microsecond,
              ));
          final DateTime actual = calendar.make(year, month, day,
              hour: hour,
              minute: minute,
              second: second,
              millisecond: millisecond,
              microsecond: microsecond);
          _expectNativeAndFields(
              calendar,
              actual,
              expected,
              'seed 0xCA1E sample $sample: $year/$month/$day '
              '$hour:$minute:$second.$millisecond/$microsecond');
        }
      });

      test('seeded native conversions preserve random local and UTC instants',
          () {
        final Random random = Random(0xDA7E);
        for (int sample = 0; sample < 500; sample++) {
          final int year = 1900 + random.nextInt(200);
          final int month = 1 + random.nextInt(12);
          final int day = 1 + random.nextInt(28);
          final int hour = random.nextInt(24);
          final int minute = random.nextInt(60);
          final int second = random.nextInt(60);
          final int millisecond = random.nextInt(1000);
          final int microsecond = random.nextInt(1000);
          for (final bool isUtc in <bool>[false, true]) {
            final DateTime expected = isUtc
                ? DateTime.utc(year, month, day, hour, minute, second,
                    millisecond, microsecond)
                : DateTime(year, month, day, hour, minute, second, millisecond,
                    microsecond);
            _expectNativeAndFields(calendar, calendar.fromDateTime(expected),
                expected, 'seed 0xDA7E sample $sample UTC=$isUtc');
          }
        }
      });

      test('seeded duration arithmetic is reversible at microsecond precision',
          () {
        final Random random = Random(0xADD);
        for (int sample = 0; sample < 300; sample++) {
          final DateTime native = DateTime.utc(
              1950 + random.nextInt(100),
              1 + random.nextInt(12),
              1 + random.nextInt(28),
              12,
              34,
              56,
              789,
              123);
          final DateTime value = calendar.fromDateTime(native);
          final Duration delta = Duration(
              days: random.nextInt(801) - 400,
              microseconds: random.nextInt(2000001) - 1000000);
          expect(nativeDate(value.add(delta)), native.add(delta),
              reason: 'seed 0xADD sample $sample');
          expect(nativeDate(value.subtract(delta)), native.subtract(delta),
              reason: 'seed 0xADD sample $sample');
          expect(value.add(delta).subtract(delta), value);
          expect(value.subtract(delta).add(delta), value);
          expect(value.add(delta).difference(value), delta);
        }
      });

      test('negative and sub-millisecond epoch values match native DateTime',
          () {
        for (final int micros in <int>[
          -1000001,
          -1000000,
          -999999,
          -1001,
          -1000,
          -999,
          -1,
          0,
          1,
          999,
          1000,
          1001,
          999999,
          1000000,
          1000001,
        ]) {
          for (final bool isUtc in <bool>[false, true]) {
            final DateTime expected =
                DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: isUtc);
            final DateTime actual = calendar.fromMicroseconds(micros, isUtc);
            _expectNativeAndFields(
                calendar, actual, expected, '$micros/$isUtc');
            expect(
                actual.millisecondsSinceEpoch, expected.millisecondsSinceEpoch);
            expect(
                nativeDate(calendar.fromMilliseconds(
                    expected.millisecondsSinceEpoch, isUtc)),
                DateTime.fromMillisecondsSinceEpoch(
                    expected.millisecondsSinceEpoch,
                    isUtc: isUtc));
          }
        }
      });

      test('epoch seconds cross 32-bit signed and unsigned boundaries', () {
        for (final int seconds in <int>[
          -2147483649,
          -2147483648,
          -1,
          0,
          1,
          2147483647,
          2147483648,
          4294967296,
        ]) {
          final DateTime expected = DateTime.fromMicrosecondsSinceEpoch(
              seconds * Duration.microsecondsPerSecond,
              isUtc: true);
          final DateTime actual = calendar.fromSeconds(seconds, true);
          _expectNativeAndFields(
              calendar, actual, expected, '$seconds seconds');
          expect(
              (actual as GeneralDateTimeInterface).secondsSinceEpoch, seconds);
        }
      });

      test('oversized epoch units cannot wrap into valid dates near 1970', () {
        for (final int value in <int>[
          0x7fffffffffffffff,
          -0x7fffffffffffffff,
          1 << 62,
          -(1 << 62),
        ]) {
          for (final bool isUtc in <bool>[true, false]) {
            expect(
                () => calendar.fromSeconds(value, isUtc), throwsArgumentError,
                reason: '$value seconds UTC=$isUtc');
            expect(() => calendar.fromMilliseconds(value, isUtc),
                throwsArgumentError,
                reason: '$value milliseconds UTC=$isUtc');
            expect(() => calendar.fromMicroseconds(value, isUtc),
                throwsArgumentError,
                reason: '$value microseconds UTC=$isUtc');
          }
        }
      });

      test('ISO fractions retain every leading zero and round-trip both modes',
          () {
        for (final int millisecond in <int>[0, 1, 9, 10, 99, 100, 999]) {
          for (final int microsecond in <int>[0, 1, 9, 10, 99, 100, 999]) {
            for (final bool isUtc in <bool>[false, true]) {
              final DateTime value = calendar.make(calendar.anchorYear, 1, 1,
                  millisecond: millisecond,
                  microsecond: microsecond,
                  isUtc: isUtc);
              final String fraction = millisecond.toString().padLeft(3, '0') +
                  (microsecond == 0
                      ? ''
                      : microsecond.toString().padLeft(3, '0'));
              expect(
                  value.toIso8601String(),
                  '${isoDate(calendar.anchorYear, 1, 1)}T00:00:00.$fraction'
                  '${isUtc ? 'Z' : ''}');
              expect(calendar.parse(value.toIso8601String()), value);
              expect(calendar.parse(value.toString()), value);
            }
          }
        }
      });

      test('fraction padding and truncation agree with the native ISO parser',
          () {
        final DateTime reference =
            calendar.referenceGregorian(calendar.anchorYear, 1, 1);
        for (final String fraction in <String>[
          '0',
          '1',
          '000001',
          '000010',
          '1234',
          '123456',
          '123456789',
          '9999999',
        ]) {
          for (final String separator in <String>['.', ',']) {
            final String suffix = 'T12:34:56$separator${fraction}z';
            final DateTime expected = DateTime.parse(
                '${isoDate(reference.year, reference.month, reference.day)}$suffix');
            expect(
                nativeDate(calendar
                    .parse('${isoDate(calendar.anchorYear, 1, 1)}$suffix')),
                expected,
                reason: suffix);
          }
        }
      });

      test('supported compact and shortened time forms match native parsing',
          () {
        final DateTime reference =
            calendar.referenceGregorian(calendar.anchorYear, 1, 1);
        for (final String suffix in <String>[
          'T12Z',
          'T1234z',
          'T12:34:56 Z',
          ' 12:34:56.1z',
          'T123456,123456Z',
          'T12:34:56+00',
        ]) {
          final DateTime expected = DateTime.parse(
              '${isoDate(reference.year, reference.month, reference.day)}$suffix');
          for (final String date in <String>[
            isoDate(calendar.anchorYear, 1, 1),
            '${calendar.anchorYear}0101',
            '+${calendar.anchorYear.toString().padLeft(6, '0')}-01-01',
          ]) {
            expect(nativeDate(calendar.parse('$date$suffix')), expected,
                reason: '$date$suffix');
          }
        }
      });

      test(
          'positive and negative offset extremes cross calendar dates correctly',
          () {
        final DateTime reference =
            calendar.referenceGregorian(calendar.anchorYear, 1, 1);
        for (final String suffix in <String>[
          'T00:00:00+23:59',
          'T23:59:59.999999-23:59',
          'T00:00:00+03',
          'T23:59:59-0330',
          'T00:00:00-00:00',
        ]) {
          final DateTime expected = DateTime.parse(
              '${isoDate(reference.year, reference.month, reference.day)}$suffix');
          _expectNativeAndFields(
              calendar,
              calendar.parse('${isoDate(calendar.anchorYear, 1, 1)}$suffix'),
              expected,
              suffix);
        }
      });

      test('malformed strings fail consistently without leaking RangeError',
          () {
        final String date = isoDate(calendar.anchorYear, 1, 1);
        for (final String input in <String>[
          '',
          'junk$date',
          '$date junk',
          '$date\u0000',
          '${date}T',
          '${date}T1Z',
          '${date}T12:3Z',
          '${date}T12:34:56.Z',
          '${date}T12:34:56ZZ',
          '${date}T12:34:56+00:00Z',
          '${date}T12:34:56+24:00',
          '${date}T12:34:56-24:00',
          '${date}T12:34:56+00:60',
          '${date}T12:34:56-00:60',
          '${date}T12:34:56+0:00',
          '${date}T12:34:56Z\njunk',
          '9999999999999999999999-01-01',
        ]) {
          expect(() => calendar.parse(input), throwsFormatException,
              reason: input);
          expect(calendar.tryParse(input), isNull, reason: input);
        }
      });

      test(
          'offset matrix preserves exact endpoints and rejects adjacent instants',
          () {
        final DateTime minimum = calendar.minimumGregorian;
        final DateTime maximum = calendar.maximumGregorian
            .add(const Duration(days: 1))
            .subtract(const Duration(microseconds: 1));
        for (final int minutes in <int>[
          -1439,
          -840,
          -330,
          -1,
          0,
          1,
          210,
          840,
          1439
        ]) {
          for (final bool atMinimum in <bool>[true, false]) {
            final DateTime endpoint = atMinimum ? minimum : maximum;
            final String input =
                _boundaryInput(calendar, endpoint, minutes, atMinimum);
            expect(nativeDate(calendar.parse(input)), endpoint, reason: input);
            expect(calendar.tryParse(input), calendar.fromDateTime(endpoint));
            final DateTime outside =
                endpoint.add(Duration(microseconds: atMinimum ? -1 : 1));
            final String invalid =
                _boundaryInput(calendar, outside, minutes, atMinimum);
            expect(() => calendar.parse(invalid), throwsFormatException,
                reason: invalid);
            expect(calendar.tryParse(invalid), isNull, reason: invalid);
          }
        }
      });

      test('epoch boundary acceptance depends on the resulting wall date', () {
        final int minimum = calendar.minimumGregorian.microsecondsSinceEpoch;
        final int maximum = calendar.maximumGregorian
                .add(const Duration(days: 1))
                .microsecondsSinceEpoch -
            1;
        for (final int micros in <int>[
          minimum - 1,
          minimum,
          minimum + 1,
          maximum - 1,
          maximum,
          maximum + 1,
        ]) {
          for (final bool isUtc in <bool>[true, false]) {
            final DateTime expected =
                DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: isUtc);
            if (calendar.supportsWallDate(expected)) {
              expect(nativeDate(calendar.fromMicroseconds(micros, isUtc)),
                  expected);
            } else {
              expect(() => calendar.fromMicroseconds(micros, isUtc),
                  throwsRangeError);
            }
          }
        }
      });

      test('local constructors resolve DST gaps and folds like native DateTime',
          () {
        _verifyCiTimeZone();
        // CI runs these same wall times in UTC, Asia/Tehran, and New York.
        for (final (int, int, int, int, int) wall
            in <(int, int, int, int, int)>[
          (2019, 3, 22, 0, 30),
          (2019, 9, 21, 23, 30),
          (2021, 3, 14, 2, 30),
          (2021, 11, 7, 1, 30),
        ]) {
          final (int y, int m, int d, int h, int min) = wall;
          final (int cy, int cm, int cd) =
              calendar.referenceFields(DateTime.utc(y, m, d));
          final DateTime expected = DateTime(y, m, d, h, min, 56, 789, 123);
          final DateTime actual = calendar.make(cy, cm, cd,
              hour: h,
              minute: min,
              second: 56,
              millisecond: 789,
              microsecond: 123,
              isUtc: false);
          _expectNativeAndFields(calendar, actual, expected, '$wall');
          expect(nativeDate(actual.toUtc()), expected.toUtc());
          expect(nativeDate(actual.toUtc().toLocal()), expected);
          expect(actual.timeZoneName, expected.timeZoneName);
          expect(actual.timeZoneOffset, expected.timeZoneOffset);
        }
      });

      test(
          'duration addition and calendar-day navigation follow their clock semantics',
          () {
        for (final DateTime start in <DateTime>[
          DateTime(2019, 3, 21),
          DateTime(2019, 9, 21),
          DateTime(2021, 3, 14),
          DateTime(2021, 11, 7),
        ]) {
          final DateTime value = calendar.fromDateTime(start);
          expect(nativeDate(value.add(const Duration(days: 1))),
              start.add(const Duration(days: 1)));
          final DateTime nextWallDay =
              calendar.delegate.addDaysToDate(value, 1);
          expect(nativeDate(nextWallDay),
              DateTime(start.year, start.month, start.day + 1));
          expect(nextWallDay.runtimeType, calendar.type);
        }
      });

      test(
          'zone conversion rejects only wall dates outside the supported range',
          () {
        for (final DateTime local in <DateTime>[
          DateTime(calendar.minimumGregorian.year,
              calendar.minimumGregorian.month, calendar.minimumGregorian.day),
          DateTime(
              calendar.maximumGregorian.year,
              calendar.maximumGregorian.month,
              calendar.maximumGregorian.day,
              23,
              59,
              59,
              999,
              999),
        ]) {
          final DateTime value = calendar.fromDateTime(local);
          if (calendar.supportsWallDate(local.toUtc())) {
            expect(nativeDate(value.toUtc()), local.toUtc());
          } else {
            expect(value.toUtc, throwsRangeError);
          }
        }
        for (final DateTime utc in <DateTime>[
          calendar.minimumGregorian,
          calendar.maximumGregorian.add(const Duration(hours: 23, minutes: 59)),
        ]) {
          final DateTime value = calendar.fromDateTime(utc);
          if (calendar.supportsWallDate(utc.toLocal())) {
            expect(nativeDate(value.toLocal()), utc.toLocal());
          } else {
            expect(value.toLocal, throwsRangeError);
          }
        }
      });
    });
  }

  group('Cross-calendar interoperability', () {
    test(
        'all comparison directions agree across native and both calendar types',
        () {
      final DateTime native = DateTime.utc(2024, 3, 20, 12, 34, 56, 789, 123);
      final List<DateTime> values = <DateTime>[];
      for (final int delta in <int>[-1, 0, 1]) {
        final DateTime instant = native.add(Duration(microseconds: delta));
        values.addAll(<DateTime>[
          instant,
          instant.toLocal(),
          PersianDateTime.fromDateTime(instant),
          HijriDateTime.fromDateTime(instant),
        ]);
      }
      for (final DateTime first in values) {
        for (final DateTime second in values) {
          final DateTime firstNative = DateTime.fromMicrosecondsSinceEpoch(
              first.microsecondsSinceEpoch,
              isUtc: first.isUtc);
          final DateTime secondNative = DateTime.fromMicrosecondsSinceEpoch(
              second.microsecondsSinceEpoch,
              isUtc: second.isUtc);
          expect(first.compareTo(second), firstNative.compareTo(secondNative));
          expect(first.isBefore(second), firstNative.isBefore(secondNative));
          expect(first.isAfter(second), firstNative.isAfter(secondNative));
          expect(first.isAtSameMomentAs(second),
              firstNative.isAtSameMomentAs(secondNative));
          expect(
              first.difference(second), firstNative.difference(secondNative));
          expect(first == second, firstNative == secondNative);
        }
      }
    });
    test(
        'fromDateTime accepts the other calendar without reinterpreting its fields',
        () {
      for (final bool isUtc in <bool>[true, false]) {
        final DateTime native = isUtc
            ? DateTime.utc(2024, 3, 20, 23, 59, 59, 999, 999)
            : DateTime(2024, 3, 20, 23, 59, 59, 999, 999);
        final PersianDateTime persian = PersianDateTime.fromDateTime(native);
        final HijriDateTime hijri = HijriDateTime.fromDateTime(native);
        expect(PersianDateTime.fromDateTime(hijri), persian);
        expect(HijriDateTime.fromDateTime(persian), hijri);
        expect(nativeDate(PersianDateTime.fromDateTime(hijri)), native);
        expect(nativeDate(HijriDateTime.fromDateTime(persian)), native);
      }
    });

    test(
        'mixed calendar values sort chronologically and act as interchangeable keys',
        () {
      final DateTime native = DateTime.utc(2024, 3, 20, 12, 34, 56, 789, 123);
      final List<DateTime> values = <DateTime>[
        HijriDateTime.fromDateTime(native.add(const Duration(microseconds: 1))),
        PersianDateTime.fromDateTime(native),
        native.subtract(const Duration(microseconds: 1)),
        HijriDateTime.fromDateTime(native),
        native,
      ]..sort();
      expect(values.map((DateTime date) => date.microsecondsSinceEpoch), <int>[
        native.microsecondsSinceEpoch - 1,
        native.microsecondsSinceEpoch,
        native.microsecondsSinceEpoch,
        native.microsecondsSinceEpoch,
        native.microsecondsSinceEpoch + 1
      ]);
      final Map<DateTime, String> lookup = <DateTime, String>{
        PersianDateTime.fromDateTime(native): 'same instant',
      };
      expect(lookup[HijriDateTime.fromDateTime(native)], 'same instant');
      expect(lookup[native], 'same instant');
      lookup[HijriDateTime.fromDateTime(native)] = 'replaced';
      expect(lookup, hasLength(1));
      expect(lookup[native], 'replaced');
      expect(lookup[values.first], isNull);
      expect(lookup[values.last], isNull);
    });
  });
}

void _verifyCiTimeZone() {
  const String zone = String.fromEnvironment('CALENDAR_TEST_TZ');
  if (zone == 'UTC') {
    expect(DateTime(2021, 3, 14, 12).timeZoneOffset, Duration.zero);
  } else if (zone == 'America/New_York') {
    expect(DateTime(2021, 3, 14, 12).difference(DateTime(2021, 3, 13, 12)),
        const Duration(hours: 23));
    expect(DateTime(2021, 11, 7, 12).difference(DateTime(2021, 11, 6, 12)),
        const Duration(hours: 25));
  } else if (zone == 'Asia/Tehran') {
    expect(DateTime(2019, 3, 22, 12).difference(DateTime(2019, 3, 21, 12)),
        const Duration(hours: 23));
    expect(DateTime(2019, 9, 22, 12).difference(DateTime(2019, 9, 21, 12)),
        const Duration(hours: 25));
  } else {
    expect(zone, isEmpty, reason: 'Unknown CI time-zone expectation: $zone');
  }
}

void _expectNativeAndFields(CalendarTestCase calendar, DateTime actual,
    DateTime expected, String reason) {
  expect(actual.runtimeType, calendar.type, reason: reason);
  expect(nativeDate(actual), expected, reason: reason);
  expect((
    actual.year,
    actual.month,
    actual.day
  ), calendar.referenceFields(expected), reason: reason);
  expect((
    actual.hour,
    actual.minute,
    actual.second,
    actual.millisecond,
    actual.microsecond
  ), (
    expected.hour,
    expected.minute,
    expected.second,
    expected.millisecond,
    expected.microsecond
  ), reason: reason);
  expect(actual.isUtc, expected.isUtc, reason: reason);
  expect(actual.weekday, expected.weekday, reason: reason);
}

String _boundaryInput(CalendarTestCase calendar, DateTime instant,
    int offsetMinutes, bool atMinimum) {
  final DateTime wall = instant.add(Duration(minutes: offsetMinutes));
  final DateTime anchor =
      atMinimum ? calendar.minimumGregorian : calendar.maximumGregorian;
  final int dayDelta =
      DateTime.utc(wall.year, wall.month, wall.day).difference(anchor).inDays;
  final String date = atMinimum
      ? isoDate(calendar.minimumYear, 1, 1 + dayDelta)
      : isoDate(calendar.maximumYear, 12, calendar.lastDay + dayDelta);
  final int magnitude = offsetMinutes.abs();
  final String offset = '${offsetMinutes < 0 ? '-' : '+'}'
      '${(magnitude ~/ 60).toString().padLeft(2, '0')}:'
      '${(magnitude % 60).toString().padLeft(2, '0')}';
  final String clock =
      wall.toIso8601String().split('T').last.replaceAll('Z', '');
  return '${date}T$clock$offset';
}
