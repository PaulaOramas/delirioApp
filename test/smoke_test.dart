import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delirio_app/main.dart';

void main() {
	testWidgets('Prueba de humo - la app inicia y muestra navegación', (WidgetTester tester) async {
		// Ejecuta el widget de la aplicación directamente
		await tester.pumpWidget(const DeLirioApp());

		// Deja que las animaciones se estabilicen.
		await tester.pumpAndSettle();

		// La barra de navegación personalizada debe mostrar los iconos/etiquetas principales.
		expect(find.byIcon(Icons.home), findsOneWidget);
		expect(find.text('Buscar'), findsOneWidget);
		expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
		expect(find.byIcon(Icons.person), findsOneWidget);
	});
}
