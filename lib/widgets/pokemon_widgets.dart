import 'package:flutter/material.dart';
import '../models/pokemon.dart';

typedef TypeStyle = ({
  String name,
  Color color,
  Color background,
  IconData icon,
});

const pokemonTypes = <String, TypeStyle>{
  'grass': (
    name: 'Planta',
    color: Color(0xFF438E65),
    background: Color(0xFFE7F4EA),
    icon: Icons.eco_rounded,
  ),
  'fire': (
    name: 'Fuego',
    color: Color(0xFFD87543),
    background: Color(0xFFFFEDE4),
    icon: Icons.local_fire_department_rounded,
  ),
  'water': (
    name: 'Agua',
    color: Color(0xFF4F87C8),
    background: Color(0xFFE7F1FC),
    icon: Icons.water_drop_rounded,
  ),
  'electric': (
    name: 'Eléctrico',
    color: Color(0xFFAD861C),
    background: Color(0xFFFFF6D9),
    icon: Icons.bolt_rounded,
  ),
  'psychic': (
    name: 'Psíquico',
    color: Color(0xFFD36691),
    background: Color(0xFFFCEBF2),
    icon: Icons.auto_awesome_rounded,
  ),
  'ghost': (
    name: 'Fantasma',
    color: Color(0xFF8273B3),
    background: Color(0xFFEFECF8),
    icon: Icons.nightlight_round,
  ),
  'normal': (
    name: 'Normal',
    color: Color(0xFF80828E),
    background: Color(0xFFEEEFF2),
    icon: Icons.circle_outlined,
  ),
  'poison': (
    name: 'Veneno',
    color: Color(0xFF9B65B0),
    background: Color(0xFFF2E9F7),
    icon: Icons.science_rounded,
  ),
  'bug': (
    name: 'Bicho',
    color: Color(0xFF889D3D),
    background: Color(0xFFF0F4E3),
    icon: Icons.bug_report_rounded,
  ),
  'flying': (
    name: 'Volador',
    color: Color(0xFF838CC5),
    background: Color(0xFFEEEFFB),
    icon: Icons.air_rounded,
  ),
  'ground': (
    name: 'Tierra',
    color: Color(0xFFB38B53),
    background: Color(0xFFF6EEDD),
    icon: Icons.landscape_rounded,
  ),
  'fairy': (
    name: 'Hada',
    color: Color(0xFFCA81B3),
    background: Color(0xFFFBEAF5),
    icon: Icons.star_rounded,
  ),
  'fighting': (
    name: 'Lucha',
    color: Color(0xFFB7615C),
    background: Color(0xFFF7E8E6),
    icon: Icons.sports_mma_rounded,
  ),
  'rock': (
    name: 'Roca',
    color: Color(0xFFA29159),
    background: Color(0xFFF2EEDF),
    icon: Icons.terrain_rounded,
  ),
  'steel': (
    name: 'Acero',
    color: Color(0xFF748F9B),
    background: Color(0xFFE8F0F3),
    icon: Icons.shield_rounded,
  ),
  'ice': (
    name: 'Hielo',
    color: Color(0xFF4D9BA8),
    background: Color(0xFFE5F6F7),
    icon: Icons.ac_unit_rounded,
  ),
  'dragon': (
    name: 'Dragón',
    color: Color(0xFF6F6DB9),
    background: Color(0xFFECEBFA),
    icon: Icons.whatshot_rounded,
  ),
  'dark': (
    name: 'Siniestro',
    color: Color(0xFF6C6578),
    background: Color(0xFFEDEBF0),
    icon: Icons.dark_mode_rounded,
  ),
};

TypeStyle typeStyle(String type) =>
    pokemonTypes[type] ?? pokemonTypes['normal']!;

class Pokeball extends StatelessWidget {
  const Pokeball({
    super.key,
    this.size = 34,
    this.color = const Color(0xFFED4B4E),
  });
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _PokeballPainter(color));
}

class _PokeballPainter extends CustomPainter {
  _PokeballPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..color = color;
    canvas.drawCircle(center, radius, paint);
    paint
      ..color = Colors.white
      ..strokeWidth = size.width * 0.10;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);
    canvas.drawCircle(center, radius * 0.32, paint);
    paint.color = color;
    canvas.drawCircle(center, radius * 0.18, paint);
  }

  @override
  bool shouldRepaint(covariant _PokeballPainter oldDelegate) =>
      oldDelegate.color != color;
}

class TypeBadge extends StatelessWidget {
  const TypeBadge(this.type, {super.key});
  final String type;
  @override
  Widget build(BuildContext context) {
    final style = typeStyle(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 13, color: style.color),
          const SizedBox(width: 4),
          Text(
            style.name,
            style: TextStyle(
              color: style.color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class PokemonArtwork extends StatelessWidget {
  const PokemonArtwork({
    super.key,
    required this.url,
    required this.name,
    this.size = 160,
  });
  final String? url;
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) {
    Widget fallback() => SizedBox.square(
      dimension: size,
      child: Center(
        child: Icon(
          Icons.catching_pokemon,
          size: size * 0.35,
          color: const Color(0xFFB4BAC2),
        ),
      ),
    );
    if (url == null) return fallback();
    return Image.network(
      url!,
      height: size,
      width: size,
      fit: BoxFit.contain,
      semanticLabel: name,
      errorBuilder: (_, _, _) => fallback(),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback(),
    );
  }
}

class PokemonCard extends StatefulWidget {
  const PokemonCard({
    super.key,
    required this.pokemon,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
  });
  final Pokemon pokemon;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;
  @override
  State<PokemonCard> createState() => _PokemonCardState();
}

class _PokemonCardState extends State<PokemonCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final p = widget.pokemon;
    final style = typeStyle(p.types.first);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? style.color.withValues(alpha: 0.5)
                : const Color(0xFFE9EBEF),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.06 : 0.015),
              blurRadius: _hovered ? 24 : 5,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: style.background.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Center(
                            child: Pokeball(
                              size: 136,
                              color: Colors.white.withValues(alpha: 0.48),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                            child: AnimatedScale(
                              scale: _hovered ? 1.07 : 1,
                              duration: const Duration(milliseconds: 220),
                              child: PokemonArtwork(
                                url: p.thumbnail ?? p.image,
                                name: p.displayName,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          top: 12,
                          child: Text(
                            p.number,
                            style: TextStyle(
                              color: style.color.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 3,
                          top: 3,
                          child: IconButton(
                            tooltip: widget.favorite
                                ? 'Quitar ${p.displayName} de favoritos'
                                : 'Guardar ${p.displayName} en favoritos',
                            onPressed: widget.onFavorite,
                            icon: Icon(
                              widget.favorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 19,
                              color: widget.favorite
                                  ? const Color(0xFFED4B4E)
                                  : const Color(0xFF949DA5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 5, 17, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_outward_rounded,
                            size: 16,
                            color: Color(0xFFB6BCC4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: p.types.map(TypeBadge.new).toList(),
                      ),
                    ],
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

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE9EBEF)),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Pokeball(size: 70, color: Color(0xFFE5E8ED)),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          width: 100,
          height: 17,
          margin: const EdgeInsets.only(left: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 65,
          height: 22,
          margin: const EdgeInsets.only(left: 9, bottom: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    ),
  );
}
