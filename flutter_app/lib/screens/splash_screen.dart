import 'package:flutter/material.dart';

import '../app/game_app.dart';
import '../state/game_controller.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/game_ui.dart';
import 'home_screen.dart';
import 'offline_screen.dart';

/// Заставка: логотип, загрузка мира и подсказка. Ориентация — любая.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final controller = GameScope.read(context);
    if (controller.phase == LoadPhase.booting) {
      await controller.boot();
    }
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    final ready = controller.phase == LoadPhase.ready;
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 460),
      pageBuilder: (_, animation, __) => FadeTransition(
        opacity: animation,
        child: ready
            ? const HomeScreen()
            : OfflineScreen(
                onRetry: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
                ),
              ),
      ),
    ));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final palette = paletteOf(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SceneBackground(asset: 'assets/bg/splash.webp', veil: 0.25),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.mid.withOpacity(0.35), palette.deep.withOpacity(0.92)],
              ),
            ),
          ),
          SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                final portrait = orientation == Orientation.portrait;
                if (portrait) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: Tween(begin: 0.96, end: 1.04)
                              .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
                          child: _Logo(palette: palette, size: 150),
                        ),
                        const SizedBox(height: 4),
                        Text('Детектор внимания', style: AppText.title, textAlign: TextAlign.center),
                        Text('приключения кота Мурзика', style: AppText.small),
                        const SizedBox(height: 30),
                        _Loader(controller: controller, palette: palette),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Logo(palette: palette, size: 132),
                            const SizedBox(height: 6),
                            Text('Детектор внимания', style: AppText.title),
                            Text('приключения кота Мурзика', style: AppText.small),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const HeartShape(size: 13),
                                const SizedBox(width: 6),
                                Text('Горизонтальный режим включён', style: AppText.tiny),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: _Loader(controller: controller, palette: palette)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.palette, required this.size});

  final Palette palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size + 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size + 24,
            height: size + 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                palette.accent.withOpacity(0.55),
                palette.accent.withOpacity(0),
              ]),
            ),
          ),
          Image.asset('assets/hero_cat.png', height: size, fit: BoxFit.contain),
        ],
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader({required this.controller, required this.palette});

  final GameController controller;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final ready = controller.phase != LoadPhase.booting;
    final message = switch (controller.phase) {
      LoadPhase.booting => 'Загрузка мира Мурзика…',
      LoadPhase.ready => 'Мир готов. Начинаем!',
      LoadPhase.offline => 'Сервер недоступен — проверьте интернет и повторите попытку',
      LoadPhase.error => controller.errorText ?? 'Что-то пошло не так',
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 10,
          child: ready
              ? const ProgressBar(value: 1, height: 10)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    minHeight: 10,
                    backgroundColor: Color(0x33000000),
                    color: Palette.gold,
                  ),
                ),
        ),
        const SizedBox(height: 14),
        GamePanel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          radius: 16,
          child: Row(
            children: [
              const HeartShape(size: 15),
              const SizedBox(width: 8),
              Expanded(child: Text(message, style: AppText.small)),
            ],
          ),
        ),
      ],
    );
  }
}
