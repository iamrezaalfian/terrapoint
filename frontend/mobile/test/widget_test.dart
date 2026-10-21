import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_mobile/main.dart';

void main() {
  testWidgets('TerraPoint Clean Modern Tech App initial render test', (WidgetTester tester) async {
    await tester.pumpWidget(const TerraPointApp());
    // Initial Splash Screen test
    expect(find.text('TerraPoint'), findsOneWidget);
    expect(find.text('Mining Logistics & Visual Verification'), findsOneWidget);

    // Fast-forward splash timer (2 seconds)
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Navigated to Login Screen
    expect(find.text('Masuk ke Sistem'), findsOneWidget);
    expect(find.text('DRV-001'), findsOneWidget);
  });
}
