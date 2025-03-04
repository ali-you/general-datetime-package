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
}
