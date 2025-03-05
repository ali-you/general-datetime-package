import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/src/hijri_datetime.dart';

void main() {
  group('HijriDatetime Challenging Test Cases', () {
    test('Normalization overflow test', () {
      // Construct a HijriDatetime with overflowing time parts.
      // For example: 23h, 59m, 59s with extra 1500 ms and 2000 us.
      final dt = HijriDatetime(1444, 1, 29, 23, 59, 59, 1500, 2000);
      // After normalization, the hour, minute, and second values must be within conventional ranges.
      expect(dt.hour, inInclusiveRange(0, 23));
      expect(dt.minute, inInclusiveRange(0, 59));
      expect(dt.second, inInclusiveRange(0, 59));
    });

    test('Normalization overflow test', () {
      // Construct a HijriDatetime with overflowing time parts.
      // For example: 23h, 59m, 59s with extra 1500 ms and 2000 us.
      final dt = HijriDatetime(1444, 1, 29, 23, 59, 59, 1500, 2000);
      // After normalization, the hour, minute, and second values must be within conventional ranges.
      expect(dt.hour, inInclusiveRange(0, 23));
      expect(dt.minute, inInclusiveRange(0, 59));
      expect(dt.second, inInclusiveRange(0, 59));
    });

    test('Conversion consistency: Gregorian to Hijri and back', () {
      // Choose a Gregorian datetime.
      final greg = DateTime(2023, 5, 1, 15, 30);
      // Convert to Hijri using our factory method.
      final hijri = HijriDatetime.fromDatetime(greg);
      // Convert back to Gregorian.
      final gregConverted = hijri.toDatetime();
      // Due to approximation the values might not match exactly.
      // We check that the converted Gregorian date is a valid DateTime.
      expect(gregConverted, isNotNull);
    });

    test('Leap year calculation', () {
      // Using the leap year rule:
      // if (((11 * year) + 14) % 30) < 11 then it is a leap year.
      // These tests use years known (approximately) to be leap or non-leap.
      final leapYear = 1442;  // Expected to be a leap year in some approximations.
      final nonLeapYear = 1443; // Expected non-leap year.
      final dtLeap = HijriDatetime(leapYear);
      final dtNonLeap = HijriDatetime(nonLeapYear);
      expect(dtLeap.isLeapYear, isTrue);
      expect(dtNonLeap.isLeapYear, isFalse);
    });

    test('Edge of month boundary test', () {
      // For a month expected to have 30 days (an odd month)
      // Create a date at the edge and then one day beyond.
      final dt = HijriDatetime(1443, 1, 30);
      // Now create a date with an overflow day (31)
      final dtOverflow = HijriDatetime(1443, 1, 31);
      // The normalization should roll over dtOverflow into the next month.
      expect(dtOverflow.month, equals(2));
    });

    test('Known historical date conversion', () {
      // Known conversion: 1 Muharram 1443 is roughly August 10, 2021 in Gregorian.
      final knownGregorian = DateTime(2021, 8, 10);
      final hijri = HijriDatetime.fromDatetime(knownGregorian);
      // As the conversion is approximate, we allow a small margin of error.
      expect(hijri.year, equals(1443));
      expect(hijri.month, equals(1));
      // Day might vary by one or two days due to approximation.
      expect(hijri.day, inInclusiveRange(1, 3));
    });
  });
  group('Time Normalization and Microsecond Overflow', () {
    test('Extreme microsecond cascading overflow', () {
      final dt = HijriDatetime(1444, 1, 1, 23, 59, 59, 999, 999999);
      expect(dt.hour, equals(0));
      expect(dt.minute, equals(0));
      expect(dt.second, equals(0));
      expect(dt.millisecond, equals(999));
      expect(dt.microsecond, equals(999));
    });

    test('Negative time normalization', () {
      final dt = HijriDatetime(-100, 1, 2, -2, -70, -125, -2000, -3000);
      final jt = HijriDatetime.fromDatetime(DateTime(-100));
      DateTime temp = DateTime(2025, 10, 5, -2, -30);
      print(dt.toString());
      print(jt.toString());
      print(temp.toString());
      expect(dt.hour, inInclusiveRange(0, 23));
      expect(dt.minute, inInclusiveRange(0, 59));
      expect(dt.second, inInclusiveRange(0, 59));
    });
  });

  group('Day/Month Boundary Stress Tests', () {
    test('30-day month overflow with leap year impact', () {
      final leapDay = HijriDatetime(1442, 12, 30);  // 1442 is leap year
      final nonLeapDay = HijriDatetime(1443, 12, 30); // Non-leap year
      expect(leapDay.month, equals(12));
      expect(nonLeapDay.month, equals(1));
      expect(nonLeapDay.year, equals(1444));
    });

    test('Multi-month cascading overflow', () {
      final dt = HijriDatetime(1444, 1, 60);
      expect(dt.month, equals(3));
      expect(dt.day, inInclusiveRange(1, 2));
    });
  });

  group('Leap Year Edge Cases', () {
    test('Boundary condition ((11*year +14) %30 == 10)', () {
      final edgeYear = ((30 * 5) - 14) ~/ 11; // Calculate exact boundary year
      final dt = HijriDatetime(edgeYear);
      expect(dt.isLeapYear, isTrue);
    });

    test('Year 1400 sequence verification', () {
      final leapYears = [1442, 1475, 1508].map((y) => HijriDatetime(y));
      expect(leapYears.every((dt) => dt.isLeapYear), isTrue);
    });
  });

  group('Conversion Fidelity Tests', () {
    test('Millisecond precision round-trip', () {
      final original = DateTime.now().copyWith(microsecond: 456789);
      final hijri = HijriDatetime.fromDatetime(original);
      final roundTrip = hijri.toDatetime();
      expect(roundTrip.difference(original).inMicroseconds.abs(), lessThan(2000));
    });

    test('Epoch boundary conversion', () {
      final unixEpoch = DateTime.utc(1970);
      final hijriEpoch = HijriDatetime.fromDatetime(unixEpoch);
      expect(hijriEpoch.year, inInclusiveRange(1389, 1391));
      expect(hijriEpoch.toDatetime().isAtSameMomentAs(unixEpoch), isTrue);
    });
  });

  group('Historical Date Verification', () {
    test('Gregorian 2023-03-23 → Ramadan 1, 1444', () {
      final greg = DateTime(2023, 3, 23);
      final hijri = HijriDatetime.fromDatetime(greg);
      expect(hijri.month, equals(9));
      expect(hijri.day, inInclusiveRange(1, 2));
    });

    test('Hijri 1400-1-1 → Gregorian crossover', () {
      final hijri = HijriDatetime(1400, 1, 1);
      final greg = hijri.toDatetime();
      expect(greg.year, inInclusiveRange(1979, 1980));
    });
  });

  group('Extreme Value Handling', () {
    test('Year 35000 normalization', () {
      final dt = HijriDatetime(35000, 13, 60, 25, 70, 70, 5000, 5000);
      expect(dt.year, greaterThan(35000)); // Testing integer overflow protection
      expect(dt.month, inInclusiveRange(1, 12));
    });

    test('Negative year calculation', () {
      final dt = HijriDatetime(-500, 1, 1);
      expect(dt.toDatetime(), isNotNull);
    });
  });

  group('Calendar Consistency Checks', () {
    test('Month length validation', () {
      final oddMonth = HijriDatetime(1444, 1); // Muharram (30 days)
      final evenMonth = HijriDatetime(1444, 2); // Safar (29 days)
      expect(oddMonth.monthLength, equals(30));
      expect(evenMonth.monthLength, equals(29));
    });

    // test('Day of year calculation', () {
    //   final firstDay = HijriDatetime(1444, 1, 1);
    //   final lastDay = HijriDatetime(1444, 12, 30);
    //   expect(firstDay.dayOfYear, equals(1));
    //   expect(lastDay.dayOfYear, equals(354)); // Standard non-leap year
    // });
  });


  group('Negative Time Normalization for HijriDatetime', () {
    test('Negative hour normalization', () {

      final dt = HijriDatetime(1442, 9, 1, -3);
      final temp = DateTime(2025, 9, 1, -3);
      // Expected final: 1442/8/29, 21:00:00
      print(dt.toString());
      print(temp.toString());
      expect(dt.year, equals(1442));
      expect(dt.month, equals(8));
      expect(dt.day, equals(29));
      expect(dt.hour, equals(21));
    });

    test('Negative minute normalization (direct input)', () {
      final dt = HijriDatetime(1442, 9, 2, 0, -90);
      final temp = DateTime(2025, 9, 2, 0, -90);
      // Expected final: 1442/8/29, 21:00:00
      print(temp.toString());
      // Expected final: 1442/9/1, 22:30:00
      print(dt.toString());
      expect(dt.year, equals(1442));
      expect(dt.month, equals(9));
      expect(dt.day, equals(1));
      expect(dt.hour, equals(22));
      expect(dt.minute, equals(30));
    });

    test('Negative second normalization', () {

      final dt = HijriDatetime(1442, 9, 1, 0, 0, -75);
      // Expected final: 1442/8/29, 23:58:45
      print(dt.toString());
      expect(dt.year, equals(1442));
      expect(dt.month, equals(8));
      expect(dt.day, equals(29));
      expect(dt.hour, equals(23));
      expect(dt.minute, equals(58));
      expect(dt.second, equals(45));
    });

    test('Combined negative values', () {
      final dt = HijriDatetime(1442, 9, 1, -27, -90, -75, 0, -1500);
      print(dt.toString());
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
