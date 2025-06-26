// This is a basic Flutter widget test for Production.INC.

import 'package:flutter_test/flutter_test.dart';

import 'package:game1/main.dart';

void main() {
  testWidgets('Production.INC app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(ProductionIncApp());

    // Verify that our game title is displayed.
    expect(find.text('Production.INC'), findsOneWidget);
    
    // Verify that the main game buttons exist.
    expect(find.text('Buy Materials'), findsOneWidget);
    expect(find.text('Build Products'), findsOneWidget);
    expect(find.text('Sell Products'), findsOneWidget);
  });
}
