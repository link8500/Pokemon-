import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemon/controllers/pokedex_controller.dart';
import 'package:pokemon/screens/pokedex_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_repository.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Outfit')
      ..addFont(rootBundle.load('assets/fonts/Outfit.ttf'));
    await loader.load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('catalog fits a $width pixel screen', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = PokedexController(repository: FakeRepository());
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Outfit'),
          home: PokedexScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Descubre Pokémon'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('typing dito presents Ditto and a correction', (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = PokedexController(repository: FakeRepository());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Outfit'),
        home: PokedexScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'dito');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Ditto'), findsOneWidget);
    expect(
      find.textContaining('¿Buscabas', findRichText: true),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
