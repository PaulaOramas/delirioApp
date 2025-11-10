// Ejemplos de uso del Sistema de Paletas de Colores
// Archivo: ejemplos_paletas.dart

import 'package:flutter/material.dart';
import '../theme.dart';

/// ============================================
/// EJEMPLOS DE USO DEL SISTEMA DE PALETAS
/// ============================================

class EjemplosPaletas extends StatefulWidget {
  const EjemplosPaletas({Key? key}) : super(key: key);

  @override
  State<EjemplosPaletas> createState() => _EjemplosPaletasState();
}

class _EjemplosPaletasState extends State<EjemplosPaletas> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejemplos de Paletas'),
        actions: [
          // Botón para cambiar paleta rápidamente
          PopupMenuButton<ColorPalette>(
            icon: const Icon(Icons.palette),
            onSelected: (ColorPalette palette) {
              themeController.setPalette(palette);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ColorPalette.rosa,
                child: Text('🌸 Rosa'),
              ),
              const PopupMenuItem(
                value: ColorPalette.verde,
                child: Text('🌿 Verde'),
              ),
              const PopupMenuItem(
                value: ColorPalette.azul,
                child: Text('🌊 Azul'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Información actual
            _buildCurrentPaletteInfo(),
            
            const SizedBox(height: 24),
            
            // Botones de cambio rápido
            _buildQuickPaletteButtons(),
            
            const SizedBox(height: 24),
            
            // Ejemplos de componentes
            _buildComponentExamples(),
            
            const SizedBox(height: 24),
            
            // Card con diferentes estilos
            _buildStyledCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPaletteInfo() {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Icon(
                    Icons.palette,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paleta Actual: ${themeController.paletteDisplayName}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Modo: ${_getModoTexto()}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickPaletteButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cambio Rápido de Paleta:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPaletteButton(
                'Rosa',
                Icons.favorite,
                kFucsia,
                ColorPalette.rosa,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPaletteButton(
                'Verde',
                Icons.eco,
                kVerdePrimario,
                ColorPalette.verde,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPaletteButton(
                'Azul',
                Icons.waves,
                kAzulPrimario,
                ColorPalette.azul,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaletteButton(String nombre, IconData icono, Color color, ColorPalette paleta) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final isSelected = themeController.palette == paleta;
        
        return ElevatedButton.icon(
          onPressed: () {
            themeController.setPalette(paleta);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cambiado a paleta $nombre'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          icon: Icon(icono),
          label: Text(nombre),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? color : null,
            foregroundColor: isSelected ? Colors.white : null,
          ),
        );
      },
    );
  }

  Widget _buildComponentExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ejemplos de Componentes:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        
        // Botones
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Primario'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Secundario'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton(
                onPressed: () {},
                child: const Text('Texto'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Campo de texto
        TextField(
          decoration: InputDecoration(
            labelText: 'Campo de ejemplo',
            hintText: 'Escribe algo aquí...',
            prefixIcon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Switch y Checkbox
        Row(
          children: [
            Expanded(
              child: SwitchListTile(
                title: const Text('Opción 1'),
                value: true,
                onChanged: (_) {},
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Opción 2'),
                value: true,
                onChanged: (_) {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStyledCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cards con Estilo Dinámico:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        
        // Card adaptativa con colores actuales
        Card(
          elevation: 4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'Card Adaptativa',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Este card se adapta automáticamente a la paleta seleccionada',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Chips con colores dinámicos
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.star),
              label: const Text('Favorito'),
              onPressed: () {},
            ),
            FilterChip(
              label: const Text('Filtro'),
              selected: true,
              onSelected: (_) {},
            ),
            Chip(
              avatar: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person, color: Colors.white, size: 16),
              ),
              label: const Text('Usuario'),
            ),
          ],
        ),
      ],
    );
  }

  String _getModoTexto() {
    switch (themeController.mode) {
      case ThemeMode.system:
        return 'Sistema';
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
    }
  }
}

/// ============================================
/// WIDGET PERSONALIZADO QUE USA LAS PALETAS
/// ============================================

class IndicadorPaleta extends StatelessWidget {
  final String texto;
  
  const IndicadorPaleta({
    Key? key,
    required this.texto,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$texto • ${themeController.paletteDisplayName}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}

/// ============================================
/// EJEMPLOS DE USO PROGRAMÁTICO
/// ============================================

class EjemplosUso {
  
  /// Cambiar paleta programáticamente
  static void cambiarPaleta(ColorPalette nuevaPaleta) {
    themeController.setPalette(nuevaPaleta);
  }
  
  /// Obtener color primario actual
  static Color getColorPrimario(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }
  
  /// Verificar si está en modo oscuro
  static bool esModoOscuro(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
  
  /// Obtener nombre de la paleta actual
  static String getPaletaActual() {
    return themeController.paletteDisplayName;
  }
  
  /// Widget que reacciona a cambios de paleta
  static Widget widgetReactivo(Widget child) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) => child,
    );
  }
}

/// ============================================
/// EXTENSIONES ÚTILES
/// ============================================

extension ColorPaletteExtension on ColorPalette {
  String get displayName {
    switch (this) {
      case ColorPalette.rosa:
        return 'Rosa';
      case ColorPalette.verde:
        return 'Verde';
      case ColorPalette.azul:
        return 'Azul';
    }
  }
  
  IconData get icon {
    switch (this) {
      case ColorPalette.rosa:
        return Icons.favorite;
      case ColorPalette.verde:
        return Icons.eco;
      case ColorPalette.azul:
        return Icons.waves;
    }
  }
  
  String get description {
    switch (this) {
      case ColorPalette.rosa:
        return 'Paleta original DeLirio';
      case ColorPalette.verde:
        return 'Paleta natural y fresca';
      case ColorPalette.azul:
        return 'Paleta profesional y serena';
    }
  }
}