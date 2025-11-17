import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:delirio_app/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('integración - ver detalle de producto desde dashboard', (WidgetTester tester) async {
    // Ejecuta el widget de la aplicación directamente
    await tester.pumpWidget(const DeLirioApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verificar que estamos en el Dashboard (título AppBar 'Estatus')
    expect(find.text('Estatus'), findsOneWidget);

    // Encontrar tarjetas de productos (InkWell dentro de Card)
    // Cada Card contiene un producto, buscamos por el primer Card
    final productCards = find.byType(Card);
    expect(productCards, findsWidgets);

    // Tocar la primera tarjeta de producto para navegar a su detalle
    await tester.tap(productCards.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verificar que llegamos a la pantalla de detalle
    // La pantalla de producto debería tener un AppBar con el nombre del producto
    // y un PageView para las imágenes (buscar por Hero tag o por imagen)
    expect(find.byType(PageView), findsOneWidget);

    // Verificar que hay al menos un widget de imagen (Image.network o similar)
    expect(find.byType(Image), findsWidgets);

    // Verificar que hay un texto de precio (verifica que contiene '$')
    final priceMatches = find.byWidgetPredicate(
      (widget) => widget is Text && widget.data?.contains('\$') ?? false,
    );
    expect(priceMatches, findsOneWidget);

    // Esperar a que se establezcan las animaciones
    await tester.pumpAndSettle();
  });
}
