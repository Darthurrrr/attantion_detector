import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/toast_layer.dart';
import '../state/game_controller.dart';
import '../theme/palette.dart';
import '../widgets/game_ui.dart';

/// Корневой виджет: тема + доступ к контроллеру без сторонних пакетов.
class GameApp extends StatelessWidget {
  const GameApp({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return GameScope(controller: controller, child: const _ThemedApp());
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GameScope.of(context),
      builder: (context, _) {
        final palette = Palette.byId(GameScope.of(context).state?.uiTheme);
        return MaterialApp(
          title: 'Детектор внимания',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: palette.deep,
            colorScheme: ColorScheme.fromSeed(seedColor: palette.bright, brightness: Brightness.dark),
            extensions: [GamePaletteExt(palette: palette)],
            textTheme: const TextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white),
          ),
          builder: (context, child) => ToastOverlay(child: child ?? const SizedBox.shrink()),
          home: const SplashScreen(),
        );
      },
    );
  }
}

/// Простой InheritedNotifier вместо внешних пакетов состояния.
class GameScope extends InheritedNotifier<GameController> {
  const GameScope({super.key, required GameController controller, required super.child})
      : super(notifier: controller);

  static GameController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GameScope>();
    assert(scope != null, 'GameScope не найден в дереве');
    return scope!.notifier!;
  }

  static GameController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<GameScope>();
    assert(scope != null, 'GameScope не найден в дереве');
    return scope!.notifier!;
  }
}

/// Доступ к палитре текущей темы интерфейса.
Palette paletteOf(BuildContext context) {
  final state = GameScope.of(context).state;
  return Palette.byId(state?.uiTheme);
}
