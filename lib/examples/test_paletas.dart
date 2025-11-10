// Test de funcionamiento de las paletas adaptativas
// Este archivo muestra los cambios hechos

/// CAMBIOS REALIZADOS PARA ADAPTAR COLORES:

/// 1. DASHBOARD SCREEN:
/// - Banner: Gradiente ahora usa Theme.of(context).colorScheme.primary
/// - Iconos de categorías: Ahora usan Theme.of(context).colorScheme.primary  
/// - Precios de productos: Ahora usan Theme.of(context).colorScheme.primary

/// 2. SEARCH SCREEN:
/// - Icono de búsqueda: Ahora usa Theme.of(context).colorScheme.primary
/// - Precios de productos: Ahora usa Theme.of(context).colorScheme.primary

/// ELEMENTOS ADAPTADOS:
/// ✅ Banner principal (dashboard)
/// ✅ Iconos de categorías (Ramos, Suculentas, Plantas, Regalos)
/// ✅ Precios de productos (dashboard y search)
/// ✅ Icono de búsqueda (search)

/// CÓMO PROBAR:
/// 1. Ir a Perfil > Paleta de colores
/// 2. Cambiar entre Rosa/Verde/Azul
/// 3. Volver al Dashboard
/// 4. Verificar que el banner y iconos cambien de color
/// 5. Ir a Buscar y verificar que también se adapte

/// COLORES POR PALETA:
/// Rosa: #E35A83 (fucsia)
/// Verde: #4CAF50 (verde)  
/// Azul: #2196F3 (azul)

/// Los elementos ahora se adaptan automáticamente usando:
/// Theme.of(context).colorScheme.primary

import 'package:flutter/material.dart';
import '../theme.dart';

class TestPaletas extends StatelessWidget {
  const TestPaletas({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Paletas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Banner de ejemplo
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ],
                ),
              ),
              child: const Center(
                child: Text(
                  'Banner Adaptativo',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Iconos de ejemplo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Icon(Icons.local_florist, 
                         size: 40, 
                         color: Theme.of(context).colorScheme.primary),
                    const Text('Ramos'),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.grass, 
                         size: 40, 
                         color: Theme.of(context).colorScheme.primary),
                    const Text('Suculentas'),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.spa, 
                         size: 40, 
                         color: Theme.of(context).colorScheme.primary),
                    const Text('Plantas'),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Precio de ejemplo
            Text(
              '\$25.99',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Selector de paletas
            ListenableBuilder(
              listenable: themeController,
              builder: (context, _) {
                return Column(
                  children: [
                    Text('Paleta actual: ${themeController.paletteDisplayName}'),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => themeController.setPalette(ColorPalette.rosa),
                          child: const Text('Rosa'),
                        ),
                        ElevatedButton(
                          onPressed: () => themeController.setPalette(ColorPalette.verde),
                          child: const Text('Verde'),
                        ),
                        ElevatedButton(
                          onPressed: () => themeController.setPalette(ColorPalette.azul),
                          child: const Text('Azul'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}