import 'package:attention_detector/app/game_app.dart';
import 'package:attention_detector/screens/home_screen.dart';
import 'package:attention_detector/widgets/ambient_effects.dart';
import 'package:attention_detector/widgets/game_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/game_fixtures.dart';

void main() {
  testWidgets('декоративные искры не перехватывают нажатия', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: ElevatedButton(onPressed: () => taps++, child: const Text('Играть'))),
            const AmbientSparkles(),
          ],
        ),
      ),
    ));
    await tester.tap(find.text('Играть'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('иллюстрация движется и останавливается при уменьшении анимации', (tester) async {
    const artwork = ValueKey('artwork');
    Widget view(bool reduced) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: const Scaffold(
              body: Center(
                child: FloatingArt(
                  distance: 12,
                  duration: Duration(seconds: 4),
                  child: SizedBox(key: artwork, width: 40, height: 40),
                ),
              ),
            ),
          ),
        );

    await tester.pumpWidget(view(false));
    await tester.pump();
    final start = tester.getTopLeft(find.byKey(artwork));
    await tester.pump(const Duration(seconds: 1));
    final moved = tester.getTopLeft(find.byKey(artwork));
    expect((moved.dy - start.dy).abs(), greaterThan(2));

    await tester.pumpWidget(view(true));
    final paused = tester.getTopLeft(find.byKey(artwork));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getTopLeft(find.byKey(artwork)).dy, closeTo(paused.dy, 0.001));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('парящая иллюстрация останавливается на скрытом экране и продолжает движение', (tester) async {
    const artwork = ValueKey('ticker-artwork');
    Widget view(bool enabled) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: TickerMode(
                enabled: enabled,
                child: const FloatingArt(
                  distance: 12,
                  duration: Duration(seconds: 4),
                  child: SizedBox(key: artwork, width: 40, height: 40),
                ),
              ),
            ),
          ),
        );

    await tester.pumpWidget(view(true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(view(false));
    final paused = tester.getTopLeft(find.byKey(artwork)).dy;
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getTopLeft(find.byKey(artwork)).dy, closeTo(paused, 0.001));
    await tester.pumpWidget(view(true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect((tester.getTopLeft(find.byKey(artwork)).dy - paused).abs(), greaterThan(0.1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('звёзды результата появляются без анимации при системном ограничении', (tester) async {
    Widget view(bool reduced) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: const Scaffold(body: Center(child: StarRow(stars: 2, animate: true))),
          ),
        );

    await tester.pumpWidget(view(false));
    expect(find.byType(TweenAnimationBuilder<double>), findsNWidgets(2));
    await tester.pumpWidget(view(true));
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    expect(find.byType(StarShape), findsNWidgets(3));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('питомец запускает обе анимации и реагирует на касание', (tester) async {
    final controller = makeController();
    await tester.pumpWidget(GameScope(
      controller: controller,
      child: MaterialApp(
        home: Scaffold(body: Center(child: SizedBox(width: 280, height: 280, child: PetStage(state: controller.state!, compact: false)))),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(PetStage));
    await tester.pump();
    expect(controller.offlinePats, 1);
    await tester.pump(const Duration(milliseconds: 750));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  test('новые иллюстрации включены в пакет приложения', () async {
    for (final asset in [
      'assets/bg/shop_scene.webp',
      'assets/bg/events_scene.webp',
      'assets/bg/training_scene.webp',
    ]) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.lengthInBytes, greaterThan(1000), reason: asset);
    }
  });
}
