import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/general_datetime.dart';

void main() {
  group('Static Methods', () {
    test('Now Method', () {
      print(GeneralDateTimeInterface.now<JalaliDateTime>());
    });
  });
}
