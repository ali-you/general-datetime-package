import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/general_datetime.dart';

import '../support/calendar_test_case.dart';

void main() {
  for (final calendar in calendarTestCases) {
    final id = calendar.type == PersianDateTime
        ? CalendarId.persian
        : CalendarId.islamicUmalqura;
    group('${calendar.name} serialization', () {
      test('calendar ISO parsed as Gregorian changes the instant', () {
        final date = calendar.make(calendar.anchorYear, 1, 1);
        final expected = calendar.referenceGregorian(calendar.anchorYear, 1, 1);
        expect(
            DateTime.parse(date.toIso8601String()).isAtSameMomentAs(expected),
            isFalse);
        expect(
            calendar.parse(date.toIso8601String()).isAtSameMomentAs(expected),
            isTrue);
        expect(date.toUtc().runtimeType, calendar.type);
        expect(date.toUtc().toIso8601String(), date.toIso8601String());
      });

      test('JSON uses independent Gregorian timestamp with all microseconds',
          () {
        final DateTime date = calendar.make(calendar.anchorYear, 1, 1,
            hour: 12,
            minute: 34,
            second: 56,
            millisecond: 789,
            microsecond: 123);
        final expected = calendar
            .referenceGregorian(calendar.anchorYear, 1, 1)
            .add(const Duration(
                hours: 12,
                minutes: 34,
                seconds: 56,
                milliseconds: 789,
                microseconds: 123));
        final record =
            CalendarInstant.fromDateTime(date, timeZone: 'Asia/Tehran');
        expect(record.toJson(), {
          'version': 1,
          'kind': 'instant',
          'timestamp': expected.toIso8601String(),
          'calendar': id.identifier,
          'timeZone': 'Asia/Tehran',
        });
        final restored =
            CalendarInstant.fromJson(jsonDecode(jsonEncode(record)));
        expect(restored.instant.runtimeType, DateTime);
        expect(restored.instant.isUtc, isTrue);
        expect(restored.instant.microsecondsSinceEpoch,
            expected.microsecondsSinceEpoch);
        expect(restored.calendar, id);
        expect(restored.timeZone, 'Asia/Tehran');
        expect(calendar.fromDateTime(restored.instant), date);
      });

      test('local and UTC representations serialize the same instant', () {
        final utc = calendar.make(calendar.anchorYear, 1, 1,
            hour: 12, millisecond: 789, microsecond: 123);
        final local = utc.toLocal();
        expect(CalendarInstant.fromDateTime(local).toJson(),
            CalendarInstant.fromDateTime(utc).toJson());
        expect(CalendarInstant.fromDateTime(local).timeZone, isNull);
      });

      test('calendar date JSON retains wall fields and has no clock or zone',
          () {
        final date = calendar.make(calendar.anchorYear, 1, 1,
            hour: 23, minute: 59, microsecond: 123, isUtc: false);
        final record = CalendarDateRecord.fromDateTime(date);
        expect(record.toJson(), {
          'version': 1,
          'kind': 'calendar-date',
          'calendar': id.identifier,
          'year': calendar.anchorYear,
          'month': 1,
          'day': 1,
        });
        final restored =
            CalendarDateRecord.fromJson(jsonDecode(jsonEncode(record)));
        expect(restored.toJson(), record.toJson());
      });

      test('both finite calendar-date endpoints round trip', () {
        for (final date in [
          calendar.make(calendar.minimumYear, 1, 1),
          calendar.make(calendar.maximumYear, 12, calendar.lastDay),
        ]) {
          final record = CalendarDateRecord.fromDateTime(date);
          expect(CalendarDateRecord.fromJson(record.toJson()).toJson(),
              record.toJson());
          expect(
              CalendarInstant.fromJson(
                      CalendarInstant.fromDateTime(date).toJson())
                  .instant
                  .microsecondsSinceEpoch,
              date.microsecondsSinceEpoch);
        }
      });

      test('invalid month lengths and out-of-range years cannot normalize', () {
        final year = calendar.anchorYear;
        for (final (y, m, d) in [
          (year, 0, 1),
          (year, 13, 1),
          (year, 1, 0),
          (year, 1, calendar.referenceMonthLength(year, 1) + 1),
          (calendar.minimumYear - 1, 1, 1),
          (calendar.maximumYear + 1, 1, 1),
          (9223372036854775807, 1, 1),
          (year, 9223372036854775807, 1),
          (year, 1, 9223372036854775807),
        ]) {
          expect(
              () => CalendarDateRecord(calendar: id, year: y, month: m, day: d),
              throwsArgumentError);
          expect(
              () => CalendarDateRecord.fromJson({
                    'version': 1,
                    'kind': 'calendar-date',
                    'calendar': id.identifier,
                    'year': y,
                    'month': m,
                    'day': d,
                  }),
              throwsFormatException);
        }
      });
    });
  }

  group('instant schema', () {
    test('native Gregorian values round trip before and after the epoch', () {
      for (final date in [
        DateTime.utc(0),
        DateTime.utc(1969, 12, 31, 23, 59, 59, 999, 999),
        DateTime.utc(1970),
        DateTime.utc(9999, 12, 31, 23, 59, 59, 999, 999),
      ]) {
        final record = CalendarInstant.fromDateTime(date);
        expect(record.calendar, CalendarId.gregory);
        expect(record.toJson().containsKey('timeZone'), isFalse);
        expect(CalendarInstant.fromJson(jsonDecode(jsonEncode(record))).instant,
            date);
      }
    });

    test('fractional seconds are retained exactly through six digits', () {
      for (final (suffix, micros) in [
        ('Z', 0),
        ('.1Z', 100000),
        ('.12Z', 120000),
        ('.123Z', 123000),
        ('.1234Z', 123400),
        ('.12345Z', 123450),
        ('.123456Z', 123456),
      ]) {
        final record = CalendarInstant.fromJson({
          ..._instantJson(),
          'timestamp': '2024-03-20T12:34:56$suffix',
        });
        expect(record.instant.millisecond * 1000 + record.instant.microsecond,
            micros);
        expect(
            CalendarInstant.fromJson(record.toJson()).instant, record.instant);
      }
    });

    test('malformed and normalized timestamps are rejected', () {
      for (final timestamp in <Object?>[
        null,
        1710936000000,
        '',
        '2024-03-20',
        '2024-03-20T12:34:56',
        '2024-03-20T12:34:56+03:30',
        '2024-03-20T12:34:56Z[u-ca=persian]',
        '20240320T123456Z',
        '2024-03-20t12:34:56z',
        '2024-00-20T12:34:56Z',
        '2024-13-20T12:34:56Z',
        '2024-03-00T12:34:56Z',
        '2024-03-32T12:34:56Z',
        '2023-02-29T12:34:56Z',
        '2024-02-30T12:34:56Z',
        '2024-03-20T24:00:00Z',
        '2024-03-20T12:60:00Z',
        '2024-03-20T12:34:60Z',
        '2024-03-20T12:34:56.Z',
        '2024-03-20T12:34:56.1234567Z',
        '+010000-03-20T12:34:56Z',
        '2024-03-20T12:34:56Z\n',
        ' 2024-03-20T12:34:56Z',
      ]) {
        expect(
            () => CalendarInstant.fromJson({
                  ..._instantJson(),
                  'timestamp': timestamp,
                }),
            throwsFormatException,
            reason: '$timestamp');
      }
    });

    test('Gregorian timestamp years outside schema cannot be encoded', () {
      for (final date in [DateTime.utc(-1), DateTime.utc(10000)]) {
        expect(() => CalendarInstant.fromDateTime(date), throwsArgumentError);
      }
    });

    test('calendar metadata does not reinterpret or constrain the instant', () {
      final record = CalendarInstant.fromJson({
        ..._instantJson(),
        'timestamp': '0000-01-01T00:00:00Z',
        'calendar': 'islamic-umalqura',
        'timeZone': 'Asia/Tehran',
      });
      expect(record.instant, DateTime.utc(0));
      expect(record.calendar, CalendarId.islamicUmalqura);
      expect(
          () => HijriDateTime.fromDateTime(record.instant), throwsRangeError);
    });

    test('timeZone is optional opaque metadata with strict type validation',
        () {
      for (final zone in <Object?>[
        null,
        123,
        '',
        ' ',
        ' Asia/Tehran',
        'UTC '
      ]) {
        expect(
            () => CalendarInstant.fromJson({
                  ..._instantJson(),
                  'timeZone': zone,
                }),
            throwsFormatException);
      }
      for (final zone in ['', ' ', ' UTC']) {
        expect(
            () => CalendarInstant.fromDateTime(DateTime.utc(2024),
                timeZone: zone),
            throwsArgumentError);
      }
      final record = CalendarInstant.fromDateTime(DateTime.utc(2024),
          timeZone: 'Application/Zone');
      expect(CalendarInstant.fromJson(record.toJson()).timeZone,
          'Application/Zone');
    });
  });

  group('calendar-date schema', () {
    test('Gregorian leap dates and native endpoints round trip', () {
      for (final date in [
        DateTime.utc(2000, 2, 29),
        DateTime.utc(2024, 2, 29),
        DateTime.utc(0),
        DateTime.utc(-271821, 4, 20),
        DateTime.utc(275760, 9, 13),
      ]) {
        final record = CalendarDateRecord.fromDateTime(date);
        expect(record.calendar, CalendarId.gregory);
        expect(
            CalendarDateRecord.fromJson(jsonDecode(jsonEncode(record)))
                .toJson(),
            record.toJson());
      }
    });

    test('invalid Gregorian dates and extreme fields are rejected', () {
      for (final (y, m, d) in [
        (1900, 2, 29),
        (2024, 4, 31),
        (2024, 0, 1),
        (2024, 1, 0),
        (-271821, 4, 19),
        (275760, 9, 14),
        (9223372036854775807, 1, 1),
        (2024, 9223372036854775807, 1),
        (2024, 1, 9223372036854775807),
      ]) {
        expect(
            () => CalendarDateRecord(
                calendar: CalendarId.gregory, year: y, month: m, day: d),
            throwsArgumentError);
        expect(
            () => CalendarDateRecord.fromJson({
                  ..._dateJson(),
                  'calendar': 'gregory',
                  'year': y,
                  'month': m,
                  'day': d,
                }),
            throwsFormatException);
      }
    });

    test('negative and zero Persian years round trip as calendar fields', () {
      for (final year in [-61, -1, 0]) {
        final record = CalendarDateRecord(
            calendar: CalendarId.persian, year: year, month: 1, day: 1);
        expect(CalendarDateRecord.fromJson(jsonDecode(jsonEncode(record))).year,
            year);
      }
    });

    test('string, fractional, null, and boolean date fields are rejected', () {
      for (final field in ['year', 'month', 'day']) {
        for (final invalid in <Object?>['1', 1.0, null, true, []]) {
          expect(
              () => CalendarDateRecord.fromJson({
                    ..._dateJson(),
                    field: invalid,
                  }),
              throwsFormatException);
        }
      }
    });
  });

  for (final (kind, valid, decode)
      in <(String, Map<String, Object>, Object Function(Object?))>[
    ('instant', _instantJson(), CalendarInstant.fromJson),
    ('calendar-date', _dateJson(), CalendarDateRecord.fromJson),
  ]) {
    group('$kind record validation', () {
      test('nonobjects and nonstring keys are rejected', () {
        for (final json in <Object?>[
          null,
          [],
          'date',
          1,
          {1: 'value'}
        ]) {
          expect(() => decode(json), throwsFormatException);
        }
      });
      test('every required field must be present', () {
        for (final key in valid.keys) {
          final json = {...valid}..remove(key);
          expect(() => decode(json), throwsFormatException, reason: key);
        }
      });
      test('unknown versions, kinds, calendars, and fields are rejected', () {
        for (final version in <Object?>[0, 2, '1', 1.0, null]) {
          expect(() => decode({...valid, 'version': version}),
              throwsFormatException);
        }
        for (final value in <Object?>['unknown', null, 1]) {
          expect(
              () => decode({...valid, 'kind': value}), throwsFormatException);
          expect(() => decode({...valid, 'calendar': value}),
              throwsFormatException);
        }
        for (final calendar in ['hijri', 'islamic', 'gregorian', 'Persian']) {
          expect(() => decode({...valid, 'calendar': calendar}),
              throwsFormatException);
        }
        expect(() => decode({...valid, 'extra': true}), throwsFormatException);
      });
    });
  }

  test('instant and date records cannot be confused', () {
    expect(() => CalendarInstant.fromJson(_dateJson()), throwsFormatException);
    expect(() => CalendarDateRecord.fromJson(_instantJson()),
        throwsFormatException);
    expect(
        () => CalendarDateRecord.fromJson({..._dateJson(), 'timeZone': 'UTC'}),
        throwsFormatException);
  });

  test('JSON map mutation cannot change immutable records', () {
    final source = _instantJson();
    final instant = CalendarInstant.fromJson(source);
    source['timestamp'] = 'wrong';
    instant.toJson()['calendar'] = 'wrong';
    expect(instant.toJson(), _instantJson());
    final date = CalendarDateRecord.fromJson(_dateJson());
    date.toJson()['year'] = 9999;
    expect(date.year, 1403);
  });

  test('unregistered calendar implementations fail explicitly', () {
    final date = _UnsupportedCalendar();
    expect(() => CalendarInstant.fromDateTime(date), throwsUnsupportedError);
    expect(() => CalendarDateRecord.fromDateTime(date), throwsUnsupportedError);
  });
}

Map<String, Object> _instantJson() => {
      'version': 1,
      'kind': 'instant',
      'timestamp': '2024-03-20T12:34:56.789123Z',
      'calendar': 'persian',
    };

Map<String, Object> _dateJson() => {
      'version': 1,
      'kind': 'calendar-date',
      'calendar': 'persian',
      'year': 1403,
      'month': 1,
      'day': 1,
    };

class _UnsupportedCalendar extends DateTime
    implements GeneralDateTimeInterface<DateTime> {
  _UnsupportedCalendar() : super.utc(2024, 3, 20);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
