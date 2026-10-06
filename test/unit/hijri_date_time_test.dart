import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/general_datetime.dart';
// Used only by the archived third-party comparisons below.
// import 'package:hijri/hijri_calendar.dart';

import '../fixtures/umm_al_qura_openjdk21_fixture.dart';

void main() {
  group('Umm al-Qura reference data', () {
    test('publishes the exact OpenJDK Hijrah-umalqura bounds', () {
      expect(HijriDateTime.minimumYear, 1300);
      expect(HijriDateTime.maximumYear, 1600);
      expect(HijriDateTime.minimumOfficialYear, HijriDateTime.minimumYear);
      expect(HijriDateTime.maximumOfficialYear, HijriDateTime.maximumYear);
      expect(
        UmmAlQuraOpenJdk21Fixture.encodedYearCount,
        HijriDateTime.maximumYear - HijriDateTime.minimumYear + 1,
      );
      expect(
        HijriDateTime.minimumGregorianDate,
        UmmAlQuraOpenJdk21Fixture.firstGregorianUtc,
      );
      expect(
        HijriDateTime.maximumGregorianDate,
        UmmAlQuraOpenJdk21Fixture.lastGregorianUtc,
      );
      expect(
        UmmAlQuraOpenJdk21Fixture.firstGregorianUtc.add(Duration(
          days: UmmAlQuraOpenJdk21Fixture.totalSupportedDays - 1,
        )),
        UmmAlQuraOpenJdk21Fixture.lastGregorianUtc,
      );
      expect(HijriDateTime.utc(1445).name, 'Hijri');
    });

    test('matches independent reference anchors in both directions', () {
      for (final _ReferenceAnchor anchor in _referenceAnchors) {
        final DateTime expected = DateTime.utc(
          anchor.gregorianYear,
          anchor.gregorianMonth,
          anchor.gregorianDay,
          12,
          34,
          56,
          789,
          123,
        );
        final HijriDateTime hijri = HijriDateTime.utc(
          anchor.hijriYear,
          anchor.hijriMonth,
          anchor.hijriDay,
          12,
          34,
          56,
          789,
          123,
        );

        expect(hijri.toDateTime(), expected, reason: anchor.toString());
        _expectHijriFields(
          HijriDateTime.fromDateTime(expected),
          anchor.hijriYear,
          anchor.hijriMonth,
          anchor.hijriDay,
          hour: 12,
          minute: 34,
          second: 56,
          millisecond: 789,
          microsecond: 123,
          isUtc: true,
          reason: anchor.toString(),
        );
      }
    });

    test('matches every official month length and year length', () {
      for (int year = HijriDateTime.minimumYear;
          year <= HijriDateTime.maximumYear;
          year++) {
        final int expectedYearLength =
            UmmAlQuraOpenJdk21Fixture.yearLength(year);
        final HijriDateTime firstDay = HijriDateTime.utc(year);
        expect(firstDay.hasOfficialCalendarData, isTrue, reason: 'year $year');

        expect(
          firstDay.yearLength,
          expectedYearLength,
          reason: 'year $year',
        );
        expect(
          firstDay.isLeapYear,
          expectedYearLength == 355,
          reason: 'year $year',
        );

        int runningDayOfYear = 1;
        for (int month = 1; month <= HijriDateTime.monthsPerYear; month++) {
          final int expectedMonthLength =
              UmmAlQuraOpenJdk21Fixture.monthLength(year, month);
          final HijriDateTime firstOfMonth = HijriDateTime.utc(year, month);
          final HijriDateTime lastOfMonth =
              HijriDateTime.utc(year, month, expectedMonthLength);

          expect(
            HijriDateTime.daysInMonth(year, month),
            expectedMonthLength,
            reason: '$year-$month static length',
          );
          expect(
            firstOfMonth.monthLength,
            expectedMonthLength,
            reason: '$year-$month instance length',
          );
          expect(
            firstOfMonth.dayOfYear,
            runningDayOfYear,
            reason: '$year-$month first day',
          );
          expect(
            lastOfMonth.dayOfYear,
            runningDayOfYear + expectedMonthLength - 1,
            reason: '$year-$month last day',
          );
          runningDayOfYear += expectedMonthLength;
        }
        expect(runningDayOfYear - 1, expectedYearLength, reason: 'year $year');
      }
    });

    test('converts and round-trips every supported calendar day', () {
      DateTime gregorianDay = UmmAlQuraOpenJdk21Fixture.firstGregorianUtc;
      int visitedDays = 0;

      for (int year = HijriDateTime.minimumYear;
          year <= HijriDateTime.maximumYear;
          year++) {
        final bool expectedLeapYear =
            UmmAlQuraOpenJdk21Fixture.yearLength(year) == 355;
        int expectedDayOfYear = 1;

        for (int month = 1; month <= HijriDateTime.monthsPerYear; month++) {
          final int monthLength =
              UmmAlQuraOpenJdk21Fixture.monthLength(year, month);
          for (int day = 1; day <= monthLength; day++) {
            final String context =
                'AH $year-${_twoDigits(month)}-${_twoDigits(day)}';
            final DateTime expectedGregorian = DateTime.utc(
              gregorianDay.year,
              gregorianDay.month,
              gregorianDay.day,
              17,
              18,
              19,
              321,
              654,
            );
            final HijriDateTime hijri = HijriDateTime.utc(
              year,
              month,
              day,
              17,
              18,
              19,
              321,
              654,
            );

            _require(
              hijri.toDateTime() == expectedGregorian,
              '$context converted to ${hijri.toDateTime()}, expected '
              '$expectedGregorian',
            );
            _require(hijri.isUtc, '$context lost its UTC flag');
            _require(
              hijri.monthLength == monthLength,
              '$context reported month length ${hijri.monthLength}, expected '
              '$monthLength',
            );
            _require(
              hijri.dayOfYear == expectedDayOfYear,
              '$context reported dayOfYear ${hijri.dayOfYear}, expected '
              '$expectedDayOfYear',
            );
            _require(
              hijri.isLeapYear == expectedLeapYear,
              '$context reported the wrong leap-year status',
            );
            _require(
              hijri.weekday == expectedGregorian.weekday,
              '$context reported weekday ${hijri.weekday}, expected '
              '${expectedGregorian.weekday}',
            );
            _require(
              hijri.julianDay == _gregorianJulianDayNumber(expectedGregorian),
              '$context reported Julian day ${hijri.julianDay}, expected '
              '${_gregorianJulianDayNumber(expectedGregorian)}',
            );

            final HijriDateTime roundTrip =
                HijriDateTime.fromDateTime(expectedGregorian);
            _require(
              _hasFields(
                roundTrip,
                year,
                month,
                day,
                17,
                18,
                19,
                321,
                654,
                isUtc: true,
              ),
              '$expectedGregorian round-tripped as $roundTrip, expected '
              '$context',
            );
            _require(
              roundTrip.toDateTime() == expectedGregorian,
              '$context did not preserve its exact instant',
            );

            gregorianDay = gregorianDay.add(const Duration(days: 1));
            expectedDayOfYear++;
            visitedDays++;
          }
        }
      }

      expect(visitedDays, UmmAlQuraOpenJdk21Fixture.totalSupportedDays);
      expect(
        gregorianDay,
        UmmAlQuraOpenJdk21Fixture.lastGregorianUtc.add(const Duration(days: 1)),
      );
    });
  });

  group('Validity and supported boundaries', () {
    test('reports strict Hijri and Gregorian validity', () {
      final int finalDay = UmmAlQuraOpenJdk21Fixture.monthLength(1600, 12);

      expect(HijriDateTime.isValidDate(1300, 1, 1), isTrue);
      expect(HijriDateTime.isValidDate(1600, 12, finalDay), isTrue);
      expect(HijriDateTime.isValidDate(1299, 12, 29), isFalse);
      expect(HijriDateTime.isValidDate(1601, 1, 1), isFalse);
      expect(HijriDateTime.isValidDate(1445, 0, 1), isFalse);
      expect(HijriDateTime.isValidDate(1445, 13, 1), isFalse);
      expect(HijriDateTime.isValidDate(1445, 1, 0), isFalse);
      expect(
        HijriDateTime.isValidDate(
          1445,
          1,
          UmmAlQuraOpenJdk21Fixture.monthLength(1445, 1) + 1,
        ),
        isFalse,
      );

      expect(
        HijriDateTime.isSupportedDateTime(DateTime.utc(1882, 11, 12)),
        isTrue,
      );
      expect(
        HijriDateTime.isSupportedDateTime(
          DateTime.utc(2174, 11, 25, 23, 59, 59, 999, 999),
        ),
        isTrue,
      );
      expect(
        HijriDateTime.isSupportedDateTime(DateTime.utc(1882, 11, 11)),
        isFalse,
      );
      expect(
        HijriDateTime.isSupportedDateTime(DateTime.utc(2174, 11, 26)),
        isFalse,
      );
      expect(() => HijriDateTime.daysInMonth(1299, 1), throwsRangeError);
      expect(() => HijriDateTime.daysInMonth(1601, 1), throwsRangeError);
      expect(() => HijriDateTime.daysInMonth(1445, 0), throwsRangeError);
      expect(() => HijriDateTime.daysInMonth(1445, 13), throwsRangeError);
    });

    test('accepts both exact endpoints', () {
      _expectHijriFields(HijriDateTime.utc(1300), 1300, 1, 1, isUtc: true);
      expect(
        HijriDateTime.utc(1300).toDateTime(),
        DateTime.utc(1882, 11, 12),
      );

      final int finalDay = UmmAlQuraOpenJdk21Fixture.monthLength(1600, 12);
      final HijriDateTime maximum = HijriDateTime.utc(
        1600,
        12,
        finalDay,
        23,
        59,
        59,
        999,
        999,
      );
      expect(
        maximum.toDateTime(),
        DateTime.utc(2174, 11, 25, 23, 59, 59, 999, 999),
      );
    });

    test('normalizes into the range before checking final validity', () {
      _expectHijriFields(HijriDateTime.utc(1299, 13, 1), 1300, 1, 1,
          isUtc: true);
      _expectHijriFields(HijriDateTime.utc(1601, 0, 1), 1600, 12, 1,
          isUtc: true);
      _expectHijriFields(
        HijriDateTime.utc(1600, 13, 0),
        1600,
        12,
        UmmAlQuraOpenJdk21Fixture.monthLength(1600, 12),
        isUtc: true,
      );
    });

    test('constructors reject final dates outside the table', () {
      final int finalDay = UmmAlQuraOpenJdk21Fixture.monthLength(1600, 12);

      expect(() => HijriDateTime(1299, 12, 29), throwsRangeError);
      expect(() => HijriDateTime.utc(1299, 12, 29), throwsRangeError);
      expect(() => HijriDateTime(1601, 1, 1), throwsRangeError);
      expect(() => HijriDateTime.utc(1601, 1, 1), throwsRangeError);
      expect(() => HijriDateTime(1300, 1, 0), throwsRangeError);
      expect(
        () => HijriDateTime.utc(1600, 12, finalDay + 1),
        throwsRangeError,
      );
    });

    test('Gregorian and epoch factories reject unsupported days', () {
      final DateTime before = DateTime.utc(1882, 11, 11);
      final DateTime after = DateTime.utc(2174, 11, 26);

      expect(() => HijriDateTime.fromDateTime(before), throwsRangeError);
      expect(() => HijriDateTime.fromDateTime(after), throwsRangeError);
      expect(
        () => HijriDateTime.fromSecondsSinceEpoch(
          before.millisecondsSinceEpoch ~/ 1000,
          isUtc: true,
        ),
        throwsRangeError,
      );
      expect(
        () => HijriDateTime.fromMillisecondsSinceEpoch(
          after.millisecondsSinceEpoch,
          isUtc: true,
        ),
        throwsRangeError,
      );
      expect(
        () => HijriDateTime.fromMicrosecondsSinceEpoch(
          after.microsecondsSinceEpoch,
          isUtc: true,
        ),
        throwsRangeError,
      );
    });
  });

  group('DateTime-style normalization', () {
    test('normalizes every official month underflow and overflow', () {
      for (int year = HijriDateTime.minimumYear;
          year <= HijriDateTime.maximumYear;
          year++) {
        for (int month = 1; month <= HijriDateTime.monthsPerYear; month++) {
          final int monthLength =
              UmmAlQuraOpenJdk21Fixture.monthLength(year, month);

          if (year != HijriDateTime.maximumYear || month != 12) {
            final ReferenceHijriDate expectedNext =
                UmmAlQuraOpenJdk21Fixture.dateAfter(
              year,
              month,
              monthLength,
              1,
            );
            final HijriDateTime overflow =
                HijriDateTime.utc(year, month, monthLength + 1);
            _require(
              _hasDateFields(
                overflow,
                expectedNext.year,
                expectedNext.month,
                expectedNext.day,
              ),
              '$year-$month day overflow produced $overflow, expected '
              '$expectedNext',
            );
            _require(overflow.isUtc, '$year-$month overflow lost UTC mode');
          }

          if (year != HijriDateTime.minimumYear || month != 1) {
            final ReferenceHijriDate expectedPrevious =
                UmmAlQuraOpenJdk21Fixture.dateAfter(year, month, 1, -1);
            final HijriDateTime underflow = HijriDateTime.utc(year, month, 0);
            _require(
              _hasDateFields(
                underflow,
                expectedPrevious.year,
                expectedPrevious.month,
                expectedPrevious.day,
              ),
              '$year-$month day underflow produced $underflow, expected '
              '$expectedPrevious',
            );
            _require(underflow.isUtc, '$year-$month underflow lost UTC mode');
          }
        }
      }
    });

    test('normalizes large day and month offsets', () {
      final ReferenceHijriDate expected =
          UmmAlQuraOpenJdk21Fixture.dateAfter(1445, 1, 1, 399);
      _expectHijriFields(
        HijriDateTime.utc(1445, 1, 400),
        expected.year,
        expected.month,
        expected.day,
        isUtc: true,
      );

      _expectHijriFields(HijriDateTime.utc(1445, 25, 1), 1447, 1, 1,
          isUtc: true);
      _expectHijriFields(HijriDateTime.utc(1446, 0, 1), 1445, 12, 1,
          isUtc: true);
      _expectHijriFields(HijriDateTime.utc(1446, -11, 1), 1445, 1, 1,
          isUtc: true);
    });

    test('cascades positive and negative time components exactly', () {
      final HijriDateTime negative =
          HijriDateTime.utc(1445, 9, 1, -27, -90, -75, -2000, -1500);
      expect(
        negative.toDateTime(),
        DateTime.utc(2024, 3, 11, -27, -90, -75, -2000, -1500),
      );
      expect(negative.isUtc, isTrue);

      final HijriDateTime positive =
          HijriDateTime.utc(1445, 9, 1, 23, 59, 59, 999, 1001);
      expect(
        positive.toDateTime(),
        DateTime.utc(2024, 3, 12, 0, 0, 0, 0, 1),
      );
      _expectHijriFields(
        positive,
        1445,
        9,
        2,
        microsecond: 1,
        isUtc: true,
      );

      _expectHijriFields(
        HijriDateTime(1445, 9, 1, 25, 61, 61, 1001, 1001),
        1445,
        9,
        2,
        hour: 2,
        minute: 2,
        second: 2,
        millisecond: 2,
        microsecond: 1,
      );
    });
  });

  group('Factories, time zones, and epoch values', () {
    test('local and UTC constructors preserve wall fields and precision', () {
      final HijriDateTime local =
          HijriDateTime(1445, 9, 1, 12, 34, 56, 789, 123);
      final HijriDateTime utc =
          HijriDateTime.utc(1445, 9, 1, 12, 34, 56, 789, 123);

      expect(local.toDateTime(), DateTime(2024, 3, 11, 12, 34, 56, 789, 123));
      expect(local.isUtc, isFalse);
      expect(
        utc.toDateTime(),
        DateTime.utc(2024, 3, 11, 12, 34, 56, 789, 123),
      );
      expect(utc.isUtc, isTrue);
      expect(utc.timeZoneOffset, Duration.zero);
      expect(utc.timeZoneName, 'UTC');
    });

    test('fromDateTime preserves instant, mode, and microseconds', () {
      final List<DateTime> values = <DateTime>[
        DateTime(2024, 3, 11, 12, 34, 56, 789, 123),
        DateTime.utc(2024, 3, 11, 12, 34, 56, 789, 123),
      ];

      for (final DateTime value in values) {
        final HijriDateTime hijri = HijriDateTime.fromDateTime(value);
        expect(hijri.toDateTime(), value);
        expect(hijri.isUtc, value.isUtc);
        expect(hijri.millisecond, 789);
        expect(hijri.microsecond, 123);
        _expectHijriFields(
          hijri,
          1445,
          9,
          1,
          hour: 12,
          minute: 34,
          second: 56,
          millisecond: 789,
          microsecond: 123,
          isUtc: value.isUtc,
        );
      }
    });

    test('now and timestamp are bracketed by native clocks', () {
      final DateTime beforeLocal =
          DateTime.now().subtract(const Duration(seconds: 1));
      final HijriDateTime localNow = HijriDateTime.now();
      final DateTime afterLocal =
          DateTime.now().add(const Duration(seconds: 1));
      expect(localNow.isUtc, isFalse);
      expect(localNow.toDateTime().isBefore(beforeLocal), isFalse);
      expect(localNow.toDateTime().isAfter(afterLocal), isFalse);

      final DateTime beforeUtc =
          DateTime.timestamp().subtract(const Duration(seconds: 1));
      final HijriDateTime utcNow = HijriDateTime.timestamp();
      final DateTime afterUtc =
          DateTime.timestamp().add(const Duration(seconds: 1));
      expect(utcNow.isUtc, isTrue);
      expect(utcNow.toDateTime().isBefore(beforeUtc), isFalse);
      expect(utcNow.toDateTime().isAfter(afterUtc), isFalse);
    });

    test('toUtc and toLocal preserve the represented instant', () {
      final HijriDateTime local = HijriDateTime.fromDateTime(
        DateTime(2024, 3, 11, 12, 34, 56, 789, 123),
      );
      expect(identical(local.toLocal(), local), isTrue);

      final HijriDateTime utc = local.toUtc();
      expect(utc, isA<HijriDateTime>());
      expect(utc.isUtc, isTrue);
      expect(utc.isAtSameMomentAs(local), isTrue);
      expect(utc.toDateTime().isAtSameMomentAs(local.toDateTime()), isTrue);
      expect(identical(utc.toUtc(), utc), isTrue);

      final HijriDateTime roundTrip = utc.toLocal();
      expect(roundTrip.isUtc, isFalse);
      expect(roundTrip.isAtSameMomentAs(local), isTrue);
      expect(roundTrip.toDateTime(), local.toDateTime());
    });

    test('epoch factories preserve their documented precision', () {
      final DateTime native = DateTime.utc(2024, 3, 11, 12, 34, 56, 789, 123);

      final HijriDateTime fromSeconds = HijriDateTime.fromSecondsSinceEpoch(
        native.microsecondsSinceEpoch ~/ Duration.microsecondsPerSecond,
        isUtc: true,
      );
      _expectHijriFields(
        fromSeconds,
        1445,
        9,
        1,
        hour: 12,
        minute: 34,
        second: 56,
        isUtc: true,
      );
      expect(
        fromSeconds.toDateTime(),
        DateTime.utc(2024, 3, 11, 12, 34, 56),
      );

      final HijriDateTime fromMilliseconds =
          HijriDateTime.fromMillisecondsSinceEpoch(
        native.millisecondsSinceEpoch,
        isUtc: true,
      );
      expect(
        fromMilliseconds.toDateTime(),
        DateTime.utc(2024, 3, 11, 12, 34, 56, 789),
      );

      final HijriDateTime fromMicroseconds =
          HijriDateTime.fromMicrosecondsSinceEpoch(
        native.microsecondsSinceEpoch,
        isUtc: true,
      );
      expect(fromMicroseconds.toDateTime(), native);
      expect(
        fromMicroseconds.microsecondsSinceEpoch,
        native.microsecondsSinceEpoch,
      );
      expect(
        fromMicroseconds.millisecondsSinceEpoch,
        native.millisecondsSinceEpoch,
      );
      expect(
        fromMicroseconds.secondsSinceEpoch,
        native.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond,
      );
    });

    test('local epoch construction agrees with native DateTime', () {
      final DateTime native = DateTime(2024, 3, 11, 12, 34, 56, 789, 123);
      final HijriDateTime hijri = HijriDateTime.fromMicrosecondsSinceEpoch(
        native.microsecondsSinceEpoch,
      );

      expect(hijri.isUtc, isFalse);
      expect(hijri.toDateTime(), native);
      expect(hijri.microsecondsSinceEpoch, native.microsecondsSinceEpoch);
    });
  });

  group('Parsing and formatting', () {
    test('parses local, UTC, compact, and fractional forms', () {
      _expectHijriFields(
        HijriDateTime.parse('1445-09-01 12:34:56.789123'),
        1445,
        9,
        1,
        hour: 12,
        minute: 34,
        second: 56,
        millisecond: 789,
        microsecond: 123,
      );
      _expectHijriFields(
        HijriDateTime.parse('1445-09-01T12:34:56.789123Z'),
        1445,
        9,
        1,
        hour: 12,
        minute: 34,
        second: 56,
        millisecond: 789,
        microsecond: 123,
        isUtc: true,
      );
      _expectHijriFields(
        HijriDateTime.parse('14450901T123456.1Z'),
        1445,
        9,
        1,
        hour: 12,
        minute: 34,
        second: 56,
        millisecond: 100,
        isUtc: true,
      );
    });

    test('applies positive and negative numeric offsets', () {
      final HijriDateTime positiveOffset =
          HijriDateTime.parse('1445-09-01T03:15:00+03:30');
      expect(positiveOffset.isUtc, isTrue);
      expect(
        positiveOffset.toDateTime(),
        DateTime.utc(2024, 3, 10, 23, 45),
      );

      final HijriDateTime negativeOffset =
          HijriDateTime.parse('1445-09-01T03:15:00-02:30');
      expect(negativeOffset.isUtc, isTrue);
      expect(
        negativeOffset.toDateTime(),
        DateTime.utc(2024, 3, 11, 5, 45),
      );
    });

    test('normalizes parsed calendar and time overflow', () {
      final int monthLength = UmmAlQuraOpenJdk21Fixture.monthLength(1445, 8);
      final String overflowingDay =
          (monthLength + 1).toString().padLeft(2, '0');
      _expectHijriFields(
        HijriDateTime.parse('1445-08-${overflowingDay}T25:61:61Z'),
        1445,
        9,
        2,
        hour: 2,
        minute: 2,
        second: 1,
        isUtc: true,
      );
    });

    test('applies offsets before validating the supported endpoints', () {
      final HijriDateTime minimum = HijriDateTime.utc(1300);
      expect(
        HijriDateTime.parse('1300-01-00T23:00:00-01:00'),
        minimum,
      );
      expect(
        HijriDateTime.parse('1300-01-00T23:00:00.123456-01:00'),
        minimum.add(const Duration(microseconds: 123456)),
      );

      final HijriDateTime maximumWallTime =
          HijriDateTime.utc(1600, 12, 30, 23, 0, 0, 123, 456);
      for (final String input in <String>[
        '1601-01-01T00:00:00.123456+01:00',
        '1600-12-31T00:00:00.123456+0100',
        '1600-13-01T00:00:00.123456+01',
      ]) {
        expect(HijriDateTime.parse(input), maximumWallTime, reason: input);
        expect(HijriDateTime.tryParse(input), maximumWallTime, reason: input);
      }

      for (final String input in <String>[
        '1300-01-01T00:00:00+00:01',
        '1300-01-00T23:00:00-00:59',
        '1600-12-30T23:59:59.999999-00:01',
        '1601-01-01T01:00:00+01:00',
      ]) {
        expect(() => HijriDateTime.parse(input), throwsFormatException,
            reason: input);
        expect(HijriDateTime.tryParse(input), isNull, reason: input);
      }
    });

    test('formats Hijri fields and round-trips its own output', () {
      final HijriDateTime utc =
          HijriDateTime.utc(1445, 9, 1, 12, 34, 56, 789, 123);
      expect(utc.toString(), '1445-09-01 12:34:56.789123Z');
      expect(utc.toIso8601String(), '1445-09-01T12:34:56.789123Z');
      expect(HijriDateTime.parse(utc.toIso8601String()), utc);
      expect(HijriDateTime.tryParse(utc.toIso8601String()), utc);

      final HijriDateTime wholeMilliseconds =
          HijriDateTime.utc(1445, 9, 1, 0, 0, 0, 7);
      expect(wholeMilliseconds.toString(), '1445-09-01 00:00:00.007Z');
    });

    test('rejects malformed, unsupported, and invalid-offset input', () {
      for (final String input in <String>[
        'not a date',
        '1445/09/01',
        '1445-09',
        '1445-09-01T00:00:00+24:00',
        '1445-09-01T00:00:00+03:60',
        '1299-12-29',
        '1601-01-01',
      ]) {
        expect(
          () => HijriDateTime.parse(input),
          throwsFormatException,
          reason: input,
        );
        expect(HijriDateTime.tryParse(input), isNull, reason: input);
      }
    });
  });

  group('copyWith', () {
    test('preserves Hijri type and unchanged fields', () {
      final HijriDateTime original =
          HijriDateTime.utc(1445, 9, 1, 12, 34, 56, 789, 123);
      final HijriDateTime copy = original.copyWith();

      expect(copy, isA<HijriDateTime>());
      expect(copy, original);
      expect(copy.hashCode, original.hashCode);
      expect(identical(copy, original), isFalse);
      expect(copy.toDateTime(), original.toDateTime());
    });

    test('replaces wall fields and normalizes overflow', () {
      final HijriDateTime original =
          HijriDateTime.utc(1445, 9, 1, 12, 34, 56, 789, 123);
      _expectHijriFields(
        original.copyWith(
          year: 1446,
          month: 2,
          day: 3,
          hour: 4,
          minute: 5,
          second: 6,
          millisecond: 7,
          microsecond: 8,
        ),
        1446,
        2,
        3,
        hour: 4,
        minute: 5,
        second: 6,
        millisecond: 7,
        microsecond: 8,
        isUtc: true,
      );

      final int monthLength = UmmAlQuraOpenJdk21Fixture.monthLength(1445, 9);
      _expectHijriFields(
        original.copyWith(day: monthLength + 1),
        1445,
        10,
        1,
        hour: 12,
        minute: 34,
        second: 56,
        millisecond: 789,
        microsecond: 123,
        isUtc: true,
      );
    });

    test('isUtc changes interpretation while preserving Hijri wall fields', () {
      final HijriDateTime utc =
          HijriDateTime.utc(1445, 9, 1, 12, 34, 56, 789, 123);
      final HijriDateTime local = utc.copyWith(isUtc: false);

      _expectHijriFields(
        local,
        1445,
        9,
        1,
        hour: 12,
        minute: 34,
        second: 56,
        millisecond: 789,
        microsecond: 123,
      );
      expect(local.toDateTime(), DateTime(2024, 3, 11, 12, 34, 56, 789, 123));
      expect(local.copyWith(isUtc: true), utc);
    });

    test('rejects copies whose normalized result leaves the table', () {
      expect(
        () => HijriDateTime.utc(1300).copyWith(day: 0),
        throwsRangeError,
      );
      expect(
        () => HijriDateTime.utc(1600, 12, 1).copyWith(month: 13),
        throwsRangeError,
      );
    });
  });

  group('Arithmetic, comparison, and equality', () {
    test('adds and subtracts across official month and year boundaries', () {
      final int ramadanLength = UmmAlQuraOpenJdk21Fixture.monthLength(1445, 9);
      final HijriDateTime ramadanEnd =
          HijriDateTime.utc(1445, 9, ramadanLength, 23, 30);
      _expectHijriFields(
        ramadanEnd.add(const Duration(hours: 1)),
        1445,
        10,
        1,
        hour: 0,
        minute: 30,
        isUtc: true,
      );

      final HijriDateTime newYear = HijriDateTime.utc(1446, 1, 1);
      final ReferenceHijriDate previous =
          UmmAlQuraOpenJdk21Fixture.dateAfter(1446, 1, 1, -1);
      _expectHijriFields(
        newYear.subtract(const Duration(days: 1)),
        previous.year,
        previous.month,
        previous.day,
        isUtc: true,
      );
    });

    test('preserves exact sub-day duration arithmetic', () {
      final HijriDateTime value =
          HijriDateTime.utc(1445, 9, 1, 12, 34, 56, 789, 123);
      const Duration delta = Duration(
        days: 40,
        hours: 3,
        minutes: 2,
        seconds: 1,
        microseconds: 456,
      );

      expect(
        value.add(delta).toDateTime(),
        value.toDateTime().add(delta),
      );
      expect(
        value.subtract(delta).toDateTime(),
        value.toDateTime().subtract(delta),
      );
      expect(value.add(delta).subtract(delta), value);
    });

    test('arithmetic rejects results beyond either endpoint', () {
      final int finalDay = UmmAlQuraOpenJdk21Fixture.monthLength(1600, 12);
      expect(
        () => HijriDateTime.utc(1300).subtract(const Duration(microseconds: 1)),
        throwsRangeError,
      );
      expect(
        () => HijriDateTime.utc(1600, 12, finalDay, 23, 59, 59, 999, 999)
            .add(const Duration(microseconds: 1)),
        throwsRangeError,
      );
    });

    test('comparison and difference agree with native instants', () {
      final HijriDateTime first = HijriDateTime.utc(1445, 9, 1, 10, 0, 0);
      final HijriDateTime second = HijriDateTime.utc(1445, 9, 1, 12, 30, 0);
      final DateTime nativeSecond = DateTime.utc(2024, 3, 11, 12, 30);

      expect(first.compareTo(second), lessThan(0));
      expect(second.compareTo(first), greaterThan(0));
      expect(second.compareTo(nativeSecond), 0);
      expect(first.isBefore(second), isTrue);
      expect(second.isAfter(first), isTrue);
      expect(second.isAtSameMomentAs(nativeSecond), isTrue);
      expect(second.difference(first), const Duration(hours: 2, minutes: 30));
      expect(second.difference(nativeSecond), Duration.zero);
    });

    test('equality and hashCode are symmetric with native DateTime', () {
      final DateTime native = DateTime.utc(2024, 3, 11, 12, 34, 56, 789, 123);
      final HijriDateTime first = HijriDateTime.fromDateTime(native);
      final HijriDateTime second =
          HijriDateTime.utc(1445, 9, 1, 12, 34, 56, 789, 123);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first == native, isTrue);
      expect(native == first, isTrue);
      expect(first.hashCode, native.hashCode);
      expect(<DateTime>{first, second, native}, hasLength(1));

      final HijriDateTime oneMicrosecondLater =
          second.add(const Duration(microseconds: 1));
      expect(first == oneMicrosecondLater, isFalse);
      expect(native == oneMicrosecondLater, isFalse);
    });

    test('UTC and local modes match DateTime equality semantics', () {
      final HijriDateTime utc =
          HijriDateTime.utc(1445, 9, 1, 12, 34, 56, 789, 123);
      final HijriDateTime localSameMoment = utc.toLocal();

      expect(utc.isAtSameMomentAs(localSameMoment), isTrue);
      expect(utc == localSameMoment, isFalse);
      expect(localSameMoment == utc, isFalse);
      expect(
        utc.toDateTime() == localSameMoment.toDateTime(),
        isFalse,
      );
    });
  });

  // hijri 3.0.1 differs from ICU/OpenJDK in both historical and recent
  // months. These regressions use the primary chronology, while the exhaustive
  // fixture test above validates both directions across the entire range.
  group('ICU/OpenJDK dataset regressions', () {
    test('preserves the historical Safar boundary in AH 1356', () {
      expect(HijriDateTime.daysInMonth(1356, 2), 30);
      _expectHijriFields(
        HijriDateTime.fromDateTime(DateTime.utc(1937, 5, 11)),
        1356,
        2,
        30,
        isUtc: true,
      );
      expect(HijriDateTime.utc(1356, 3, 1).toDateTime(),
          DateTime.utc(1937, 5, 12));
    });

    test('preserves the Jumada boundary in AH 1446', () {
      expect(HijriDateTime.daysInMonth(1446, 5), 29);
      _expectHijriFields(
        HijriDateTime.fromDateTime(DateTime.utc(2024, 12, 2)),
        1446,
        6,
        1,
        isUtc: true,
      );
      expect(HijriDateTime.utc(1446, 6, 1).toDateTime(),
          DateTime.utc(2024, 12, 2));
    });
  });

  // Compared with hijri 3.0.1 on 2026-10-06: 764/1,740 month lengths differ.
  // Across 51,383 days, 20,741 forward and 20,730 reverse conversions differ.
  // These equality tests failed; ICU/OpenJDK fixture tests remain authoritative.
  // Restore the hijri dev dependency and commented import to rerun.
  // group('Third-party comparison with hijri 3.0.1', () {
  //   test('compares every shared month length', () {
  //     final reference = HijriCalendar();
  //     var checked = 0;
  //     var mismatches = 0;
  //     final examples = <String>[];
  //     for (var year = 1356; year <= 1500; year++) {
  //       for (var month = 1; month <= 12; month++) {
  //         final actual = HijriDateTime.daysInMonth(year, month);
  //         final expected = reference.getDaysInMonth(year, month);
  //         checked++;
  //         if (actual != expected) {
  //           mismatches++;
  //           if (examples.length < 5) {
  //             examples.add('$year-$month: ICU/OpenJDK=$actual, hijri=$expected');
  //           }
  //         }
  //       }
  //     }
  //     final report = '$mismatches of $checked month lengths differ; $examples';
  //     print(report);
  //     expect(mismatches, 0, reason: report);
  //   });
  //
  //   test('compares both conversions for every shared Gregorian day', () {
  //     final reference = HijriCalendar();
  //     final first = reference.hijriToGregorian(1356, 1, 1);
  //     final last = reference.hijriToGregorian(
  //         1500, 12, reference.getDaysInMonth(1500, 12));
  //     final end = DateTime.utc(last.year, last.month, last.day);
  //     var checked = 0;
  //     var forwardMismatches = 0;
  //     var reverseMismatches = 0;
  //     final examples = <String>[];
  //     for (var date = DateTime.utc(first.year, first.month, first.day);
  //         !date.isAfter(end);
  //         date = date.add(const Duration(days: 1))) {
  //       final expected = HijriCalendar.fromDate(date);
  //       final actual = HijriDateTime.fromDateTime(date);
  //       checked++;
  //       if (actual.year != expected.hYear ||
  //           actual.month != expected.hMonth ||
  //           actual.day != expected.hDay) {
  //         forwardMismatches++;
  //         if (examples.length < 5) {
  //           examples.add('${date.toIso8601String()}: '
  //               'ICU/OpenJDK=${actual.year}-${actual.month}-${actual.day}, '
  //               'hijri=${expected.hYear}-${expected.hMonth}-${expected.hDay}');
  //         }
  //       }
  //       final reverse = HijriDateTime.utc(
  //               expected.hYear, expected.hMonth, expected.hDay)
  //           .toDateTime();
  //       if (reverse != date) reverseMismatches++;
  //     }
  //     final report = '$checked shared days: $forwardMismatches forward and '
  //         '$reverseMismatches reverse differences; $examples';
  //     print(report);
  //     expect(forwardMismatches, 0, reason: report);
  //     expect(reverseMismatches, 0, reason: report);
  //   });
  // });
}

const List<_ReferenceAnchor> _referenceAnchors = <_ReferenceAnchor>[
  _ReferenceAnchor(1300, 1, 1, 1882, 11, 12),
  _ReferenceAnchor(1318, 8, 1, 1900, 11, 24),
  _ReferenceAnchor(1343, 1, 1, 1924, 8, 2),
  _ReferenceAnchor(1356, 2, 30, 1937, 5, 11),
  _ReferenceAnchor(1356, 3, 1, 1937, 5, 12),
  _ReferenceAnchor(1400, 1, 1, 1979, 11, 21),
  _ReferenceAnchor(1420, 9, 1, 1999, 12, 9),
  _ReferenceAnchor(1430, 1, 1, 2008, 12, 29),
  _ReferenceAnchor(1440, 1, 1, 2018, 9, 11),
  _ReferenceAnchor(1444, 9, 1, 2023, 3, 23),
  _ReferenceAnchor(1444, 10, 1, 2023, 4, 21),
  _ReferenceAnchor(1445, 1, 1, 2023, 7, 19),
  _ReferenceAnchor(1445, 9, 1, 2024, 3, 11),
  _ReferenceAnchor(1445, 10, 1, 2024, 4, 10),
  _ReferenceAnchor(1446, 1, 1, 2024, 7, 7),
  _ReferenceAnchor(1446, 6, 1, 2024, 12, 2),
  _ReferenceAnchor(1446, 9, 1, 2025, 3, 1),
  _ReferenceAnchor(1446, 10, 1, 2025, 3, 30),
  _ReferenceAnchor(1500, 1, 1, 2076, 11, 28),
  _ReferenceAnchor(1550, 1, 1, 2125, 6, 3),
  _ReferenceAnchor(1600, 1, 1, 2173, 12, 7),
  _ReferenceAnchor(1600, 12, 30, 2174, 11, 25),
];

final class _ReferenceAnchor {
  const _ReferenceAnchor(
    this.hijriYear,
    this.hijriMonth,
    this.hijriDay,
    this.gregorianYear,
    this.gregorianMonth,
    this.gregorianDay,
  );

  final int hijriYear;
  final int hijriMonth;
  final int hijriDay;
  final int gregorianYear;
  final int gregorianMonth;
  final int gregorianDay;

  @override
  String toString() =>
      'AH $hijriYear-${_twoDigits(hijriMonth)}-${_twoDigits(hijriDay)} '
      '= $gregorianYear-${_twoDigits(gregorianMonth)}-'
      '${_twoDigits(gregorianDay)}';
}

void _expectHijriFields(
  HijriDateTime actual,
  int year,
  int month,
  int day, {
  int hour = 0,
  int minute = 0,
  int second = 0,
  int millisecond = 0,
  int microsecond = 0,
  bool isUtc = false,
  String? reason,
}) {
  expect(actual.year, year, reason: reason);
  expect(actual.month, month, reason: reason);
  expect(actual.day, day, reason: reason);
  expect(actual.hour, hour, reason: reason);
  expect(actual.minute, minute, reason: reason);
  expect(actual.second, second, reason: reason);
  expect(actual.millisecond, millisecond, reason: reason);
  expect(actual.microsecond, microsecond, reason: reason);
  expect(actual.isUtc, isUtc, reason: reason);
}

bool _hasDateFields(HijriDateTime value, int year, int month, int day) =>
    value.year == year && value.month == month && value.day == day;

bool _hasFields(
  HijriDateTime value,
  int year,
  int month,
  int day,
  int hour,
  int minute,
  int second,
  int millisecond,
  int microsecond, {
  required bool isUtc,
}) =>
    _hasDateFields(value, year, month, day) &&
    value.hour == hour &&
    value.minute == minute &&
    value.second == second &&
    value.millisecond == millisecond &&
    value.microsecond == microsecond &&
    value.isUtc == isUtc;

void _require(bool condition, String message) {
  if (!condition) fail(message);
}

int _gregorianJulianDayNumber(DateTime date) {
  final int a = (14 - date.month) ~/ 12;
  final int y = date.year + 4800 - a;
  final int m = date.month + 12 * a - 3;
  return date.day +
      ((153 * m + 2) ~/ 5) +
      365 * y +
      (y ~/ 4) -
      (y ~/ 100) +
      (y ~/ 400) -
      32045;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
