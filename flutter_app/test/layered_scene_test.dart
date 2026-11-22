import 'dart:ui' as ui;

import 'package:attention_detector/app/game_app.dart';
import 'package:attention_detector/screens/home_screen.dart';
import 'package:attention_detector/widgets/game_ui.dart';
import 'package:attention_detector/widgets/layered_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/game_fixtures.dart';

void main() {
  test('миниатюра поляны обновляется, остальные темы не подменяются', () {
    expect(worldPreviewAsset('world_meadow', 'assets/bg/home.webp'), 'assets/bg/meadow_landscape.webp');
    expect(worldPreviewAsset('world_cosmos', 'assets/bg/cosmic.webp'), 'assets/bg/cosmic.webp');
  });

  for (final scene in <({Widget widget, String portrait, String landscape})>[
    (
      widget: const LayeredScene.meadow(),
      portrait: 'assets/bg/meadow_portrait.webp',
      landscape: 'assets/bg/meadow_landscape.webp',
    ),
    (
      widget: const LayeredScene.summon(),
      portrait: 'assets/bg/summon_portrait.webp',
      landscape: 'assets/bg/summon_landscape.webp',
    ),
  ]) {
    testWidgets('фон ${scene.portrait} выбирается по ориентации', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: scene.widget)));
      expect(tester.widget<SceneBackground>(find.byType(SceneBackground)).asset, scene.portrait);

      await tester.binding.setSurfaceSize(const Size(844, 390));
      await tester.pump();
      expect(tester.widget<SceneBackground>(find.byType(SceneBackground)).asset, scene.landscape);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('декоративные планы не блокируют нажатия', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: ElevatedButton(onPressed: () => taps++, child: const Text('Проверка'))),
            const LayeredScene.meadow(),
            const MeadowForeground(),
            const SummonStageCrystals(),
          ],
        ),
      ),
    ));
    await tester.tap(find.text('Проверка'));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('остров движется, а при reduced motion и TickerMode замирает', (tester) async {
    Widget view({required bool reduced, required bool enabled}) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: TickerMode(
              enabled: enabled,
              child: const Scaffold(body: LayeredScene.meadow()),
            ),
          ),
        );

    final island = find.byKey(const ValueKey('meadow-floating-island'));
    await tester.pumpWidget(view(reduced: false, enabled: true));
    await tester.pump();
    final start = tester.getTopLeft(island).dy;
    await tester.pump(const Duration(seconds: 1));
    expect((tester.getTopLeft(island).dy - start).abs(), greaterThan(1));

    await tester.pumpWidget(view(reduced: true, enabled: true));
    final reducedPosition = tester.getTopLeft(island).dy;
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getTopLeft(island).dy, closeTo(reducedPosition, 0.001));

    await tester.pumpWidget(view(reduced: false, enabled: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(view(reduced: false, enabled: false));
    final hiddenPosition = tester.getTopLeft(island).dy;
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getTopLeft(island).dy, closeTo(hiddenPosition, 0.001));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final theme in <String, String>{
    'world_cosmos': 'assets/bg/cosmic.webp',
    'world_summon': 'assets/bg/summon.webp',
    'world_collection': 'assets/bg/collection.webp',
  }.entries) {
    testWidgets('выбранный мир ${theme.key} не заменяется поляной', (tester) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = makeController(worldTheme: theme.key);
      await tester.pumpWidget(GameScope(controller: controller, child: const MaterialApp(home: HomeScreen())));
      expect(tester.widget<SceneBackground>(find.byType(SceneBackground)).asset, theme.value);
      expect(find.byType(MeadowForeground), findsNothing);
      expect(find.byKey(const ValueKey('meadow-floating-island')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }

  testWidgets('поглаживание питомца проходит сквозь растения', (tester) async {
    final controller = makeController();
    await tester.pumpWidget(GameScope(
      controller: controller,
      child: MaterialApp(
        home: Scaffold(body: Center(child: SizedBox(width: 280, height: 280, child: PetStage(state: controller.state!, compact: false)))),
      ),
    ));
    await tester.pump();
    final plants = find.descendant(of: find.byType(MeadowForeground), matching: find.byType(Image)).first;
    await tester.tapAt(tester.getCenter(plants));
    await tester.pump();
    expect(controller.offlinePats, 1);
    await tester.pump(const Duration(milliseconds: 750));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  test('иллюстрации включены в пакет, у декоративных слоёв есть прозрачность', () async {
    for (final asset in [
      'assets/bg/meadow_landscape.webp',
      'assets/bg/meadow_portrait.webp',
      'assets/bg/summon_landscape.webp',
      'assets/bg/summon_portrait.webp',
    ]) {
      expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(1000), reason: asset);
    }
    for (final asset in [
      'assets/layers/floating_island.png',
      'assets/layers/meadow_foreground.png',
      'assets/layers/summon_crystals.png',
    ]) {
      final bytes = await rootBundle.load(asset);
      final image = await ui.decodeImageFromList(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
      final pixels = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      var transparent = false;
      var opaque = false;
      for (var i = 3; i < pixels.lengthInBytes; i += 4) {
        final alpha = pixels.getUint8(i);
        transparent = transparent || alpha == 0;
        opaque = opaque || alpha == 255;
        if (transparent && opaque) break;
      }
      image.dispose();
      expect(transparent && opaque, isTrue, reason: asset);
    }
  });
}
