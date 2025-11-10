import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/screens/product_screen.dart';


// MODELO + SERVICIO
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

    List<Product> result = _all;

    if (hasText) {
      final q = _norm(text);
      result = result.where((p) => _norm(p.nombre).contains(q)).toList();
    } else if (hasCategory) {
      final cat = _norm(_selectedCategory);
      result = result.where((p) => _norm(p.categoria) == cat).toList();
    } else {
      result = [];
    }

    setState(() {
      _filtered = result;
      _showSuggestions = !(hasText || hasCategory);
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
      builder: (ctx) => const _FiltersSheet(),
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
          actions: [
            IconButton(
              tooltip: 'Filtros',
              onPressed: _openFilters,
              icon: const Icon(Icons.tune),
            ),
          ],
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

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Busca ramos, plantas o regalos',
          prefixIcon: const Icon(Icons.search, color: kFucsia),
          suffixIcon: controller.text.isEmpty
              ? IconButton(
                  tooltip: 'Filtros',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Abre el botón de filtros arriba (UI demo)')),
                  ),
                  icon: const Icon(Icons.tune),
                )
              : IconButton(
                  tooltip: 'Limpiar',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
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
                  style: const TextStyle(fontWeight: FontWeight.w800, color: kFucsia),
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

class _FiltersSheet extends StatelessWidget {
  const _FiltersSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double price = 35;

    return StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filtros', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.local_florist_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    value: 'Ramos',
                    items: const [
                      DropdownMenuItem(value: 'Ramos', child: Text('Ramos')),
                      DropdownMenuItem(value: 'Plantas', child: Text('Plantas')),
                      DropdownMenuItem(value: 'Regalos', child: Text('Regalos')),
                    ],
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.attach_money),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Precio máximo'),
                      Slider(
                        value: price,
                        min: 10,
                        max: 150,
                        divisions: 14,
                        label: '\$${price.toStringAsFixed(0)}',
                        onChanged: (v) => setState(() => price = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filtros aplicados (UI demo)')),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
