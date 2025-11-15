import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:delirio_app/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('integración + humo - navegar al perfil', (WidgetTester tester) async {
    // Ejecuta el widget de la aplicación directamente
    await tester.pumpWidget(const DeLirioApp());
    await tester.pumpAndSettle();

    // Verificar que la barra de navegación personalizada muestra los iconos principales.
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);

    // Toca el icono de perfil para navegar a la pantalla de perfil.
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();

    // El perfil debería mostrarse (verifica algunos textos clave).
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
