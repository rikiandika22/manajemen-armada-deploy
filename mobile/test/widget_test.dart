import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';

void main() {
  testWidgets('App renders splash screen successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());

    // Verify that our app displays the splash screen text.
    expect(find.text('Sumber Agung Trans'), findsOneWidget);
  });
}
