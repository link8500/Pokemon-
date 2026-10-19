import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokemon/controllers/pokedex_controller.dart';
import 'support/fake_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PokedexController controller;
  late FakeRepository repository;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = FakeRepository();
    controller = PokedexController(repository: repository);
  });
  tearDown(() => controller.dispose());

  test('loads API results and combines type and generation filters', () async {
    await controller.initialize();
    expect(controller.visible, hasLength(4));
    await controller.setType('electric');
    expect(controller.visible.map((p) => p.id), [25, 172]);
    await controller.setGeneration(1);
    expect(controller.visible.single.id, 25);
    await controller.setGeneration(2);
    expect(controller.visible.single.id, 172);
  });
  test('search corrects dito using the complete index', () async {
    await controller.initialize();
    controller.search('dito', immediately: true);
    await Future<void>.delayed(Duration.zero);
    expect(controller.visible.single.name, 'ditto');
    expect(controller.correction, 'Ditto');
  });
  test('favorites persist and are available after reopening', () async {
    await controller.initialize();
    await controller.toggleFavorite(132);
    final reopened = PokedexController(repository: FakeRepository());
    addTearDown(reopened.dispose);
    await reopened.initialize();
    await reopened.showFavorites(true);
    expect(reopened.visible.single.id, 132);
    await reopened.toggleFavorite(132);
    expect(reopened.visible, isEmpty);
  });
  test('network failure is recoverable', () async {
    repository.fail = true;
    await controller.initialize();
    expect(controller.error, contains('PokéAPI'));
    expect(controller.loading, isFalse);
    repository.fail = false;
    await controller.initialize();
    expect(controller.error, isNull);
    expect(controller.visible, hasLength(4));
  });
  test('sort and reset restore a usable catalog', () async {
    await controller.initialize();
    await controller.setSort(PokemonSort.numberDescending);
    expect(controller.visible.first.id, 172);
    await controller.setType('normal');
    await controller.reset();
    expect(controller.visible.first.id, 1);
    expect(controller.visible, hasLength(4));
  });
}
