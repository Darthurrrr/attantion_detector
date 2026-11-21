import 'package:attention_detector/app/game_app.dart';
import 'package:attention_detector/screens/events_screen.dart';
import 'package:attention_detector/screens/home_screen.dart';
import 'package:attention_detector/screens/shop_screen.dart';
import 'package:attention_detector/screens/trainings_screen.dart';
import 'package:attention_detector/widgets/ambient_effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/game_fixtures.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(800, 400)]) {
    testWidgets('экраны со сценами помещаются: ${size.width} × ${size.height}', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = makeController();
      for (final screen in <Widget>[
        const HomeScreen(),
        const ShopScreen(),
        const EventsScreen(),
        const TrainingsScreen(),
      ]) {
        await tester.pumpWidget(GameScope(controller: controller, child: MaterialApp(home: screen)));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: '${screen.runtimeType}, $size');
        expect(find.byType(AmbientSparkles), findsOneWidget, reason: '${screen.runtimeType}, $size');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }

  testWidgets('количество яиц меняется поверх анимированного фона', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = makeController();
    await tester.pumpWidget(GameScope(controller: controller, child: const MaterialApp(home: ShopScreen())));
    await tester.pump();
    await tester.tap(find.byTooltip('Увеличить количество'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Итого: 120'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
