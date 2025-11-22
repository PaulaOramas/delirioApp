import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/screens/product_screen.dart';
import 'package:delirio_app/models/product.dart';
import 'package:delirio_app/services/product_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  // UI secundaria (sugerencias "bonitas")
  final List<String> _categories = [
    'Ramos',
    'Plantas',
    'Regalos',
    'Secos',
    'Premium',
    'Ofertas'
  ];
  final List<String> _trending = [
    'Ramo primavera',
    'Monstera',
    'Rosas rojas',
    'Suculentas',
    'Girasoles'
  ];
  final List<String> _recent = ['Ramo pastel', 'Orquídea blanca'];

  // Datos reales
  List<Product> _all = [];
  List<Product> _filtered = [];
  bool _loadingAll = true;
  String? _error;

  // Estado de búsqueda/filtro
  bool _showSuggestions = true;
  String? _selectedCategory; // null = sin filtro por categoría (chips superiores)

  // ===== Facetas / filtros avanzados =====

  // Precio
  double _priceMax = 150;

  // Facetas disponibles (calculadas a partir de los productos)
  Set<String> _availableCategoriesFacet = {};
  Set<String> _availableColors = {};
  Set<String> _availableFlowerTypes = {};
  Set<String> _availableAccessories = {};
  Set<String> _availableOcasiones = {};
  Set<String> _availableEstados = {};

  // Facetas seleccionadas
  Set<String> _selectedCategories = {};
  Set<String> _selectedColors = {};
  Set<String> _selectedFlowerTypes = {};
  Set<String> _selectedAccessories = {};
  Set<String> _selectedOcasiones = {};
  Set<String> _selectedEstados = {};

  // Diccionarios para detectar patrones por texto
  final Map<String, String> _colorTokens = const {
    'rojo': 'Rojo',
    'roja': 'Rojo',
    'rosas rojas': 'Rojo',
    'rosado': 'Rosado',
    'rosa pastel': 'Rosado',
    'fucsia': 'Fucsia',
    'amarillo': 'Amarillo',
    'amarilla': 'Amarillo',
    'girasol': 'Amarillo',
    'girasoles': 'Amarillo',
    'blanco': 'Blanco',
    'blanca': 'Blanco',
    'azul': 'Azul',
    'celeste': 'Celeste',
    'morado': 'Morado',
    'lila': 'Lila',
    'violeta': 'Violeta',
    'verde': 'Verde',
    'naranja': 'Naranja',
    'naranjas': 'Naranja',
  };

  final Map<String, String> _flowerTokens = const {
    'rosa': 'Rosas',
    'rosas': 'Rosas',
    'girasol': 'Girasoles',
    'girasoles': 'Girasoles',
    'tulipan': 'Tulipanes',
    'tulipán': 'Tulipanes',
    'tulipanes': 'Tulipanes',
    'orquidea': 'Orquídeas',
    'orquídea': 'Orquídeas',
    'orquídeas': 'Orquídeas',
    'lirio': 'Lirios',
    'lirios': 'Lirios',
    'clavel': 'Claveles',
    'claveles': 'Claveles',
    'hortensia': 'Hortensias',
    'hortensias': 'Hortensias',
    'suculenta': 'Suculentas',
    'suculentas': 'Suculentas',
    'peonia': 'Peonías',
    'peonía': 'Peonías',
    'peonias': 'Peonías',
  };

  final Map<String, String> _accessoryTokens = const {
    'peluche': 'Peluche',
    'globos': 'Globo',
    'globo': 'Globo',
    'chocolate': 'Chocolate',
    'chocolates': 'Chocolate',
    'caja': 'Caja decorativa',
    'caja decorativa': 'Caja decorativa',
    'jarron': 'Jarrón',
    'jarrón': 'Jarrón',
    'tarjeta': 'Tarjeta',
    'sobre': 'Sobre con mensaje',
    'vela': 'Vela',
    'vino': 'Vino',
    'botella': 'Botella',
  };

  final Map<String, String> _occasionTokens = const {
    'cumple': 'Cumpleaños',
    'cumpleaños': 'Cumpleaños',
    'aniversario': 'Aniversario',
    'san valentin': 'San Valentín',
    'san valentín': 'San Valentín',
    'día de la madre': 'Día de la Madre',
    'dia de la madre': 'Día de la Madre',
    'día de la mujer': 'Día de la Mujer',
    'dia de la mujer': 'Día de la Mujer',
    'boda': 'Boda',
    'matrimonio': 'Boda',
    'graduacion': 'Graduación',
    'graduación': 'Graduación',
    'agradecimiento': 'Agradecimiento',
    'amistad': 'Amistad',
    'luto': 'Luto',
  };

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loadingAll = true;
      _error = null;
    });
    try {
      final list = await ProductService.getAllProducts();
      setState(() {
        _all = list;
        _loadingAll = false;
      });
      _recomputeFacets();
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los productos: $e';
        _loadingAll = false;
      });
    }
  }

  void _recomputeFacets() {
    final cats = <String>{};
    final colors = <String>{};
    final flowers = <String>{};
    final accessories = <String>{};
    final ocasiones = <String>{};
    final estados = <String>{};

    for (final p in _all) {
      final text = _norm('${p.nombre} ${p.descripcion}');
      // Categorías desde BD
      if (p.categoria.trim().isNotEmpty) {
        cats.add(_beautify(p.categoria));
      }
      // Colores
      _collectTokens(text, _colorTokens, colors);
      // Tipos de flor
      _collectTokens(text, _flowerTokens, flowers);
      // Accesorios
      _collectTokens(text, _accessoryTokens, accessories);
      // Ocasiones
      _collectTokens(text, _occasionTokens, ocasiones);
      // Estado
      if (p.estado.trim().isNotEmpty) {
        estados.add(_beautify(p.estado));
      }
    }

    setState(() {
      _availableCategoriesFacet = cats;
      _availableColors = colors;
      _availableFlowerTypes = flowers;
      _availableAccessories = accessories;
      _availableOcasiones = ocasiones;
      _availableEstados = estados;
    });
  }

  void _collectTokens(
    String haystack,
    Map<String, String> tokens,
    Set<String> target,
  ) {
    for (final entry in tokens.entries) {
      if (haystack.contains(entry.key)) {
        target.add(entry.value);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ----------------- LÓGICA DE BÚSQUEDA/FILTRO -----------------

  String _norm(String? s) => (s ?? '').toLowerCase().trim();

  String _beautify(String s) {
    final t = _norm(s);
    if (t.isEmpty) return '';
    return t[0].toUpperCase() + t.substring(1);
  }

  String _productText(Product p) =>
      _norm('${p.nombre} ${p.descripcion} ${p.categoria}');

  bool _matchesTokenFacet(
    Product p,
    Map<String, String> tokenMap,
    Set<String> selectedLabels,
  ) {
    if (selectedLabels.isEmpty) return true;
    final text = _productText(p);
    final selectedNorm = selectedLabels.map(_norm).toSet();

    for (final entry in tokenMap.entries) {
      if (text.contains(entry.key)) {
        final labelNorm = _norm(entry.value);
        if (selectedNorm.contains(labelNorm)) return true;
      }
    }
    return false;
  }

  void _applyFilters() {
    final text = _controller.text.trim();
    final hasText = text.length >= 2;
    final hasSimpleCategory =
        _selectedCategory != null && _selectedCategory!.isNotEmpty;

    final hasAdvancedFilters =
        _selectedCategories.isNotEmpty ||
        _selectedColors.isNotEmpty ||
        _selectedFlowerTypes.isNotEmpty ||
        _selectedAccessories.isNotEmpty ||
        _selectedOcasiones.isNotEmpty ||
        _selectedEstados.isNotEmpty ||
        _priceMax < 150;

    List<Product> result = _all;

    // 1. Filtro por texto (prioridad)
    if (hasText) {
      final q = _norm(text);
      result = result.where((p) => _productText(p).contains(q)).toList();
    } else if (hasSimpleCategory) {
      // 2. Filtro por categoría superior (chips)
      final cat = _norm(_selectedCategory);
      result = result.where((p) => _norm(p.categoria) == cat).toList();
    }

    // 3. Facetas avanzadas (se aplican sobre el resultado actual)
    if (_selectedCategories.isNotEmpty) {
      final catsNorm = _selectedCategories.map(_norm).toSet();
      result = result
          .where((p) => catsNorm.contains(_norm(p.categoria)))
          .toList();
    }

    if (_selectedColors.isNotEmpty) {
      result = result
          .where((p) =>
              _matchesTokenFacet(p, _colorTokens, _selectedColors))
          .toList();
    }

    if (_selectedFlowerTypes.isNotEmpty) {
      result = result
          .where((p) =>
              _matchesTokenFacet(p, _flowerTokens, _selectedFlowerTypes))
          .toList();
    }

    if (_selectedAccessories.isNotEmpty) {
      result = result
          .where((p) =>
              _matchesTokenFacet(p, _accessoryTokens, _selectedAccessories))
          .toList();
    }

    if (_selectedOcasiones.isNotEmpty) {
      result = result
          .where((p) =>
              _matchesTokenFacet(p, _occasionTokens, _selectedOcasiones))
          .toList();
    }

    if (_selectedEstados.isNotEmpty) {
      final sel = _selectedEstados.map(_norm).toSet();
      result =
          result.where((p) => sel.contains(_norm(p.estado))).toList();
    }

    // 4. Precio y stock siempre
    result = result
        .where((p) => p.precio <= _priceMax && p.stock > 0)
        .toList();

    setState(() {
      _filtered = result;
      _showSuggestions =
          !(hasText || hasSimpleCategory || hasAdvancedFilters);
    });
  }

  // Buscar por nombre (Enter/botón/recientes/tendencias)
  void _submitSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe algo para buscar')),
      );
      return;
    }
    // Si busco por texto, deselecciono categoría de los chips superiores
    _selectedCategory = null;

    if (!_recent.contains(query)) {
      _recent.insert(0, query);
      if (_recent.length > 6) _recent.removeLast();
    }
    _focus.unfocus();
    _applyFilters();
  }

  // Cambiar texto (live mode a partir de 2 letras)
  void _onTextChanged(String t) {
    if (t.trim().isEmpty) {
      if (_selectedCategory == null) {
        setState(() => _showSuggestions = true);
      } else {
        _applyFilters();
      }
      return;
    }
    if (t.trim().length < 2) {
      setState(() => _showSuggestions = true);
      return;
    }
    _selectedCategory = null;
    _applyFilters();
  }

  // Limpiar texto
  void _clearSearch() {
    _controller.clear();
    setState(() {
      if (_selectedCategory == null) {
        _showSuggestions = true;
        _filtered = [];
      } else {
        _applyFilters();
      }
    });
    _focus.requestFocus();
  }

  // Click en chip categoría (UI superior)
  void _toggleCategory(String c) {
    setState(() {
      if (_selectedCategory?.toLowerCase() == c.toLowerCase()) {
        _selectedCategory = null; // deseleccionar
      } else {
        _selectedCategory = c;
      }
      _controller.clear();
    });
    _applyFilters();
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => _FiltersSheet(
        initialPriceMax: _priceMax,
        initialSelectedCategories: _selectedCategories.toSet(),
        initialSelectedColors: _selectedColors.toSet(),
        initialSelectedFlowerTypes: _selectedFlowerTypes.toSet(),
        initialSelectedAccessories: _selectedAccessories.toSet(),
        initialSelectedOcasiones: _selectedOcasiones.toSet(),
        initialSelectedEstados: _selectedEstados.toSet(),
        availableCategories: _availableCategoriesFacet.toSet(),
        availableColors: _availableColors.toSet(),
        availableFlowerTypes: _availableFlowerTypes.toSet(),
        availableAccessories: _availableAccessories.toSet(),
        availableOcasiones: _availableOcasiones.toSet(),
        availableEstados: _availableEstados.toSet(),
        onApply: (
          priceMax,
          selectedCategories,
          selectedColors,
          selectedFlowerTypes,
          selectedAccessories,
          selectedOcasiones,
          selectedEstados,
        ) {
          setState(() {
            _priceMax = priceMax;
            _selectedCategories = selectedCategories;
            _selectedColors = selectedColors;
            _selectedFlowerTypes = selectedFlowerTypes;
            _selectedAccessories = selectedAccessories;
            _selectedOcasiones = selectedOcasiones;
            _selectedEstados = selectedEstados;
          });
          _applyFilters();
          Navigator.pop(ctx);
        },
        onClearFilters: () {
          setState(() {
            _priceMax = 150;
            _selectedCategories = {};
            _selectedColors = {};
            _selectedFlowerTypes = {};
            _selectedAccessories = {};
            _selectedOcasiones = {};
            _selectedEstados = {};
          });
          _applyFilters();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // ----------------- UI -----------------

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buscar'),
        ),
        body: SafeArea(
          child: _loadingAll
              ? const _InitialLoading()
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _loadAll)
                  : SingleChildScrollView(
                      padding:
                          const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SearchBar(
                            controller: _controller,
                            focusNode: _focus,
                            onSubmitted: _submitSearch,
                            onChanged: _onTextChanged,
                            onClear: _clearSearch,
                            onOpenFilters: _openFilters,
                          ),
                          const SizedBox(height: 16),
                          _SectionTitle('Categorías'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.map((c) {
                              final selected =
                                  _selectedCategory?.toLowerCase() ==
                                      c.toLowerCase();
                              return FilterChip(
                                label: Text(c),
                                selected: selected,
                                selectedColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                onSelected: (_) => _toggleCategory(c),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration:
                                const Duration(milliseconds: 220),
                            child: _showSuggestions
                                ? _Suggestions(
                                    trending: _trending,
                                    recent: _recent,
                                    onTapItem: (q) {
                                      _controller.text = q;
                                      _submitSearch(q);
                                    },
                                  )
                                : _ResultsList(
                                    query: (_selectedCategory !=
                                                    null &&
                                                _selectedCategory!
                                                    .isNotEmpty)
                                        ? _selectedCategory!
                                        : _controller.text.trim(),
                                    items: _filtered,
                                    onBackToSuggestions: () {
                                      setState(() {
                                        _selectedCategory = null;
                                        _controller.clear();
                                        _showSuggestions = true;
                                        _filtered = [];
                                      });
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onOpenFilters;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onChanged,
    required this.onClear,
    required this.onOpenFilters,
  });

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(Icons.search, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: widget.onSubmitted,
              onChanged: (value) {
                widget.onChanged(value);
                setState(() {}); // Actualizar botón limpiar
              },
              decoration: const InputDecoration(
                hintText: 'Busca ramos, plantas o regalos',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 0, vertical: 14),
              ),
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            IconButton(
              tooltip: 'Limpiar',
              onPressed: widget.onClear,
              icon: const Icon(Icons.close),
            ),
          IconButton(
            tooltip: 'Filtros',
            onPressed: widget.onOpenFilters,
            icon: const Icon(Icons.tune),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: .2,
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  final List<String> trending;
  final List<String> recent;
  final ValueChanged<String> onTapItem;

  const _Suggestions({
    required this.trending,
    required this.recent,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: const ValueKey('suggestions'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (recent.isNotEmpty) ...[
          _SectionTitle('Recientes'),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ..._intersperse(
                  const Divider(height: 1),
                  recent.map((r) => ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(r),
                        trailing: IconButton(
                          tooltip: 'Repetir búsqueda',
                          icon: const Icon(Icons.north_west),
                          onPressed: () => onTapItem(r),
                        ),
                        onTap: () => onTapItem(r),
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _SectionTitle('Tendencias'),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ..._intersperse(
                const Divider(height: 1),
                trending.map((t) => ListTile(
                      leading: const Icon(Icons.trending_up),
                      title: Text(t),
                      onTap: () => onTapItem(t),
                    )),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _intersperse(
      Widget separator, Iterable<Widget> children) {
    final list = <Widget>[];
    var i = 0;
    for (final child in children) {
      list.add(child);
      if (i != children.length - 1) list.add(separator);
      i++;
    }
    return list;
  }
}

// =================== RESULTADOS ===================

class _ResultsList extends StatelessWidget {
  final String query;
  final List<Product> items;
  final VoidCallback onBackToSuggestions;

  const _ResultsList({
    required this.query,
    required this.items,
    required this.onBackToSuggestions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Column(
        key: const ValueKey('results-empty'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle('Resultados'),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.search_off, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    'Sin resultados para “$query”',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: onBackToSuggestions,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver a sugerencias'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey('results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle('Resultados (${items.length})'),
        const SizedBox(height: 8),
        GridView.builder(
          padding: const EdgeInsets.only(top: 8),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 230,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (_, i) => _ProductCard(product: items[i]),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final img = (product.imagenes.isNotEmpty
            ? product.imagenes.first
            : '')
        .trim();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProductScreen(productId: product.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: img.isEmpty
                      ? Container(
                          color: theme
                              .colorScheme.surfaceVariant,
                          child: const Icon(Icons.local_florist,
                              size: 28),
                        )
                      : Image.network(
                          img,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(
                            color: theme
                                .colorScheme.surfaceVariant,
                            child: const Icon(
                                Icons.local_florist, size: 28),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  product.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '\$${product.precio.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color:
                        Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InitialLoading extends StatelessWidget {
  const _InitialLoading();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: const SizedBox(height: 72),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text('Ups…',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============== BOTTOM SHEET DE FILTROS ===============

class _FiltersSheet extends StatefulWidget {
  final double initialPriceMax;
  final Set<String> initialSelectedCategories;
  final Set<String> initialSelectedColors;
  final Set<String> initialSelectedFlowerTypes;
  final Set<String> initialSelectedAccessories;
  final Set<String> initialSelectedOcasiones;
  final Set<String> initialSelectedEstados;

  final Set<String> availableCategories;
  final Set<String> availableColors;
  final Set<String> availableFlowerTypes;
  final Set<String> availableAccessories;
  final Set<String> availableOcasiones;
  final Set<String> availableEstados;

  final Function(
    double priceMax,
    Set<String> selectedCategories,
    Set<String> selectedColors,
    Set<String> selectedFlowerTypes,
    Set<String> selectedAccessories,
    Set<String> selectedOcasiones,
    Set<String> selectedEstados,
  ) onApply;

  final VoidCallback onClearFilters;

  const _FiltersSheet({
    required this.initialPriceMax,
    required this.initialSelectedCategories,
    required this.initialSelectedColors,
    required this.initialSelectedFlowerTypes,
    required this.initialSelectedAccessories,
    required this.initialSelectedOcasiones,
    required this.initialSelectedEstados,
    required this.availableCategories,
    required this.availableColors,
    required this.availableFlowerTypes,
    required this.availableAccessories,
    required this.availableOcasiones,
    required this.availableEstados,
    required this.onApply,
    required this.onClearFilters,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late double _tempPrice;
  late Set<String> _tempSelectedCategories;
  late Set<String> _tempSelectedColors;
  late Set<String> _tempSelectedFlowerTypes;
  late Set<String> _tempSelectedAccessories;
  late Set<String> _tempSelectedOcasiones;
  late Set<String> _tempSelectedEstados;

  @override
  void initState() {
    super.initState();
    _tempPrice = widget.initialPriceMax;
    _tempSelectedCategories =
        widget.initialSelectedCategories.toSet();
    _tempSelectedColors = widget.initialSelectedColors.toSet();
    _tempSelectedFlowerTypes =
        widget.initialSelectedFlowerTypes.toSet();
    _tempSelectedAccessories =
        widget.initialSelectedAccessories.toSet();
    _tempSelectedOcasiones =
        widget.initialSelectedOcasiones.toSet();
    _tempSelectedEstados =
        widget.initialSelectedEstados.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cats = widget.availableCategories.toList()..sort();
    final colors = widget.availableColors.toList()..sort();
    final flowers = widget.availableFlowerTypes.toList()..sort();
    final accessories = widget.availableAccessories.toList()..sort();
    final ocasiones = widget.availableOcasiones.toList()..sort();
    final estados = widget.availableEstados.toList()..sort();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 12,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filtros avanzados',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),

            // Precio máximo
            Row(
              children: [
                const Icon(Icons.attach_money),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Precio máximo: \$${_tempPrice.toStringAsFixed(0)}'),
                      Slider(
                        value: _tempPrice,
                        min: 10,
                        max: 200,
                        divisions: 19,
                        label:
                            '\$${_tempPrice.toStringAsFixed(0)}',
                        onChanged: (v) =>
                            setState(() => _tempPrice = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Categorías
            if (cats.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.category_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text('Categorías'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: cats.map((cat) {
                            final selected =
                                _tempSelectedCategories
                                    .contains(cat);
                            return FilterChip(
                              label: Text(cat),
                              selected: selected,
                              onSelected: (sel) {
                                setState(() {
                                  if (sel) {
                                    _tempSelectedCategories
                                        .add(cat);
                                  } else {
                                    _tempSelectedCategories
                                        .remove(cat);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Colores
            if (colors.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.palette_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text('Colores del ramo'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: colors.map((c) {
                            final selected =
                                _tempSelectedColors.contains(c);
                            return FilterChip(
                              label: Text(c),
                              selected: selected,
                              onSelected: (sel) {
                                setState(() {
                                  if (sel) {
                                    _tempSelectedColors.add(c);
                                  } else {
                                    _tempSelectedColors.remove(c);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Tipos de flor
            if (flowers.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.local_florist_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text('Tipos de flor'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: flowers.map((f) {
                            final selected =
                                _tempSelectedFlowerTypes
                                    .contains(f);
                            return FilterChip(
                              label: Text(f),
                              selected: selected,
                              onSelected: (sel) {
                                setState(() {
                                  if (sel) {
                                    _tempSelectedFlowerTypes
                                        .add(f);
                                  } else {
                                    _tempSelectedFlowerTypes
                                        .remove(f);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Accesorios
            if (accessories.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.card_giftcard_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text('Accesorios incluidos'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: accessories.map((a) {
                            final selected =
                                _tempSelectedAccessories
                                    .contains(a);
                            return FilterChip(
                              label: Text(a),
                              selected: selected,
                              onSelected: (sel) {
                                setState(() {
                                  if (sel) {
                                    _tempSelectedAccessories
                                        .add(a);
                                  } else {
                                    _tempSelectedAccessories
                                        .remove(a);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Ocasiones
            if (ocasiones.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.event_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text('Ocasiones sugeridas'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ocasiones.map((o) {
                            final selected =
                                _tempSelectedOcasiones
                                    .contains(o);
                            return FilterChip(
                              label: Text(o),
                              selected: selected,
                              onSelected: (sel) {
                                setState(() {
                                  if (sel) {
                                    _tempSelectedOcasiones
                                        .add(o);
                                  } else {
                                    _tempSelectedOcasiones
                                        .remove(o);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // // Estado
            // if (estados.isNotEmpty) ...[
            //   Row(
            //     children: [
            //       const Icon(Icons.info_outline),
            //       const SizedBox(width: 8),
            //       Expanded(
            //         child: Column(
            //           crossAxisAlignment:
            //               CrossAxisAlignment.start,
            //           children: [
            //             const Text('Estado del producto'),
            //             const SizedBox(height: 8),
            //             Wrap(
            //               spacing: 8,
            //               runSpacing: 8,
            //               children: estados.map((e) {
            //                 final selected =
            //                     _tempSelectedEstados
            //                         .contains(e);
            //                 return FilterChip(
            //                   label: Text(e),
            //                   selected: selected,
            //                   onSelected: (sel) {
            //                     setState(() {
            //                       if (sel) {
            //                         _tempSelectedEstados
            //                             .add(e);
            //                       } else {
            //                         _tempSelectedEstados
            //                             .remove(e);
            //                       }
            //                     });
            //                   },
            //                 );
            //               }).toList(),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            //   const SizedBox(height: 16),
            // ],

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      widget.onApply(
                        _tempPrice,
                        _tempSelectedCategories,
                        _tempSelectedColors,
                        _tempSelectedFlowerTypes,
                        _tempSelectedAccessories,
                        _tempSelectedOcasiones,
                        _tempSelectedEstados,
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Botón limpiar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onClearFilters,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Limpiar filtros'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
