import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/general_datetime.dart';

void main() {
  group('Static Methods', () {
    test('now rejects an unsupported interface type', () {
      expect(() => GeneralDateTimeInterface.now<GeneralDateTimeInterface>(),
          throwsA(isA<TypeError>()));
    });
    test('now returns the requested calendar type', () {
      expect(
        GeneralDateTimeInterface.now<PersianDateTime>(),
        isA<PersianDateTime>(),
      );
      expect(
        GeneralDateTimeInterface.now<HijriDateTime>(),
        isA<HijriDateTime>(),
      );
    });
  });
}
