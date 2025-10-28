import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  // Datos de demo (solo UI)
  final List<String> _categories = ['Ramos', 'Plantas', 'Regalos', 'Secos', 'Premium', 'Ofertas'];
  final List<String> _trending = ['Ramo primavera', 'Monstera', 'Rosas rojas', 'Suculentas', 'Girasoles'];
  final List<String> _recent = ['Ramo pastel', 'Orquídea blanca'];

  bool _showSuggestions = true;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submitSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe algo para buscar')),
      );
      return;
    }
    // Solo UI: feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Buscar: "$query" (UI demo)')),
    );
    setState(() {
      if (!_recent.contains(query)) {
        _recent.insert(0, query);
        if (_recent.length > 6) _recent.removeLast();
      }
      _showSuggestions = false;
      _focus.unfocus();
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _showSuggestions = true;
    });
    _focus.requestFocus();
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => const _FiltersSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barra de búsqueda
                _SearchBar(
                  controller: _controller,
                  focusNode: _focus,
                  onSubmitted: _submitSearch,
                  onChanged: (t) {
                    setState(() {
                      _showSuggestions = t.trim().isEmpty || t.trim().length < 2;
                    });
                  },
                  onClear: _clearSearch,
                ),
                const SizedBox(height: 16),

                // Chips de categorías
                _SectionTitle('Categorías'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((c) {
                    final selected = _controller.text.trim().toLowerCase() == c.toLowerCase();
                    return FilterChip(
                      label: Text(c),
                      selected: selected,
                      selectedColor: Theme.of(context).colorScheme.primaryContainer,
                      onSelected: (_) {
                        _controller.text = c;
                        _submitSearch(c);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Contenido dinámico: sugerencias / resultados placeholder
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
                      : _ResultsPlaceholder(
                          query: _controller.text.trim(),
                          onBackToSuggestions: () {
                            setState(() => _showSuggestions = true);
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
          prefixIcon: Icon(Icons.search, color: kFucsia),
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
        // Recientes
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

        // Tendencias
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

class _ResultsPlaceholder extends StatelessWidget {
  final String query;
  final VoidCallback onBackToSuggestions;

  const _ResultsPlaceholder({
    required this.query,
    required this.onBackToSuggestions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: const ValueKey('results'),
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
                Icon(Icons.search, size: 56, color: kFucsia),
                const SizedBox(height: 12),
                Text(
                  'Buscando “$query”…',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aquí aparecerán los resultados. Integra tu API cuando esté lista.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: onBackToSuggestions,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver a sugerencias'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Placeholder de tarjetas de producto (UI-only)
        GridView.builder(
          padding: const EdgeInsets.only(top: 8),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 200,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (_, i) => _ProductCardSkeleton(index: i),
        ),
      ],
    );
  }
}

class _ProductCardSkeleton extends StatelessWidget {
  final int index;
  const _ProductCardSkeleton({required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surfaceVariant.withOpacity(.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 12,
                width: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: theme.colorScheme.surfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 12,
                width: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: theme.colorScheme.surfaceVariant,
                ),
              ),
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
