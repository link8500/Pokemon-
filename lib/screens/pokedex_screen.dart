import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controllers/pokedex_controller.dart';
import '../models/pokemon.dart';
import '../widgets/pokemon_widgets.dart';
import 'pokemon_detail.dart';

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key, this.controller});
  final PokedexController? controller;
  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  late final PokedexController _controller;
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _typeScroll = ScrollController();
  final _searchFocus = FocusNode();
  final _catalogKey = GlobalKey();
  bool _randomLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PokedexController();
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _search.dispose();
    _scroll.dispose();
    _typeScroll.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _reset() {
    _search.clear();
    unawaited(_controller.reset());
  }

  Future<void> _randomPokemon() async {
    if (_randomLoading || _controller.index.isEmpty) return;
    setState(() => _randomLoading = true);
    try {
      final entry =
          _controller.index[Random().nextInt(_controller.index.length)];
      final pokemon = await _controller.repository.fetchPokemon(entry.id);
      if (mounted) await showPokemonDetail(context, pokemon, _controller);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _randomPokemon,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _randomLoading = false);
    }
  }

  Future<void> _page(int value) async {
    final pending = _controller.setPage(value);
    final target = _catalogKey.currentContext;
    if (target != null) {
      unawaited(
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        ),
      );
    }
    await pending;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) => Scaffold(
      body: SelectionArea(
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.sizeOf(context).width < 600
                          ? 20
                          : 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        _hero(),
                        const SizedBox(height: 32),
                        _searchBox(),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 15,
                              color: Color(0xFFED4B4E),
                            ),
                            SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                'Un pequeño error no detiene la aventura. Prueba «dito» o «pikchu».',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8B929D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _filters(),
                        const SizedBox(height: 30),
                        _catalogHeading(),
                        const SizedBox(height: 18),
                        if (_controller.correction != null &&
                            !_controller.loading &&
                            _controller.error == null)
                          _correction(),
                        _catalog(),
                        if (!_controller.loading &&
                            _controller.error == null &&
                            _controller.pages > 1)
                          _pagination(),
                        const SizedBox(height: 34),
                        _footer(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _header() => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFEAECF0))),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width < 600 ? 20 : 40,
            vertical: 17,
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  _controller.showFavorites(false);
                  _reset();
                },
                borderRadius: BorderRadius.circular(8),
                child: const Row(
                  children: [
                    Pokeball(size: 32),
                    SizedBox(width: 9),
                    Text(
                      'poké',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'dex',
                      style: TextStyle(
                        fontSize: 26,
                        color: Color(0xFFED4B4E),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _navButton(
                'Explorar',
                Icons.grid_view_rounded,
                !_controller.favoritesOnly,
                () => _controller.showFavorites(false),
              ),
              const SizedBox(width: 8),
              _navButton(
                'Favoritos',
                Icons.favorite_border_rounded,
                _controller.favoritesOnly,
                () => _controller.showFavorites(true),
                count: _controller.favorites.length,
              ),
              if (MediaQuery.sizeOf(context).width > 950) ...[
                const SizedBox(width: 32),
                const SizedBox(
                  height: 25,
                  child: VerticalDivider(color: Color(0xFFE4E7EB)),
                ),
                const SizedBox(width: 24),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF69AD88),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tu Pokédex personal',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8B929D)),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _navButton(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap, {
    int? count,
  }) {
    final compact = MediaQuery.sizeOf(context).width < 460;
    return Tooltip(
      message: label,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: selected
              ? const Color(0xFFED4B4E)
              : const Color(0xFF87909C),
          backgroundColor: selected
              ? const Color(0xFFFFF0F0)
              : Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 16,
            vertical: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17),
            if (!compact) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Text('$count', style: const TextStyle(fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hero() => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 750;
      final intro = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEEE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.explore_outlined,
                  color: Color(0xFFED4B4E),
                  size: 13,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'EXPLORA. DESCUBRE. ATRÁPALOS TODOS.',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFFDF5357),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Un mundo Pokémon.\n'),
                TextSpan(
                  text: 'Infinitas aventuras.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            style: TextStyle(
              fontSize: narrow ? 37 : 49,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.6,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Encuentra a tus favoritos, descubre sus habilidades\ny conoce cada detalle de tu próximo compañero.',
            style: TextStyle(
              color: Color(0xFF818996),
              fontSize: 14,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _heroMetric(
                _controller.total == 0
                    ? '1.025'
                    : _formatNumber(_controller.total),
                'Pokémon',
              ),
              Container(
                height: 25,
                width: 1,
                margin: EdgeInsets.symmetric(horizontal: narrow ? 13 : 22),
                color: const Color(0xFFDDE1E7),
              ),
              _heroMetric('9', 'generaciones'),
              Container(
                height: 25,
                width: 1,
                margin: EdgeInsets.symmetric(horizontal: narrow ? 13 : 22),
                color: const Color(0xFFDDE1E7),
              ),
              _heroMetric('18', 'tipos por explorar'),
            ],
          ),
        ],
      );
      final featured = _featured();
      if (narrow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [intro, const SizedBox(height: 26), featured],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 6, child: intro),
          const SizedBox(width: 25),
          Expanded(flex: 5, child: featured),
        ],
      );
    },
  );

  Widget _heroMetric(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.7,
        ),
      ),
      const SizedBox(height: 1),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF8B929D)),
      ),
    ],
  );

  Widget _featured() => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 410;
      final artworkSize = compact
          ? min(175.0, constraints.maxWidth * 0.48)
          : 215.0;
      return Container(
        height: 260,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2D8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF7E8C9)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const Positioned(
              right: -32,
              top: -40,
              child: Pokeball(size: 280, color: Color(0xFFFFE8B5)),
            ),
            Positioned(
              right: compact ? -8 : 7,
              bottom: 19,
              child: Transform.rotate(
                angle: -0.10,
                child: PokemonArtwork(
                  url: kIsWeb
                      ? Uri.base.resolve('lite/pikachu.webp').toString()
                      : 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png',
                  name: 'Pikachu',
                  size: artworkSize,
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 13,
                      color: Color(0xFFB58A24),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'UN CLÁSICO QUE ENAMORA',
                      style: TextStyle(
                        color: Color(0xFF9B7B35),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 76,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola,\nentrenador!',
                    style: TextStyle(
                      fontSize: compact
                          ? (constraints.maxWidth < 320 ? 22 : 26)
                          : 30,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                      color: Color(0xFF66502F),
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    'Tu próxima historia\nempieza con un Pokémon.',
                    style: TextStyle(
                      fontSize: compact ? 10 : 12,
                      color: Color(0xFFA48D67),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton.icon(
                    onPressed: _randomLoading || _controller.index.isEmpty
                        ? null
                        : _randomPokemon,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: const Color(0xFF806331),
                    ),
                    icon: Icon(
                      _randomLoading
                          ? Icons.hourglass_top_rounded
                          : Icons.shuffle_rounded,
                      size: 14,
                    ),
                    label: const Text(
                      'Sorpréndeme',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              right: 18,
              bottom: 11,
              child: Text(
                'PIKACHU  #025',
                style: TextStyle(
                  color: Color(0xFFAC925F),
                  fontSize: 9,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _searchBox() => Container(
    padding: const EdgeInsets.fromLTRB(18, 7, 7, 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E5EA)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.025),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        const Icon(Icons.search_rounded, size: 24, color: Color(0xFF9CA4AE)),
        const SizedBox(width: 13),
        Expanded(
          child: TextField(
            controller: _search,
            focusNode: _searchFocus,
            onChanged: _controller.search,
            onSubmitted: (value) =>
                _controller.search(value, immediately: true),
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: MediaQuery.sizeOf(context).width < 500
                  ? 'Nombre o número…'
                  : 'Busca un Pokémon por nombre o número…',
              hintStyle: const TextStyle(
                color: Color(0xFFA0A7B2),
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              suffixIcon: _controller.query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () {
                        _search.clear();
                        _controller.search('', immediately: true);
                        _searchFocus.requestFocus();
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () {
            _controller.search(_search.text, immediately: true);
            _searchFocus.unfocus();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_rounded, size: 17),
              if (MediaQuery.sizeOf(context).width >= 500) ...[
                const SizedBox(width: 7),
                const Text('Buscar'),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  Widget _filters() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'UN TIPO PARA CADA AVENTURA',
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8D95A1),
        ),
      ),
      const SizedBox(height: 13),
      SizedBox(
        height: 50,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: Scrollbar(
            controller: _typeScroll,
            thumbVisibility: true,
            interactive: true,
            thickness: 3,
            radius: const Radius.circular(4),
            child: ListView(
              controller: _typeScroll,
              padding: const EdgeInsets.only(bottom: 10),
              scrollDirection: Axis.horizontal,
              children: [
                _typeChip(null),
                for (final type in pokemonTypes.keys) _typeChip(type),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _typeChip(String? type) {
    final selected = _controller.selectedType == type;
    final style = type == null ? null : typeStyle(type);
    final color = selected
        ? (style?.color ?? const Color(0xFFED4B4E))
        : const Color(0xFF8B929D);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        onPressed: () => _controller.setType(type),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: selected
              ? (style?.background ?? const Color(0xFFFFEEEE))
              : Colors.white,
          side: BorderSide(
            color: selected
                ? color.withValues(alpha: 0.35)
                : const Color(0xFFE5E8ED),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        icon: Icon(style?.icon ?? Icons.apps_rounded, size: 15),
        label: Text(
          style?.name ?? 'Todos',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _catalogHeading() => LayoutBuilder(
    key: _catalogKey,
    builder: (context, constraints) {
      final title = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _controller.favoritesOnly ? 'Tus favoritos' : 'Descubre Pokémon',
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEBEEF2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _controller.loading ? '…' : '${_controller.matches.length}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF929AA6)),
            ),
          ),
        ],
      );
      final filters = Wrap(
        spacing: 9,
        runSpacing: 8,
        children: [
          _dropdown<int>(
            value: _controller.generation,
            icon: Icons.public_rounded,
            items: [
              for (var i = 0; i < generationNames.length; i++)
                DropdownMenuItem(value: i, child: Text(generationNames[i])),
            ],
            onChanged: (value) {
              if (value != null) _controller.setGeneration(value);
            },
          ),
          _dropdown<PokemonSort>(
            value: _controller.sort,
            icon: Icons.sort_rounded,
            items: const [
              DropdownMenuItem(
                value: PokemonSort.number,
                child: Text('Número ↑'),
              ),
              DropdownMenuItem(
                value: PokemonSort.numberDescending,
                child: Text('Número ↓'),
              ),
              DropdownMenuItem(
                value: PokemonSort.name,
                child: Text('Nombre A–Z'),
              ),
              DropdownMenuItem(
                value: PokemonSort.nameDescending,
                child: Text('Nombre Z–A'),
              ),
            ],
            onChanged: (value) {
              if (value != null) _controller.setSort(value);
            },
          ),
        ],
      );
      if (constraints.maxWidth < 750) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [title, const SizedBox(height: 16), filters],
        );
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [title, filters],
      );
    },
  );

  Widget _dropdown<T>({
    required T value,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) => Container(
    padding: const EdgeInsets.only(left: 10, right: 8),
    height: 37,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE5E8ED)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF919AA6)),
        const SizedBox(width: 7),
        DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            isDense: true,
            borderRadius: BorderRadius.circular(12),
            dropdownColor: Colors.white,
            icon: const Padding(
              padding: EdgeInsets.only(left: 10),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: Color(0xFF919AA6),
              ),
            ),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              color: Color(0xFF7D8795),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _correction() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF3FC),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFDAE5F7)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.auto_awesome_rounded,
          color: Color(0xFF6D8AB9),
          size: 19,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: '¿Buscabas '),
                TextSpan(
                  text: _controller.correction,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const TextSpan(
                  text: '? Estas son las coincidencias más cercanas.',
                ),
              ],
            ),
            style: const TextStyle(fontSize: 13, color: Color(0xFF627CA4)),
          ),
        ),
        TextButton(
          onPressed: () {
            _search.text = _controller.correction!;
            _controller.search(_search.text, immediately: true);
          },
          child: const Text('Ver', style: TextStyle(fontSize: 12)),
        ),
      ],
    ),
  );

  Widget _catalog() {
    if (_controller.error != null) {
      return _empty(
        Icons.wifi_off_rounded,
        'La aventura espera un momento',
        _controller.error!,
        'Volver a intentar',
        () => _controller.index.isEmpty
            ? _controller.initialize()
            : _controller.refresh(),
      );
    }
    if (!_controller.loading && _controller.visible.isEmpty) {
      final emptyFavorites =
          _controller.favoritesOnly && _controller.favorites.isEmpty;
      return _empty(
        emptyFavorites
            ? Icons.favorite_border_rounded
            : Icons.search_off_rounded,
        emptyFavorites
            ? 'Tu equipo empieza aquí'
            : 'No encontramos coincidencias',
        emptyFavorites
            ? 'Toca el corazón de un Pokémon para guardarlo aquí y tenerlo siempre a mano.'
            : 'Prueba otro nombre o número, o quita los filtros para ampliar tu búsqueda.',
        emptyFavorites ? 'Explorar Pokémon' : 'Limpiar filtros',
        () {
          if (emptyFavorites) _controller.showFavorites(false);
          _reset();
        },
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 700
            ? 3
            : constraints.maxWidth >= 330
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 18) / columns;
        final height = width < 190 ? 245.0 : 277.0;
        return Semantics(
          label: _controller.loading
              ? 'Cargando Pokémon'
              : 'Resultados de Pokémon',
          liveRegion: true,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              mainAxisExtent: height,
            ),
            itemCount: _controller.loading ? 12 : _controller.visible.length,
            itemBuilder: (context, index) {
              if (_controller.loading) return const SkeletonCard();
              final pokemon = _controller.visible[index];
              return PokemonCard(
                pokemon: pokemon,
                favorite: _controller.favorites.contains(pokemon.id),
                onFavorite: () => _controller.toggleFavorite(pokemon.id),
                onTap: () => showPokemonDetail(context, pokemon, _controller),
              );
            },
          ),
        );
      },
    );
  }

  Widget _empty(
    IconData icon,
    String title,
    String message,
    String button,
    VoidCallback onTap,
  ) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 55),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE8EBEF)),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Icon(icon, size: 45, color: const Color(0xFFEAA7A9)),
        const SizedBox(height: 17),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8B929D),
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 22),
        FilledButton(onPressed: onTap, child: Text(button)),
      ],
    ),
  );

  Widget _pagination() => Padding(
    padding: const EdgeInsets.only(top: 28),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final current = _controller.page;
        final pageNumbers = <int>{
          0,
          if (current > 1) current - 1,
          current,
          if (current + 1 < _controller.pages) current + 1,
          _controller.pages - 1,
        }.toList()..sort();
        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Página anterior',
              onPressed: current == 0 ? null : () => _page(current - 1),
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
            ),
            for (var i = 0; i < pageNumbers.length; i++) ...[
              if (i > 0 && pageNumbers[i] - pageNumbers[i - 1] > 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('…', style: TextStyle(color: Color(0xFF929BA7))),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SizedBox.square(
                  dimension: 34,
                  child: TextButton(
                    onPressed: () => _page(pageNumbers[i]),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: current == pageNumbers[i]
                          ? const Color(0xFFED4B4E)
                          : Colors.white,
                      foregroundColor: current == pageNumbers[i]
                          ? Colors.white
                          : const Color(0xFF8B929D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: Text(
                      '${pageNumbers[i] + 1}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
            IconButton(
              tooltip: 'Página siguiente',
              onPressed: current + 1 >= _controller.pages
                  ? null
                  : () => _page(current + 1),
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
            ),
          ],
        );
        final caption = Text(
          'Mostrando ${current * PokedexController.pageSize + 1}–${min((current + 1) * PokedexController.pageSize, _controller.matches.length)} de ${_formatNumber(_controller.matches.length)} Pokémon',
          style: const TextStyle(fontSize: 12, color: Color(0xFF929BA7)),
        );
        return constraints.maxWidth < 650
            ? Column(children: [controls, const SizedBox(height: 14), caption])
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [caption, controls],
              );
      },
    ),
  );

  Widget _footer() => Container(
    padding: const EdgeInsets.only(top: 22),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFFE5E8ED))),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 12,
      spacing: 28,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Pokeball(size: 17, color: Color(0xFFB5BDC8)),
            SizedBox(width: 8),
            Text(
              'Hecho con curiosidad. Impulsado por PokéAPI.',
              style: TextStyle(color: Color(0xFF9AA2AF), fontSize: 11),
            ),
          ],
        ),
        Text(
          'Pokémon y sus personajes pertenecen a Nintendo, Game Freak y Creatures.',
          style: TextStyle(
            color: const Color(0xFF9AA2AF),
            fontSize: MediaQuery.sizeOf(context).width < 500 ? 9 : 10,
          ),
        ),
      ],
    ),
  );
}

String _formatNumber(int value) => value.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]}.',
);
