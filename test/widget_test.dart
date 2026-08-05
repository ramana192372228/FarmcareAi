import 'package:flutter_test/flutter_test.dart';
import 'package:farmcare_ai/main.dart';

void main() {
  testWidgets('FarmCare AI smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FarmCareAIApp());
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(FarmCareAIApp), findsOneWidget);
  });
}
