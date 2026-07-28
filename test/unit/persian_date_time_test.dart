import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/general_datetime.dart';

import '../fixtures/university_tehran_persian_fixture.dart';

void main() {
  group('University of Tehran reference data', () {
    test('publishes the exact official bounds and source rows', () {
      expect(PersianDateTime.minimumYear, 1206);
      expect(PersianDateTime.maximumYear, 1498);
      expect(
        UniversityTehranPersianFixture.rowCount,
        PersianDateTime.maximumYear - PersianDateTime.minimumYear + 1,
      );
      expect(
        PersianDateTime.minimumGregorianDate,
        UniversityTehranPersianFixture.firstGregorianUtc,
      );
      expect(
        PersianDateTime.maximumGregorianDate,
        UniversityTehranPersianFixture.lastGregorianUtc,
      );
      expect(
        UniversityTehranPersianFixture.firstGregorianUtc.add(Duration(
          days: UniversityTehranPersianFixture.totalSupportedDays - 1,
        )),
        UniversityTehranPersianFixture.lastGregorianUtc,
      );
      expect(
        UniversityTehranPersianFixture.firstGregorianUtc,
        DateTime.utc(1827, 3, 22),
      );
      expect(
        UniversityTehranPersianFixture.anchorGregorianUtc,
        DateTime.utc(2025, 3, 21),
      );
      expect(
        UniversityTehranPersianFixture.yearStartUtc(1403),
        DateTime.utc(2024, 3, 20),
      );
      expect(
        UniversityTehranPersianFixture.yearStartUtc(1405),
        DateTime.utc(2026, 3, 21),
      );
      expect(
        UniversityTehranPersianFixture.lastGregorianUtc,
        DateTime.utc(2120, 3, 20),
      );
      expect(
        UniversityTehranPersianFixture.rows.first.year,
        PersianDateTime.minimumYear,
      );
      expect(
        UniversityTehranPersianFixture.rows.last.year,
        PersianDateTime.maximumYear,
      );
      expect(
        UniversityTehranPersianFixture.row(1408).leapMarker,
        '**',
      );
      expect(PersianDateTime.utc(1403).name, 'Persian');
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
        final PersianDateTime persian = PersianDateTime.utc(
          anchor.persianYear,
          anchor.persianMonth,
          anchor.persianDay,
          12,
          34,
          56,
          789,
          123,
        );

        expect(persian.toDateTime(), expected, reason: anchor.toString());
        _expectPersianFields(
          PersianDateTime.fromDateTime(expected),
          anchor.persianYear,
          anchor.persianMonth,
          anchor.persianDay,
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
      for (int year = PersianDateTime.minimumYear;
          year <= PersianDateTime.maximumYear;
          year++) {
        final int expectedYearLength =
            UniversityTehranPersianFixture.yearLength(year);
        final PersianDateTime firstDay = PersianDateTime.utc(year);

        expect(
          firstDay.yearLength,
          expectedYearLength,
          reason: 'year $year',
        );
        expect(
          firstDay.isLeapYear,
          expectedYearLength == 366,
          reason: 'year $year',
        );

        int runningDayOfYear = 1;
        for (int month = 1; month <= PersianDateTime.monthsPerYear; month++) {
          final int expectedMonthLength =
              UniversityTehranPersianFixture.monthLength(year, month);
          final PersianDateTime firstOfMonth = PersianDateTime.utc(year, month);
          final PersianDateTime lastOfMonth =
              PersianDateTime.utc(year, month, expectedMonthLength);

          expect(
            PersianDateTime.daysInMonth(year, month),
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
      DateTime gregorianDay = UniversityTehranPersianFixture.firstGregorianUtc;
      int visitedDays = 0;

      for (int year = PersianDateTime.minimumYear;
          year <= PersianDateTime.maximumYear;
          year++) {
        final bool expectedLeapYear =
            UniversityTehranPersianFixture.yearLength(year) == 366;
        int expectedDayOfYear = 1;

        for (int month = 1; month <= PersianDateTime.monthsPerYear; month++) {
          final int monthLength =
              UniversityTehranPersianFixture.monthLength(year, month);
          for (int day = 1; day <= monthLength; day++) {
            final String context =
                'SH $year-${_twoDigits(month)}-${_twoDigits(day)}';
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
            final PersianDateTime persian = PersianDateTime.utc(
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
              persian.toDateTime() == expectedGregorian,
              '$context converted to ${persian.toDateTime()}, expected '
              '$expectedGregorian',
            );
            _require(persian.isUtc, '$context lost its UTC flag');
            _require(
              persian.monthLength == monthLength,
              '$context reported month length ${persian.monthLength}, expected '
              '$monthLength',
            );
            _require(
              persian.dayOfYear == expectedDayOfYear,
              '$context reported dayOfYear ${persian.dayOfYear}, expected '
              '$expectedDayOfYear',
            );
            _require(
              persian.isLeapYear == expectedLeapYear,
              '$context reported the wrong leap-year status',
            );
            _require(
              persian.weekday == expectedGregorian.weekday,
              '$context reported weekday ${persian.weekday}, expected '
              '${expectedGregorian.weekday}',
            );
            _require(
              persian.julianDay == _gregorianJulianDayNumber(expectedGregorian),
              '$context reported Julian day ${persian.julianDay}, expected '
              '${_gregorianJulianDayNumber(expectedGregorian)}',
            );

            final PersianDateTime roundTrip =
                PersianDateTime.fromDateTime(expectedGregorian);
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

      expect(visitedDays, UniversityTehranPersianFixture.totalSupportedDays);
      expect(
        gregorianDay,
        UniversityTehranPersianFixture.lastGregorianUtc
            .add(const Duration(days: 1)),
      );
    });
  });

  group('Validity and supported boundaries', () {
    test('reports strict Persian and Gregorian validity', () {
      final int finalDay = UniversityTehranPersianFixture.monthLength(1498, 12);

      expect(PersianDateTime.isValidDate(1206, 1, 1), isTrue);
      expect(PersianDateTime.isValidDate(1498, 12, finalDay), isTrue);
      expect(PersianDateTime.isValidDate(1205, 12, 29), isFalse);
      expect(PersianDateTime.isValidDate(1499, 1, 1), isFalse);
      expect(PersianDateTime.isValidDate(1403, 0, 1), isFalse);
      expect(PersianDateTime.isValidDate(1403, 13, 1), isFalse);
      expect(PersianDateTime.isValidDate(1403, 1, 0), isFalse);
      expect(
        PersianDateTime.isValidDate(
          1403,
          1,
          UniversityTehranPersianFixture.monthLength(1403, 1) + 1,
        ),
        isFalse,
      );

      expect(
        PersianDateTime.isSupportedDateTime(DateTime.utc(1827, 3, 22)),
        isTrue,
      );
      expect(
        PersianDateTime.isSupportedDateTime(
          DateTime.utc(2120, 3, 20, 23, 59, 59, 999, 999),
        ),
        isTrue,
      );
      expect(
        PersianDateTime.isSupportedDateTime(DateTime.utc(1827, 3, 21)),
        isFalse,
      );
      expect(
        PersianDateTime.isSupportedDateTime(DateTime.utc(2120, 3, 21)),
        isFalse,
      );
      expect(() => PersianDateTime.daysInMonth(1205, 1), throwsRangeError);
      expect(() => PersianDateTime.daysInMonth(1499, 1), throwsRangeError);
      expect(() => PersianDateTime.daysInMonth(1403, 0), throwsRangeError);
      expect(() => PersianDateTime.daysInMonth(1403, 13), throwsRangeError);
    });

    test('accepts both exact endpoints', () {
      _expectPersianFields(PersianDateTime.utc(1206), 1206, 1, 1, isUtc: true);
      expect(
        PersianDateTime.utc(1206).toDateTime(),
        DateTime.utc(1827, 3, 22),
      );

      final int finalDay = UniversityTehranPersianFixture.monthLength(1498, 12);
      final PersianDateTime maximum = PersianDateTime.utc(
        1498,
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
        DateTime.utc(2120, 3, 20, 23, 59, 59, 999, 999),
      );
    });

    test('normalizes into the range before checking final validity', () {
      _expectPersianFields(PersianDateTime.utc(1205, 13, 1), 1206, 1, 1,
          isUtc: true);
      _expectPersianFields(PersianDateTime.utc(1499, 0, 1), 1498, 12, 1,
          isUtc: true);
      _expectPersianFields(
        PersianDateTime.utc(1498, 13, 0),
        1498,
        12,
        UniversityTehranPersianFixture.monthLength(1498, 12),
        isUtc: true,
      );
    });

    test('constructors reject final dates outside the table', () {
      final int finalDay = UniversityTehranPersianFixture.monthLength(1498, 12);

      expect(() => PersianDateTime(1205, 12, 29), throwsRangeError);
      expect(() => PersianDateTime.utc(1205, 12, 29), throwsRangeError);
      expect(() => PersianDateTime(1499, 1, 1), throwsRangeError);
      expect(() => PersianDateTime.utc(1499, 1, 1), throwsRangeError);
      expect(() => PersianDateTime(1206, 1, 0), throwsRangeError);
      expect(
        () => PersianDateTime.utc(1498, 12, finalDay + 1),
        throwsRangeError,
      );
    });

    test('Gregorian and epoch factories reject unsupported days', () {
      final DateTime before = DateTime.utc(1827, 3, 21);
      final DateTime after = DateTime.utc(2120, 3, 21);

      expect(() => PersianDateTime.fromDateTime(before), throwsRangeError);
      expect(() => PersianDateTime.fromDateTime(after), throwsRangeError);
      expect(
        () => PersianDateTime.fromSecondsSinceEpoch(
          before.millisecondsSinceEpoch ~/ 1000,
          isUtc: true,
        ),
        throwsRangeError,
      );
      expect(
        () => PersianDateTime.fromMillisecondsSinceEpoch(
          after.millisecondsSinceEpoch,
          isUtc: true,
        ),
        throwsRangeError,
      );
      expect(
        () => PersianDateTime.fromMicrosecondsSinceEpoch(
          after.microsecondsSinceEpoch,
          isUtc: true,
        ),
        throwsRangeError,
      );
    });
  });

  group('DateTime-style normalization', () {
    test('normalizes every official month underflow and overflow', () {
      for (int year = PersianDateTime.minimumYear;
          year <= PersianDateTime.maximumYear;
          year++) {
        for (int month = 1; month <= PersianDateTime.monthsPerYear; month++) {
          final int monthLength =
              UniversityTehranPersianFixture.monthLength(year, month);

          if (year != PersianDateTime.maximumYear || month != 12) {
            final ReferencePersianDate expectedNext =
                UniversityTehranPersianFixture.dateAfter(
              year,
              month,
              monthLength,
              1,
            );
            final PersianDateTime overflow =
                PersianDateTime.utc(year, month, monthLength + 1);
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

          if (year != PersianDateTime.minimumYear || month != 1) {
            final ReferencePersianDate expectedPrevious =
                UniversityTehranPersianFixture.dateAfter(year, month, 1, -1);
            final PersianDateTime underflow =
                PersianDateTime.utc(year, month, 0);
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
      final ReferencePersianDate expected =
          UniversityTehranPersianFixture.dateAfter(1403, 1, 1, 399);
      _expectPersianFields(
        PersianDateTime.utc(1403, 1, 400),
        expected.year,
        expected.month,
        expected.day,
        isUtc: true,
      );

      _expectPersianFields(PersianDateTime.utc(1403, 25, 1), 1405, 1, 1,
          isUtc: true);
      _expectPersianFields(PersianDateTime.utc(1404, 0, 1), 1403, 12, 1,
          isUtc: true);
      _expectPersianFields(PersianDateTime.utc(1404, -11, 1), 1403, 1, 1,
          isUtc: true);
    });

    test('normalizes the month before applying the day offset', () {
      _expectPersianFields(
        PersianDateTime.utc(1403, 13, 31),
        1404,
        1,
        31,
        isUtc: true,
      );

      for (final ({int year, int month, int day}) input
          in <({int year, int month, int day})>[
        (year: 1403, month: 0, day: 31),
        (year: 1403, month: 24, day: 31),
        (year: 1403, month: -12, day: 31),
      ]) {
        final int normalizedYear = input.year + _floorDiv(input.month - 1, 12);
        final int normalizedMonth = _floorMod(input.month - 1, 12) + 1;
        final ReferencePersianDate expected =
            UniversityTehranPersianFixture.dateAfter(
          normalizedYear,
          normalizedMonth,
          1,
          input.day - 1,
        );
        _expectPersianFields(
          PersianDateTime.utc(input.year, input.month, input.day),
          expected.year,
          expected.month,
          expected.day,
          isUtc: true,
          reason: '$input',
        );
      }
    });

    test('cascades positive and negative time components exactly', () {
      final DateTime base =
          UniversityTehranPersianFixture.gregorianUtc(1403, 9, 1);
      final PersianDateTime negative =
          PersianDateTime.utc(1403, 9, 1, -27, -90, -75, -2000, -1500);
      expect(
        negative.toDateTime(),
        DateTime.utc(
          base.year,
          base.month,
          base.day,
          -27,
          -90,
          -75,
          -2000,
          -1500,
        ),
      );
      expect(negative.isUtc, isTrue);

      final PersianDateTime positive =
          PersianDateTime.utc(1403, 9, 1, 23, 59, 59, 999, 1001);
      expect(
        positive.toDateTime(),
        DateTime.utc(base.year, base.month, base.day + 1, 0, 0, 0, 0, 1),
      );
      _expectPersianFields(
        positive,
        1403,
        9,
        2,
        microsecond: 1,
        isUtc: true,
      );

      _expectPersianFields(
        PersianDateTime(1403, 9, 1, 25, 61, 61, 1001, 1001),
        1403,
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
      final PersianDateTime local =
          PersianDateTime(1403, 9, 1, 12, 34, 56, 789, 123);
      final PersianDateTime utc =
          PersianDateTime.utc(1403, 9, 1, 12, 34, 56, 789, 123);
      final DateTime expectedUtc = UniversityTehranPersianFixture.gregorianUtc(
        1403,
        9,
        1,
        12,
        34,
        56,
        789,
        123,
      );
      final DateTime expectedLocal = DateTime(
        expectedUtc.year,
        expectedUtc.month,
        expectedUtc.day,
        12,
        34,
        56,
        789,
        123,
      );

      expect(local.toDateTime(), expectedLocal);
      expect(local.isUtc, isFalse);
      expect(utc.toDateTime(), expectedUtc);
      expect(utc.isUtc, isTrue);
      expect(utc.timeZoneOffset, Duration.zero);
      expect(utc.timeZoneName, 'UTC');
    });

    test('fromDateTime preserves instant, mode, and microseconds', () {
      final DateTime utc = UniversityTehranPersianFixture.gregorianUtc(
        1403,
        9,
        1,
        12,
        34,
        56,
        789,
        123,
      );
      final List<DateTime> values = <DateTime>[
        DateTime(
          utc.year,
          utc.month,
          utc.day,
          12,
          34,
          56,
          789,
          123,
        ),
        utc,
      ];

      for (final DateTime value in values) {
        final PersianDateTime persian = PersianDateTime.fromDateTime(value);
        expect(persian.toDateTime(), value);
        expect(persian.isUtc, value.isUtc);
        expect(persian.millisecond, 789);
        expect(persian.microsecond, 123);
        _expectPersianFields(
          persian,
          1403,
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
      final PersianDateTime localNow = PersianDateTime.now();
      final DateTime afterLocal =
          DateTime.now().add(const Duration(seconds: 1));
      expect(localNow.isUtc, isFalse);
      expect(localNow.toDateTime().isBefore(beforeLocal), isFalse);
      expect(localNow.toDateTime().isAfter(afterLocal), isFalse);

      final DateTime beforeUtc =
          DateTime.timestamp().subtract(const Duration(seconds: 1));
      final PersianDateTime utcNow = PersianDateTime.timestamp();
      final DateTime afterUtc =
          DateTime.timestamp().add(const Duration(seconds: 1));
      expect(utcNow.isUtc, isTrue);
      expect(utcNow.toDateTime().isBefore(beforeUtc), isFalse);
      expect(utcNow.toDateTime().isAfter(afterUtc), isFalse);
    });

    test('toUtc and toLocal preserve the represented instant', () {
      final DateTime gregorian =
          UniversityTehranPersianFixture.gregorianUtc(1403, 9, 1);
      final PersianDateTime local = PersianDateTime.fromDateTime(
        DateTime(
          gregorian.year,
          gregorian.month,
          gregorian.day,
          12,
          34,
          56,
          789,
          123,
        ),
      );
      expect(identical(local.toLocal(), local), isTrue);

      final PersianDateTime utc = local.toUtc();
      expect(utc, isA<PersianDateTime>());
      expect(utc.isUtc, isTrue);
      expect(utc.isAtSameMomentAs(local), isTrue);
      expect(utc.toDateTime().isAtSameMomentAs(local.toDateTime()), isTrue);
      expect(identical(utc.toUtc(), utc), isTrue);

      final PersianDateTime roundTrip = utc.toLocal();
      expect(roundTrip.isUtc, isFalse);
      expect(roundTrip.isAtSameMomentAs(local), isTrue);
      expect(roundTrip.toDateTime(), local.toDateTime());
    });

    test('epoch factories preserve their documented precision', () {
      final DateTime native = UniversityTehranPersianFixture.gregorianUtc(
        1403,
        9,
        1,
        12,
        34,
        56,
        789,
        123,
      );

      final PersianDateTime fromSeconds = PersianDateTime.fromSecondsSinceEpoch(
        native.microsecondsSinceEpoch ~/ Duration.microsecondsPerSecond,
        isUtc: true,
      );
      _expectPersianFields(
        fromSeconds,
        1403,
        9,
        1,
        hour: 12,
        minute: 34,
        second: 56,
        isUtc: true,
      );
      expect(
        fromSeconds.toDateTime(),
        DateTime.utc(
          native.year,
          native.month,
          native.day,
          12,
          34,
          56,
        ),
      );

      final PersianDateTime fromMilliseconds =
          PersianDateTime.fromMillisecondsSinceEpoch(
        native.millisecondsSinceEpoch,
        isUtc: true,
      );
      expect(
        fromMilliseconds.toDateTime(),
        DateTime.utc(
          native.year,
          native.month,
          native.day,
          12,
          34,
          56,
          789,
        ),
      );

      final PersianDateTime fromMicroseconds =
          PersianDateTime.fromMicrosecondsSinceEpoch(
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
      final DateTime gregorian =
          UniversityTehranPersianFixture.gregorianUtc(1403, 9, 1);
      final DateTime native = DateTime(
        gregorian.year,
        gregorian.month,
        gregorian.day,
        12,
        34,
        56,
        789,
        123,
      );
      final PersianDateTime persian =
          PersianDateTime.fromMicrosecondsSinceEpoch(
        native.microsecondsSinceEpoch,
      );

      expect(persian.isUtc, isFalse);
      expect(persian.toDateTime(), native);
      expect(persian.microsecondsSinceEpoch, native.microsecondsSinceEpoch);
    });
  });

  group('Parsing and formatting', () {
    test('parses local, UTC, compact, and fractional forms', () {
      _expectPersianFields(
        PersianDateTime.parse('1403-09-01 12:34:56.789123'),
        1403,
        9,
        1,
        hour: 12,
        minute: 34,
        second: 56,
        millisecond: 789,
        microsecond: 123,
      );
      _expectPersianFields(
        PersianDateTime.parse('1403-09-01T12:34:56.789123Z'),
        1403,
        9,
        1,
        hour: 12,
        minute: 34,
        second: 56,
        millisecond: 789,
        microsecond: 123,
        isUtc: true,
      );
      _expectPersianFields(
        PersianDateTime.parse('14030901T123456.1Z'),
        1403,
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
      final DateTime wallTime =
          UniversityTehranPersianFixture.gregorianUtc(1403, 9, 1, 3, 15);
      final PersianDateTime positiveOffset =
          PersianDateTime.parse('1403-09-01T03:15:00+03:30');
      expect(positiveOffset.isUtc, isTrue);
      expect(
        positiveOffset.toDateTime(),
        wallTime.subtract(const Duration(hours: 3, minutes: 30)),
      );

      final PersianDateTime negativeOffset =
          PersianDateTime.parse('1403-09-01T03:15:00-02:30');
      expect(negativeOffset.isUtc, isTrue);
      expect(
        negativeOffset.toDateTime(),
        wallTime.add(const Duration(hours: 2, minutes: 30)),
      );
    });

    test('normalizes parsed calendar and time overflow', () {
      final int monthLength =
          UniversityTehranPersianFixture.monthLength(1403, 8);
      final String overflowingDay =
          (monthLength + 1).toString().padLeft(2, '0');
      _expectPersianFields(
        PersianDateTime.parse('1403-08-${overflowingDay}T25:61:61Z'),
        1403,
        9,
        2,
        hour: 2,
        minute: 2,
        second: 1,
        isUtc: true,
      );
    });

    test('formats Persian fields and round-trips its own output', () {
      final PersianDateTime utc =
          PersianDateTime.utc(1403, 9, 1, 12, 34, 56, 789, 123);
      expect(utc.toString(), '1403-09-01 12:34:56.789123Z');
      expect(utc.toIso8601String(), '1403-09-01T12:34:56.789123Z');
      expect(PersianDateTime.parse(utc.toIso8601String()), utc);
      expect(PersianDateTime.tryParse(utc.toIso8601String()), utc);

      final PersianDateTime wholeMilliseconds =
          PersianDateTime.utc(1403, 9, 1, 0, 0, 0, 7);
      expect(wholeMilliseconds.toString(), '1403-09-01 00:00:00.007Z');
    });

    test('rejects malformed, unsupported, and invalid-offset input', () {
      for (final String input in <String>[
        'not a date',
        '1403/09/01',
        '1403-09',
        '1403-09-01T00:00:00+24:00',
        '1403-09-01T00:00:00+03:60',
        '1205-12-29',
        '1499-01-01',
      ]) {
        expect(
          () => PersianDateTime.parse(input),
          throwsFormatException,
          reason: input,
        );
        expect(PersianDateTime.tryParse(input), isNull, reason: input);
      }
    });
  });

  group('copyWith', () {
    test('preserves Persian type and unchanged fields', () {
      final PersianDateTime original =
          PersianDateTime.utc(1403, 9, 1, 12, 34, 56, 789, 123);
      final PersianDateTime copy = original.copyWith();

      expect(copy, isA<PersianDateTime>());
      expect(copy, original);
      expect(copy.hashCode, original.hashCode);
      expect(identical(copy, original), isFalse);
      expect(copy.toDateTime(), original.toDateTime());
    });

    test('replaces wall fields and normalizes overflow', () {
      final PersianDateTime original =
          PersianDateTime.utc(1403, 9, 1, 12, 34, 56, 789, 123);
      _expectPersianFields(
        original.copyWith(
          year: 1404,
          month: 2,
          day: 3,
          hour: 4,
          minute: 5,
          second: 6,
          millisecond: 7,
          microsecond: 8,
        ),
        1404,
        2,
        3,
        hour: 4,
        minute: 5,
        second: 6,
        millisecond: 7,
        microsecond: 8,
        isUtc: true,
      );

      final int monthLength =
          UniversityTehranPersianFixture.monthLength(1403, 9);
      _expectPersianFields(
        original.copyWith(day: monthLength + 1),
        1403,
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

    test('isUtc changes interpretation while preserving Persian wall fields',
        () {
      final PersianDateTime utc =
          PersianDateTime.utc(1403, 9, 1, 12, 34, 56, 789, 123);
      final PersianDateTime local = utc.copyWith(isUtc: false);

      _expectPersianFields(
        local,
        1403,
        9,
        1,
        hour: 12,
        minute: 34,
        second: 56,
        millisecond: 789,
        microsecond: 123,
      );
      final DateTime gregorian =
          UniversityTehranPersianFixture.gregorianUtc(1403, 9, 1);
      expect(
        local.toDateTime(),
        DateTime(
          gregorian.year,
          gregorian.month,
          gregorian.day,
          12,
          34,
          56,
          789,
          123,
        ),
      );
      expect(local.copyWith(isUtc: true), utc);
    });

    test('rejects copies whose normalized result leaves the table', () {
      expect(
        () => PersianDateTime.utc(1206).copyWith(day: 0),
        throwsRangeError,
      );
      expect(
        () => PersianDateTime.utc(1498, 12, 1).copyWith(month: 13),
        throwsRangeError,
      );
    });
  });

  group('Arithmetic, comparison, and equality', () {
    test('adds and subtracts across official month and year boundaries', () {
      final int azarLength =
          UniversityTehranPersianFixture.monthLength(1403, 9);
      final PersianDateTime azarEnd =
          PersianDateTime.utc(1403, 9, azarLength, 23, 30);
      _expectPersianFields(
        azarEnd.add(const Duration(hours: 1)),
        1403,
        10,
        1,
        hour: 0,
        minute: 30,
        isUtc: true,
      );

      final PersianDateTime newYear = PersianDateTime.utc(1404, 1, 1);
      final ReferencePersianDate previous =
          UniversityTehranPersianFixture.dateAfter(1404, 1, 1, -1);
      _expectPersianFields(
        newYear.subtract(const Duration(days: 1)),
        previous.year,
        previous.month,
        previous.day,
        isUtc: true,
      );
    });

    test('preserves exact sub-day duration arithmetic', () {
      final PersianDateTime value =
          PersianDateTime.utc(1403, 9, 1, 12, 34, 56, 789, 123);
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
      final int finalDay = UniversityTehranPersianFixture.monthLength(1498, 12);
      expect(
        () =>
            PersianDateTime.utc(1206).subtract(const Duration(microseconds: 1)),
        throwsRangeError,
      );
      expect(
        () => PersianDateTime.utc(1498, 12, finalDay, 23, 59, 59, 999, 999)
            .add(const Duration(microseconds: 1)),
        throwsRangeError,
      );
    });

    test('comparison and difference agree with native instants', () {
      final PersianDateTime first = PersianDateTime.utc(1403, 9, 1, 10, 0, 0);
      final PersianDateTime second = PersianDateTime.utc(1403, 9, 1, 12, 30, 0);
      final DateTime nativeSecond = UniversityTehranPersianFixture.gregorianUtc(
        1403,
        9,
        1,
        12,
        30,
      );

      expect(first.compareTo(second), lessThan(0));
      expect(second.compareTo(first), greaterThan(0));
      expect(second.compareTo(nativeSecond), 0);
      expect(first.isBefore(second), isTrue);
      expect(second.isAfter(first), isTrue);
      expect(second.isAtSameMomentAs(nativeSecond), isTrue);
      expect(second.difference(first), const Duration(hours: 2, minutes: 30));
      expect(second.difference(nativeSecond), Duration.zero);
    });

    test('cross-calendar comparison uses the represented native instant', () {
      final DateTime native = UniversityTehranPersianFixture.gregorianUtc(
        1403,
        1,
        1,
        10,
        20,
        30,
        400,
        500,
      );
      final PersianDateTime persian = PersianDateTime.fromDateTime(native);
      final HijriDateTime hijri = HijriDateTime.fromDateTime(native);

      expect(persian.compareTo(hijri), 0);
      expect(hijri.compareTo(persian), 0);
      expect(persian.isAtSameMomentAs(hijri), isTrue);
      expect(hijri.isAtSameMomentAs(persian), isTrue);
      expect(persian.difference(hijri), Duration.zero);
      expect(hijri.difference(persian), Duration.zero);
      expect(persian == hijri, isTrue);
      expect(hijri == persian, isTrue);
      expect(persian.hashCode, hijri.hashCode);
      expect(<DateTime>{native, persian, hijri}, hasLength(1));
    });

    test('equality and hashCode are symmetric with native DateTime', () {
      final DateTime native = UniversityTehranPersianFixture.gregorianUtc(
        1403,
        9,
        1,
        12,
        34,
        56,
        789,
        123,
      );
      final PersianDateTime first = PersianDateTime.fromDateTime(native);
      final PersianDateTime second =
          PersianDateTime.utc(1403, 9, 1, 12, 34, 56, 789, 123);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first == native, isTrue);
      expect(native == first, isTrue);
      expect(first.hashCode, native.hashCode);
      expect(<DateTime>{first, second, native}, hasLength(1));

      final PersianDateTime oneMicrosecondLater =
          second.add(const Duration(microseconds: 1));
      expect(first == oneMicrosecondLater, isFalse);
      expect(native == oneMicrosecondLater, isFalse);
    });

    test('UTC and local modes match DateTime equality semantics', () {
      final PersianDateTime utc =
          PersianDateTime.utc(1403, 9, 1, 12, 34, 56, 789, 123);
      final PersianDateTime localSameMoment = utc.toLocal();

      expect(utc.isAtSameMomentAs(localSameMoment), isTrue);
      expect(utc == localSameMoment, isFalse);
      expect(localSameMoment == utc, isFalse);
      expect(
        utc.toDateTime() == localSameMoment.toDateTime(),
        isFalse,
      );
    });
  });
}

const List<_ReferenceAnchor> _referenceAnchors = <_ReferenceAnchor>[
  _ReferenceAnchor(1206, 1, 1, 1827, 3, 22),
  _ReferenceAnchor(1210, 1, 1, 1831, 3, 21),
  _ReferenceAnchor(1300, 1, 1, 1921, 3, 21),
  _ReferenceAnchor(1350, 1, 1, 1971, 3, 21),
  _ReferenceAnchor(1379, 1, 1, 2000, 3, 20),
  _ReferenceAnchor(1399, 1, 1, 2020, 3, 20),
  _ReferenceAnchor(1403, 1, 1, 2024, 3, 20),
  _ReferenceAnchor(1403, 9, 1, 2024, 11, 21),
  _ReferenceAnchor(1403, 12, 30, 2025, 3, 20),
  _ReferenceAnchor(1404, 1, 1, 2025, 3, 21),
  _ReferenceAnchor(1405, 1, 1, 2026, 3, 21),
  _ReferenceAnchor(1450, 1, 1, 2071, 3, 21),
  _ReferenceAnchor(1498, 1, 1, 2119, 3, 21),
  _ReferenceAnchor(1498, 12, 30, 2120, 3, 20),
];

final class _ReferenceAnchor {
  const _ReferenceAnchor(
    this.persianYear,
    this.persianMonth,
    this.persianDay,
    this.gregorianYear,
    this.gregorianMonth,
    this.gregorianDay,
  );

  final int persianYear;
  final int persianMonth;
  final int persianDay;
  final int gregorianYear;
  final int gregorianMonth;
  final int gregorianDay;

  @override
  String toString() =>
      'SH $persianYear-${_twoDigits(persianMonth)}-${_twoDigits(persianDay)} '
      '= $gregorianYear-${_twoDigits(gregorianMonth)}-'
      '${_twoDigits(gregorianDay)}';
}

void _expectPersianFields(
  PersianDateTime actual,
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

bool _hasDateFields(PersianDateTime value, int year, int month, int day) =>
    value.year == year && value.month == month && value.day == day;

bool _hasFields(
  PersianDateTime value,
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

int _floorDiv(int value, int divisor) {
  final int quotient = value ~/ divisor;
  return value.remainder(divisor) < 0 ? quotient - 1 : quotient;
}

int _floorMod(int value, int divisor) =>
    value - _floorDiv(value, divisor) * divisor;

String _twoDigits(int value) => value.toString().padLeft(2, '0');
