import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/general_datetime.dart';

import '../support/calendar_test_case.dart';

void main() {
  const minimumInt = -9223372036854775808;
  const maximumInt = 9223372036854775807;
  for (final calendar in calendarTestCases) {
    for (final utc in [true, false]) {
      group('${calendar.name} ${utc ? 'UTC' : 'local'} exact normalization',
          () {
        final year = calendar.anchorYear;
        DateTime make(List<int> fields) => calendar.make(year, 1, 1,
            hour: fields[0],
            minute: fields[1],
            second: fields[2],
            millisecond: fields[3],
            microsecond: fields[4],
            isUtc: utc);

        test('rejects multiplied time fields that used to wrap to zero', () {
          const amounts = [
            18014398509481984,
            72057594037927936,
            288230376151711744,
            2305843009213693952,
            maximumInt
          ];
          for (var field = 0; field < amounts.length; field++) {
            for (final amount in [
              amounts[field],
              -amounts[field],
              minimumInt
            ]) {
              final fields = [0, 0, 0, 0, 0]..[field] = amount;
              expect(() => make(fields), throwsRangeError,
                  reason: 'field=$field value=$amount');
            }
          }
        });

        test('rejects addition overflow even when each product fits', () {
          for (final sign in [1, -1]) {
            expect(
                () => make([
                      0,
                      0,
                      sign * 9223372036854,
                      sign * 9223372036854000,
                      sign * 1551616
                    ]),
                throwsRangeError);
          }
        });

        test('preserves exact cancellation and microseconds', () {
          final result =
              make([0, 0, 9223372036854775, -9223372036854775000, 321]);
          expect(
              result, calendar.make(year, 1, 1, microsecond: 321, isUtc: utc));
          expect(result.microsecond, 321);
          expect(result.isUtc, utc);
          // One hundred million civil days cancel before range validation.
          final dayCancellation = calendar.make(year, 1, -99999999,
              hour: 2400000000, microsecond: 321, isUtc: utc);
          expect(dayCancellation, result);
        });

        test('rejects month subtraction wrap and unsupported extreme years',
            () {
          expect(
              () => calendar.make(year - 768614336404564650, minimumInt, 1,
                  isUtc: utc),
              throwsRangeError);
          for (final extreme in [minimumInt, maximumInt]) {
            expect(() => calendar.make(extreme, 1, 1, isUtc: utc),
                throwsRangeError);
            expect(() => calendar.make(year, extreme, 1, isUtc: utc),
                throwsRangeError);
            expect(() => calendar.make(year, 1, extreme, isUtc: utc),
                throwsRangeError);
          }
        });

        test('normalizes extreme months when exact year cancellation is valid',
            () {
          expect(
              calendar.make(year + 768614336404564651, minimumInt, 1,
                  isUtc: utc),
              calendar.make(year, 4, 1, isUtc: utc));
          expect(
              calendar.make(year - 768614336404564650, maximumInt, 1,
                  isUtc: utc),
              calendar.make(year, 7, 1, isUtc: utc));
        });

        test('keeps ordinary normalization and the maximum-date sentinel', () {
          expect(
              make([25, 61, -1, 1001, -1]),
              calendar.make(year, 1, 2,
                  hour: 2, minute: 1, microsecond: 999, isUtc: utc));
          expect(
              calendar.make(calendar.maximumYear + 1, 1, 0, isUtc: utc),
              calendar.make(calendar.maximumYear, 12, calendar.lastDay,
                  isUtc: utc));
          expect(
              () => calendar.make(calendar.maximumYear + 1, 1, 1, isUtc: utc),
              throwsRangeError);
        });

        test('copyWith also rejects extreme constructor fields', () {
          final date = calendar.make(year, 1, 1, isUtc: utc);
          expect(
              () =>
                  CalendarDateUtils.copyWith(date, second: 288230376151711744),
              throwsRangeError);
        });
      });
    }
  }
}
