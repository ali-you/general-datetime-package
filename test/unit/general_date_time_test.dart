import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/general_datetime.dart';

void main() {
  group('Static Methods', () {
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
