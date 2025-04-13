import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/general_datetime.dart';

void main() {
  group('HijriDatetime Challenging Test Cases', () {
    test('Normalization overflow test (basic)', () {
      // Construct a HijriDatetime with overflowing time parts.
      // For example: 23h, 59m, 59s with extra 1500 ms and 2000 us.
      final dt = HijriDatetime(1444, 1, 29, 23, 59, 59, 1500, 2000);
      // After normalization, the hour, minute, and second values must be within conventional ranges.
      expect(dt.hour, inInclusiveRange(0, 23));
      expect(dt.minute, inInclusiveRange(0, 59));
      expect(dt.second, inInclusiveRange(0, 59));
    });

    test('Normalization overflow test (duplicate case removed)', () {
      // This test is intentionally a duplicate of the above to verify consistency.
      final dt = HijriDatetime(1444, 1, 29, 23, 59, 59, 1500, 2000);
      expect(dt.hour, inInclusiveRange(0, 23));
      expect(dt.minute, inInclusiveRange(0, 59));
      expect(dt.second, inInclusiveRange(0, 59));
    });

    test('Conversion consistency: Gregorian to Hijri and back', () {
      // Choose a representative Gregorian datetime.
      final greg = DateTime(2023, 5, 1, 15, 30);
      // Convert to Hijri using our factory method.
      final hijri = HijriDatetime.fromDateTime(greg);
      // Convert back to Gregorian.
      final gregConverted = hijri.toDatetime();
      // Due to approximation the values might not match exactly,
      // but the conversion should produce a valid DateTime.
      expect(gregConverted, isNotNull);
      // Optionally, check that the absolute time difference is small
      expect(gregConverted.difference(greg).inSeconds.abs(), lessThan(5));
    });

    test('Leap year calculation', () {
      // Using the leap year rule:
      // if (((11 * year) + 14) % 30) < 11 then it is a leap year.
      // Years known approximately as leap/non-leap by this rule.
      final dtLeap = HijriDatetime(1442);
      final dtNonLeap = HijriDatetime(1443);
      expect(dtLeap.isLeapYear, isTrue);
      expect(dtNonLeap.isLeapYear, isFalse);
    });

    test('Edge of month boundary test', () {
      // For a month expected to have 30 days (an odd month)
      final dt = HijriDatetime(1443, 1, 30);
      // Creating a date with an overflow day (31) should roll into the next month.
      final dtOverflow = HijriDatetime(1443, 1, 31);
      expect(dtOverflow.month, equals(2));
    });

    test('Known historical date conversion', () {
      // Known conversion: 1 Muharram 1443 is roughly August 10, 2021 in Gregorian.
      final knownGregorian = DateTime(2021, 8, 10);
      final hijri = HijriDatetime.fromDateTime(knownGregorian);
      // Conversion is approximate, so allow a small margin for the day.
      expect(hijri.year, equals(1443));
      expect(hijri.month, equals(1));
      expect(hijri.day, inInclusiveRange(1, 3));
    });
  });

  group('Time Normalization and Microsecond Overflow', () {
    test('Extreme microsecond cascading overflow', () {
      // Test cascading normalization with extreme microsecond value.
      final dt = HijriDatetime(1444, 1, 1, 23, 59, 59, 999, 999999);
      // Compare with expected Gregorian string conversion.
      final gt = DateTime(1444, 1, 1, 23, 59, 59, 999, 999999);
      expect(dt.toString(), gt.toString());
    });

    test('Negative time normalization', () {
      // Construct a HijriDatetime with negative overflow values.
      final dt = HijriDatetime(-100, 1, 2, -2, -70, -125, -2000, -3000);
      final gt = DateTime(-100, 1, 2, -2, -70, -125, -2000, -3000);
      // Ensure hours, minutes, seconds are within valid ranges.
      expect(dt.hour, inInclusiveRange(0, 23));
      expect(dt.minute, inInclusiveRange(0, 59));
      expect(dt.second, inInclusiveRange(0, 59));
    });
  });

  group('Day/Month Boundary Stress Tests', () {
    test('30-day month overflow with leap year impact', () {
      // 1442 is a leap year: Month 12 should have 30 days.
      final leapDay = HijriDatetime(1442, 12, 30);
      // In a non-leap year, month 12 overflows.
      final nonLeapDay = HijriDatetime(1443, 12, 30);
      expect(leapDay.month, equals(12));
      // For non-leap year, day 30 in month 12 should normalize to next year/month.
      expect(nonLeapDay.month, equals(1));
      expect(nonLeapDay.year, equals(1444));
    });

    test('Multi-month cascading overflow', () {
      // Test where overflow of days cascades through multiple months.
      final dt = HijriDatetime(1444, 1, 60);
      // Expected outcome: 60 days from day 1 of month 1 should land in month 3.
      expect(dt.month, equals(3));
      // Day might be 1 or 2 depending on month lengths.
      expect(dt.day, inInclusiveRange(1, 2));
    });
  });

  group('Conversion Fidelity and Epoch Tests', () {
    test('Millisecond precision round-trip', () {
      final original = DateTime.now().copyWith(microsecond: 456789);
      final hijri = HijriDatetime.fromDateTime(original);
      final roundTrip = hijri.toDatetime();
      // Accept a small difference due to approximations.
      expect(
          roundTrip.difference(original).inMicroseconds.abs(), lessThan(2000));
    });

    test('Epoch boundary conversion', () {
      // Convert the UNIX epoch and verify that toDatetime produces a valid DateTime.
      final unixEpoch = DateTime.utc(1970);
      final hijriEpoch = HijriDatetime.fromDateTime(unixEpoch);
      // We expect the corresponding Gregorian conversion to match the epoch time.
      expect(hijriEpoch.toDatetime().isAtSameMomentAs(unixEpoch), isTrue);
    });
  });

  group('Historical Date Verification', () {
    test('Gregorian 2023-03-23 → Ramadan 1, 1444', () {
      final greg = DateTime(2023, 3, 23);
      final hijri = HijriDatetime.fromDateTime(greg);
      // Expect Ramadan (the 9th month) to start around this conversion.
      expect(hijri.month, equals(9));
      expect(hijri.day, inInclusiveRange(1, 2));
    });

    test('Hijri 1400-1-1 → Gregorian crossover', () {
      final hijri = HijriDatetime(1400, 1, 1);
      final greg = hijri.toDatetime();
      // Verify that the Gregorian equivalent falls within an expected historical range.
      expect(greg.year, inInclusiveRange(1979, 1980));
    });
  });

  group('Extreme Value Handling', () {
    test('Year 35000 normalization', () {
      // Intentionally extreme values to test cascading normalization.
      final dt = HijriDatetime(35000, 13, 60, 25, 70, 70, 5000, 5000);
      expect(
          dt.year, greaterThan(35000)); // Year should increase due to overflow.
      expect(dt.month, inInclusiveRange(1, 12));
    });

    test('Negative year calculation', () {
      final dt = HijriDatetime(-500, 1, 1);
      // The conversion should yield a valid Gregorian DateTime.
      expect(dt.toDatetime(), isNotNull);
    });
  });

  group('Calendar Consistency Checks', () {
    test('Month length validation', () {
      final oddMonth = HijriDatetime(1444, 1); // Typically 30 days.
      final evenMonth = HijriDatetime(1444, 2); // Typically 29 days.
      expect(oddMonth.monthLength, equals(30));
      expect(evenMonth.monthLength, equals(29));
    });

    test('Day of year calculation', () {
      // Optionally, if dayOfYear is implemented.
      final firstDay = HijriDatetime(1444, 1, 1);
      final lastDay =
          HijriDatetime(1444, 12, (HijriDatetime(1444, 12).monthLength));
      // Total should roughly equal 354 (or 355 in leap years)
      expect(firstDay.dayOfYear, equals(1));
      expect(lastDay.dayOfYear, inInclusiveRange(354, 355));
    });
  });

  group('Comparison and Ordering Tests', () {
    test('isBefore and isAfter', () {
      final dt1 = HijriDatetime(1444, 5, 10, 10, 0, 0);
      final dt2 = HijriDatetime(1444, 5, 10, 12, 0, 0);
      expect(dt1.isBefore(dt2), isTrue);
      expect(dt2.isAfter(dt1), isTrue);
      expect(dt1.isAtSameMomentAs(dt1), isTrue);
    });

    test('compareTo consistency', () {
      final dt1 = HijriDatetime(1444, 5, 10, 10, 0, 0);
      final dt2 = HijriDatetime(1444, 5, 10, 10, 0, 1);
      expect(dt1.compareTo(dt2), lessThan(0));
      expect(dt2.compareTo(dt1), greaterThan(0));
    });
  });

  group('Negative Time Normalization for HijriDatetime', () {
    test('Negative hour normalization', () {
      final dt = HijriDatetime(1442, 9, 1, -3);
      // Expected final: normalization should roll negative hour to previous day.
      expect(dt.year, equals(1442));
      expect(dt.month, equals(8));
      expect(dt.day, equals(29));
      expect(dt.hour, equals(21));
    });

    test('Negative minute normalization (direct input)', () {
      final dt = HijriDatetime(1442, 9, 2, 0, -90);
      // Expected final: time should correctly cascade to previous day or hour.
      expect(dt.year, equals(1442));
      expect(dt.month, equals(9));
      expect(dt.day, equals(1));
      expect(dt.hour, equals(22));
      expect(dt.minute, equals(30));
    });

    test('Negative second normalization', () {
      final dt = HijriDatetime(1442, 9, 1, 0, 0, -75);
      // Expected final: negative 75 seconds cascades correctly.
      expect(dt.year, equals(1442));
      expect(dt.month, equals(8));
      expect(dt.day, equals(29));
      expect(dt.hour, equals(23));
      expect(dt.minute, equals(58));
      expect(dt.second, equals(45));
    });

    test('Combined negative values', () {
      final dt = HijriDatetime(1442, 9, 1, -27, -90, -75, 0, -1500);
      expect(dt.year, equals(1442));
      expect(dt.month, equals(8));
      expect(dt.day, equals(28));
      expect(dt.hour, equals(19));
      expect(dt.minute, equals(28));
      expect(dt.second, equals(44));
      expect(dt.millisecond, equals(998));
      expect(dt.microsecond, equals(500));
    });
  });
}
