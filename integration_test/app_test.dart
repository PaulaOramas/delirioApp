import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:delirio_app/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('integration smoke - navigate to profile (guest)', (WidgetTester tester) async {
    // Pump the app widget directly (avoid calling main() which may access plugins)
    await tester.pumpWidget(const DeLirioApp());
    await tester.pumpAndSettle();

    // Verify nav icons exist
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);

    // Tap the profile nav icon and wait for navigation
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();

    // The Profile screen (guest) should show AppBar title 'Perfil' and a button 'Iniciar sesión'
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
