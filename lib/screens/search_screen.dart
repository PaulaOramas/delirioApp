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

  // UI secundaria
  final List<String> _categories = ['Ramos', 'Plantas', 'Regalos', 'Secos', 'Premium', 'Ofertas'];
  final List<String> _trending = ['Ramo primavera', 'Monstera', 'Rosas rojas', 'Suculentas', 'Girasoles'];
  final List<String> _recent = ['Ramo pastel', 'Orquídea blanca'];

  // Datos reales
  List<Product> _all = [];
  List<Product> _filtered = [];
  bool _loadingAll = true;
  String? _error;

  // Estado de búsqueda/filtro
  bool _showSuggestions = true;
  String? _selectedCategory; // null = sin filtro por categoría
  
  // Filtros avanzados
  double _priceMax = 150;
  Set<String> _selectedCategories = {};

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
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los productos: $e';
        _loadingAll = false;
      });
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

  void _applyFilters() {
    final text = _controller.text.trim();
    final hasText = text.length >= 2;
    final hasCategory = (_selectedCategory != null && _selectedCategory!.isNotEmpty);
    final hasAdvancedFilters = _selectedCategories.isNotEmpty || _priceMax < 150;

    List<Product> result = _all;

    // Filtro por texto de búsqueda (prioridad)
    if (hasText) {
      final q = _norm(text);
      result = result.where((p) => _norm(p.nombre).contains(q)).toList();
    } else if (hasCategory) {
      // Filtro por categoría simple (chips)
      final cat = _norm(_selectedCategory);
      result = result.where((p) => _norm(p.categoria) == cat).toList();
    } else if (hasAdvancedFilters) {
      // Si no hay búsqueda de texto, aplicar filtros avanzados
      if (_selectedCategories.isNotEmpty) {
        result = result.where((p) => _selectedCategories.contains(_norm(p.categoria))).toList();
      }
    }
    
    // Siempre aplicar filtros de precio
    result = result.where((p) => p.precio <= _priceMax).toList();
    
    // Siempre filtrar solo productos disponibles (stock > 0)
    result = result.where((p) => p.stock > 0).toList();

    setState(() {
      _filtered = result;
      _showSuggestions = !(hasText || hasCategory || hasAdvancedFilters);
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
    // Si busco por texto, deselecciono categoría
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
      // Si no hay texto y no hay categoría -> sugerencias
      if (_selectedCategory == null) {
        setState(() => _showSuggestions = true);
      } else {
        _applyFilters(); // hay categoría activa
      }
      return;
    }
    if (t.trim().length < 2) {
      setState(() => _showSuggestions = true);
      return;
    }
    // Busco por texto; ignoro categoría
    _selectedCategory = null;
    _applyFilters();
  }

  // Limpiar texto
  void _clearSearch() {
    _controller.clear();
    // Si no hay categoría activa -> sugerencias
    setState(() {
      if (_selectedCategory == null) {
        _showSuggestions = true;
        _filtered = [];
      } else {
        // Mantener filtro de categoría
        _applyFilters();
      }
    });
    _focus.requestFocus();
  }

  // Click en chip categoría
  void _toggleCategory(String c) {
    setState(() {
      // Al elegir categoría, limpiar texto y forzar filtro por categoría
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
        onApply: (priceMax, selectedCategories) {
          setState(() {
            _priceMax = priceMax;
            _selectedCategories = selectedCategories;
          });
          _applyFilters();
          Navigator.pop(ctx);
        },
        onClearFilters: () {
          setState(() {
            _priceMax = 150;
            _selectedCategories = {};
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
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                              final selected = _selectedCategory?.toLowerCase() == c.toLowerCase();
                              return FilterChip(
                                label: Text(c),
                                selected: selected,
                                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                                onSelected: (_) => _toggleCategory(c),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
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
                                    query: (_selectedCategory != null && _selectedCategory!.isNotEmpty)
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
                setState(() {}); // Actualizar el estado del botón limpiar
              },
              decoration: const InputDecoration(
                hintText: 'Busca ramos, plantas o regalos',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 14),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  List<Widget> _intersperse(Widget separator, Iterable<Widget> children) {
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.search_off, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    'Sin resultados para “$query”',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    final img = (product.imagenes.isNotEmpty ? product.imagenes.first : '').trim();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductScreen(productId: product.id), // <-- usa el ID
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
                          color: theme.colorScheme.surfaceVariant,
                          child: const Icon(Icons.local_florist, size: 28),
                        )
                      : Image.network(
                          img,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: theme.colorScheme.surfaceVariant,
                            child: const Icon(Icons.local_florist, size: 28),
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
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '\$${product.precio.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text('Ups…', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
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

class _FiltersSheet extends StatefulWidget {
  final double initialPriceMax;
  final Set<String> initialSelectedCategories;
  final Function(double, Set<String>) onApply;
  final VoidCallback onClearFilters;

  const _FiltersSheet({
    required this.initialPriceMax,
    required this.initialSelectedCategories,
    required this.onApply,
    required this.onClearFilters,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late double _tempPrice;
  late Set<String> _tempSelectedCategories;

  @override
  void initState() {
    super.initState();
    _tempPrice = widget.initialPriceMax;
    _tempSelectedCategories = widget.initialSelectedCategories.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = {'Ramos', 'Plantas', 'Regalos'};

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Filtros avanzados', style: theme.textTheme.titleLarge),
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
                    Text('Precio máximo: \$${_tempPrice.toStringAsFixed(0)}'),
                    Slider(
                      value: _tempPrice,
                      min: 10,
                      max: 200,
                      divisions: 19,
                      label: '\$${_tempPrice.toStringAsFixed(0)}',
                      onChanged: (v) => setState(() => _tempPrice = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Categorías
          Row(
            children: [
              const Icon(Icons.local_florist_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Categorías'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final selected = _tempSelectedCategories.contains(cat);
                        return FilterChip(
                          label: Text(cat),
                          selected: selected,
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                _tempSelectedCategories.add(cat);
                              } else {
                                _tempSelectedCategories.remove(cat);
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
                    widget.onApply(_tempPrice, _tempSelectedCategories);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Aplicar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Botón para limpiar filtros
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
    );
  }
}
