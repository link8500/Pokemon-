import 'package:flutter/material.dart';
import 'screens/pokedex_screen.dart';
import 'widgets/resume_repaint_boundary.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The default cache can retain 100 MB of decoded images. Keep it bounded
  // when browsing many pages on memory-constrained phones.
  PaintingBinding.instance.imageCache
    ..maximumSize = 60
    ..maximumSizeBytes = 24 * 1024 * 1024;
  runApp(const PokedexApp());
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF242832);
    return MaterialApp(
      title: 'Pokédex · Encuentra tu próximo Pokémon',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => ResumeRepaintBoundary(child: child!),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Outfit',
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEF5350),
          primary: const Color(0xFFED4B4E),
          surface: Colors.white,
          onSurface: ink,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'Outfit',
          bodyColor: ink,
          displayColor: ink,
        ),
        tooltipTheme: const TooltipThemeData(
          waitDuration: Duration(milliseconds: 400),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
      home: const PokedexScreen(),
    );
  }
}
