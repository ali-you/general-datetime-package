import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/general_datetime.dart';

import '../support/calendar_test_case.dart';

void main() {
  // Independently specified Unix-second buckets around fractional boundaries.
  const cases = <(int, int)>[
    (-2000001, -3),
    (-2000000, -2),
    (-1999999, -2),
    (-1000001, -2),
    (-1000000, -1),
    (-999999, -1),
    (-999001, -1),
    (-999000, -1),
    (-1001, -1),
    (-1000, -1),
    (-999, -1),
    (-1, -1),
    (0, 0),
    (1, 0),
    (999, 0),
    (1000, 0),
    (1001, 0),
    (999000, 0),
    (999001, 0),
    (999999, 0),
    (1000000, 1),
    (1000001, 1),
    (1999999, 1),
    (2000000, 2),
    (2000001, 2),
  ];
  for (final calendar in calendarTestCases) {
    group('${calendar.name} Unix epoch seconds', () {
      test('fractional boundaries round down in UTC and local modes', () {
        for (final (micros, seconds) in cases) {
          for (final utc in [true, false]) {
            final date = calendar.fromMicroseconds(micros, utc);
            final value = date as GeneralDateTimeInterface;
            expect(value.secondsSinceEpoch, seconds,
                reason: '$micros microseconds UTC=$utc');
            expect(date.microsecondsSinceEpoch, micros);
          }
        }
      });

      test('whole-second reconstruction starts the containing second', () {
        for (final (micros, seconds) in cases) {
          final date = calendar.fromMicroseconds(micros, true)
              as GeneralDateTimeInterface;
          final start = calendar.fromSeconds(date.secondsSinceEpoch, true);
          expect(start.microsecondsSinceEpoch, seconds * 1000000);
          expect(micros - start.microsecondsSinceEpoch,
              inInclusiveRange(0, 999999));
          expect((date.toLocal() as GeneralDateTimeInterface).secondsSinceEpoch,
              seconds);
          expect((date.toUtc() as GeneralDateTimeInterface).secondsSinceEpoch,
              seconds);
        }
      });

      test('exact seconds round-trip beyond 32-bit boundaries', () {
        for (final seconds in [-2147483649, -1, 0, 1, 2147483648, 4294967296]) {
          for (final utc in [true, false]) {
            final date =
                calendar.fromSeconds(seconds, utc) as GeneralDateTimeInterface;
            expect(date.secondsSinceEpoch, seconds);
          }
        }
      });
    });
  }
}
