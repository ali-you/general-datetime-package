import 'package:calendar_demo/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('calendar application loads and changes language',
      (tester) async {
    app.main();
    await tester.pumpAndSettle();
    expect(find.text('Calendar'), findsOneWidget);
    await tester.tap(find.text('فارسی'));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
