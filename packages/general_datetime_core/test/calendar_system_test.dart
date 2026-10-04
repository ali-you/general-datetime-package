import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:test/test.dart';

void main() {
  for (final id in CalendarId.values) {
    final system = CalendarSystems.forId(id);
    group(id.identifier, () {
      test('strict construction and conversion share an independent day', () {
        final fields = system.fromGregorianDay(DateTime.utc(2024, 3, 20));
        final expected = switch (id) {
          CalendarId.gregory => (year: 2024, month: 3, day: 20),
          CalendarId.persian => (year: 1403, month: 1, day: 1),
          CalendarId.islamicUmalqura => (year: 1445, month: 9, day: 10),
        };
        expect(fields, expected);
        expect(system.toGregorianDay(fields.year, fields.month, fields.day),
            DateTime.utc(2024, 3, 20));
        expect(() => system.construct(fields.year, 13, 1), throwsArgumentError);
        expect(() => system.construct(fields.year, fields.month, 1, hour: 24),
            throwsArgumentError);
      });
      test('finite bounds reject adjacent civil days', () {
        for (final bound in [system.minimumDate, system.maximumDate]) {
          expect(
              system.isValidDate(bound.year, bound.month, bound.day), isTrue);
          expect(
              system.fromGregorianDay(
                  system.toGregorianDay(bound.year, bound.month, bound.day)),
              bound);
        }
        expect(system.isValidDate(system.minimumDate.year - 1, 1, 1), isFalse);
        expect(system.isValidDate(system.maximumDate.year + 1, 1, 1), isFalse);
      });
      test('instant conversion retains exact microseconds', () {
        final instant = DateTime.utc(2024, 3, 20, 12, 34, 56, 123, 456);
        final result = system.fromInstant(instant);
        expect(result.microsecondsSinceEpoch, instant.microsecondsSinceEpoch);
        expect(result.isUtc, isTrue);
        expect(system.dataRevision, isNotEmpty);
      });
    });
  }
  test('published coverage is distinct from supported Persian range', () {
    expect(CalendarSystems.persian.hasPublishedData(1403), isTrue);
    expect(CalendarSystems.persian.hasPublishedData(2000), isFalse);
    expect(CalendarSystems.ummAlQura.hasPublishedData(1400), isTrue);
    final PersianDateTime typed =
        GeneralDateTimeInterface.now<PersianDateTime>();
    expect(typed, isA<PersianDateTime>());
  });
}
