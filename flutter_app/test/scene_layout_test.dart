import 'package:attention_detector/app/game_app.dart';
import 'package:attention_detector/screens/events_screen.dart';
import 'package:attention_detector/screens/home_screen.dart';
import 'package:attention_detector/screens/play_screen.dart';
import 'package:attention_detector/screens/shop_screen.dart';
import 'package:attention_detector/screens/trainings_screen.dart';
import 'package:attention_detector/widgets/ambient_effects.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/game_fixtures.dart';

/// Сохраняем подробности ошибки, которую обычно скрывает takeException().
Future<void> expectNoFlutterError(WidgetTester tester, Future<void> Function() action, {required String reason}) async {
  final details = <FlutterErrorDetails>[];
  final previousHandler = FlutterError.onError;
  FlutterError.onError = (error) {
    details.add(error);
    previousHandler?.call(error);
  };
  Object? exception;
  try {
    await action();
    exception = tester.takeException();
  } finally {
    FlutterError.onError = previousHandler;
  }
  if (exception != null) {
    for (final error in details) {
      FlutterError.dumpErrorToConsole(error, forceReport: true);
    }
  }
  expect(exception, isNull, reason: reason);
}

Finder scrollableInside(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(Scrollable),
    ).first;

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 400),
    const Size(844, 390),
  ]) {
    for (final screen in <Widget>[
      const HomeScreen(),
      const ShopScreen(),
      const EventsScreen(),
      const TrainingsScreen(),
    ]) {
      testWidgets('${screen.runtimeType} помещается: ${size.width} × ${size.height}', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = makeController();
        await expectNoFlutterError(tester, () async {
          await tester.pumpWidget(GameScope(controller: controller, child: MaterialApp(home: screen)));
          await tester.pump(const Duration(milliseconds: 100));
        }, reason: '${screen.runtimeType}, $size');
        expect(find.byType(AmbientSparkles), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      });
    }
  }

  testWidgets('количество яиц меняется поверх анимированного фона', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = makeController();
    await expectNoFlutterError(tester, () async {
      await tester.pumpWidget(GameScope(controller: controller, child: const MaterialApp(home: ShopScreen())));
      await tester.pump();
      await tester.tap(find.byTooltip('Увеличить количество'));
      await tester.pump(const Duration(milliseconds: 250));
    }, reason: 'управление количеством яиц');
    expect(find.text('Итого: 120'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('на узком экране можно прокрутить магазин и выбрать яйца', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = makeController();
    await expectNoFlutterError(tester, () async {
      await tester.pumpWidget(GameScope(controller: controller, child: const MaterialApp(home: ShopScreen())));
      await tester.scrollUntilVisible(find.byTooltip('Увеличить количество'), 140, scrollable: scrollableInside('egg-shop-content'));
      await tester.pump(); // Применяем новое положение прокрутки перед касанием.
      expect(find.byTooltip('Увеличить количество').hitTestable(), findsOneWidget);
      await tester.tap(find.byTooltip('Увеличить количество'));
      await tester.pump(const Duration(milliseconds: 250));
    }, reason: 'прокрутка магазина на узком экране');
    expect(find.text('Итого: 120'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('задания и события доступны при прокрутке на узком экране', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = makeController();
    await expectNoFlutterError(tester, () async {
      await tester.pumpWidget(GameScope(controller: controller, child: const MaterialApp(home: EventsScreen())));
      await tester.scrollUntilVisible(find.text('Пройдите тренировку 5'), 180, scrollable: scrollableInside('events-content'));
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Первые шаги'), 180, scrollable: scrollableInside('events-content'));
      await tester.pump();
    }, reason: 'прокрутка событий на узком экране');
    expect(find.text('Первые шаги'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('выбранную тренировку можно запустить на узком экране', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = makeController();
    await expectNoFlutterError(tester, () async {
      await tester.pumpWidget(GameScope(controller: controller, child: const MaterialApp(home: TrainingsScreen())));
      await tester.scrollUntilVisible(find.text('Играть'), 150, scrollable: scrollableInside('training-content'));
      await tester.pump();
      expect(find.text('Играть').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Играть'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
    }, reason: 'запуск тренировки на узком экране');
    expect(find.byType(PlayScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('на узком экране магазин доступен из верхней навигации', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = makeController();
    await expectNoFlutterError(tester, () async {
      await tester.pumpWidget(GameScope(controller: controller, child: const MaterialApp(home: HomeScreen())));
      await tester.tap(find.byTooltip('Магазин'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }, reason: 'навигация в магазин на узком экране');
    expect(find.byType(ShopScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
