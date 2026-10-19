import 'package:flutter/material.dart';
import '../controllers/pokedex_controller.dart';
import '../models/pokemon.dart';
import '../widgets/pokemon_widgets.dart';

Future<void> showPokemonDetail(
  BuildContext context,
  Pokemon pokemon,
  PokedexController controller,
) => showDialog<void>(
  context: context,
  builder: (_) => PokemonDetail(pokemon: pokemon, controller: controller),
);

class PokemonDetail extends StatefulWidget {
  const PokemonDetail({
    super.key,
    required this.pokemon,
    required this.controller,
  });
  final Pokemon pokemon;
  final PokedexController controller;
  @override
  State<PokemonDetail> createState() => _PokemonDetailState();
}

class _PokemonDetailState extends State<PokemonDetail> {
  bool _shiny = false;
  late Future<String> _description;
  @override
  void initState() {
    super.initState();
    _description = widget.controller.repository.fetchDescription(
      widget.pokemon.speciesUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pokemon;
    final style = typeStyle(p.types.first);
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 255,
                color: style.background,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Center(
                        child: Pokeball(
                          size: 210,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: PokemonArtwork(
                          url: _shiny ? p.shinyImage : p.image,
                          name:
                              '${p.displayName}${_shiny ? ' variocolor' : ''}',
                          size: 225,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      top: 22,
                      child: Text(
                        p.number,
                        style: TextStyle(
                          fontSize: 18,
                          color: style.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: IconButton.filledTonal(
                        tooltip: 'Cerrar ficha',
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.8),
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                    if (p.shinyImage != null)
                      Positioned(
                        right: 13,
                        bottom: 12,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.85,
                            ),
                            foregroundColor: style.color,
                          ),
                          onPressed: () => setState(() => _shiny = !_shiny),
                          icon: Icon(
                            _shiny
                                ? Icons.auto_awesome
                                : Icons.auto_awesome_outlined,
                            size: 17,
                          ),
                          label: Text(
                            _shiny ? 'Ver original' : 'Ver variocolor',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.displayName,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ListenableBuilder(
                          listenable: widget.controller,
                          builder: (context, _) {
                            final favorite = widget.controller.favorites
                                .contains(p.id);
                            return IconButton(
                              tooltip: favorite
                                  ? 'Quitar de favoritos'
                                  : 'Guardar en favoritos',
                              onPressed: () =>
                                  widget.controller.toggleFavorite(p.id),
                              icon: Icon(
                                favorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: const Color(0xFFED4B4E),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: p.types.map(TypeBadge.new).toList(),
                    ),
                    const SizedBox(height: 18),
                    FutureBuilder<String>(
                      future: _description,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'No se pudo cargar la descripción.',
                                  style: TextStyle(color: Color(0xFF737D8C)),
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(
                                  () => _description = widget
                                      .controller
                                      .repository
                                      .fetchDescription(p.speciesUrl),
                                ),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          );
                        }
                        return Text(
                          snapshot.data ??
                              'Buscando información en la Pokédex…',
                          style: const TextStyle(
                            color: Color(0xFF737D8C),
                            height: 1.6,
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _measurement(
                            Icons.height_rounded,
                            '${p.height.toStringAsFixed(1)} m',
                            'Altura',
                          ),
                          _measurement(
                            Icons.monitor_weight_outlined,
                            '${p.weight.toStringAsFixed(1)} kg',
                            'Peso',
                          ),
                          _measurement(
                            Icons.public_rounded,
                            generationFor(p.id) == 0
                                ? 'Especial'
                                : 'Gen. ${generationFor(p.id)}',
                            'Generación',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Estadísticas base',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...p.stats.entries.map(
                      (stat) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 98,
                              child: Text(
                                _statNames[stat.key] ?? stat.key,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF737D8C),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 33,
                              child: Text(
                                '${stat.value}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: LinearProgressIndicator(
                                  value: (stat.value / 255).clamp(0.0, 1.0),
                                  minHeight: 7,
                                  color: style.color,
                                  backgroundColor: style.background,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Habilidades',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.abilities
                          .map(
                            (a) => Chip(
                              label: Text(
                                prettyName(a),
                                style: const TextStyle(fontSize: 12),
                              ),
                              side: const BorderSide(color: Color(0xFFE8EBEF)),
                              backgroundColor: Colors.white,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Datos e ilustraciones de PokéAPI',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9AA2AD)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _measurement(IconData icon, String value, String label) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFF9AA2AD), size: 19),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9AA2AD)),
        ),
      ],
    ),
  );
}

const _statNames = {
  'hp': 'PS',
  'attack': 'Ataque',
  'defense': 'Defensa',
  'special-attack': 'Ataque esp.',
  'special-defense': 'Defensa esp.',
  'speed': 'Velocidad',
};
