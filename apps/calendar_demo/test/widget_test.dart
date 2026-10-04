import 'package:calendar_demo/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('demo boots and switches presentation language', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    expect(find.text('Calendar'), findsOneWidget);
    await tester.tap(find.text('فارسی'));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
