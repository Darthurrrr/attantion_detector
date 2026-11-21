import 'dart:math' as math;
import 'dart:ui' show MaskFilter;

import 'package:flutter/material.dart';

import '../app/game_app.dart';
import '../data/models.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/game_ui.dart';
import '../widgets/top_bar.dart';
import 'trainings_screen.dart';
import 'collection_screen.dart';
import 'events_screen.dart';
import 'inventory_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';
import 'summon_screen.dart';

/// Главный экран: живой мир, активный питомец, валюты и вход в тренировки.
/// Горизонтальная ориентация получает собственную композицию (сцена слева,
/// панели справа), вертикальная — вертикальную (сцена сверху, панели снизу).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameScope.of(context).state;
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final worldAsset = _worldAsset(state.worldTheme);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            child: SceneBackground(key: ValueKey(worldAsset), asset: worldAsset, veil: 0.18),
          ),
          SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                final portrait = orientation == Orientation.portrait;
                if (portrait) {
                  return Column(
                    children: [
                      GameTopBar(current: 'home', compact: true),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 260,
                                child: PetStage(state: state, compact: false),
                              ),
                              const SizedBox(height: 10),
                              _MenuGrid(state: state),
                              const SizedBox(height: 10),
                              _DailyStrip(state: state),
                              const SizedBox(height: 10),
                              _StartPanel(state: state),
                            ],
                          ),
                        ),
                      ),
                      const GameBottomNav(current: 'home'),
                    ],
                  );
                }
                return Column(
                  children: [
                    GameTopBar(current: 'home'),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  Expanded(child: PetStage(state: state, compact: true)),
                                  const SizedBox(height: 8),
                                  const _RotateHint(),
                                  const SizedBox(height: 8),
                                  _DailyStrip(state: state),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  Expanded(child: _MenuGrid(state: state)),
                                  const SizedBox(height: 10),
                                  _StartPanel(state: state),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _worldAsset(String id) => switch (id) {
        'world_cosmos' => 'assets/bg/cosmic.webp',
        'world_summon' => 'assets/bg/summon.webp',
        'world_collection' => 'assets/bg/collection.webp',
        _ => 'assets/bg/home.webp',
      };
}

/// Сцена с питомцем: анимация ожидания, реакция на касание и поглаживание.
class PetStage extends StatefulWidget {
  const PetStage({super.key, required this.state, required this.compact});

  final GameState state;
  final bool compact;

  @override
  State<PetStage> createState() => _PetStageState();
}

class _PetStageState extends State<PetStage> with SingleTickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);
  late final AnimationController _squash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  double _stroke = 0;
  bool _hearts = false;

  @override
  void dispose() {
    _idle.dispose();
    _squash.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    final controller = GameScope.read(context);
    _squash.forward(from: 0);
    setState(() => _hearts = true);
    await controller.patPet();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _hearts = false);
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.state.activePet;
    final palette = paletteOf(context);
    if (pet == null) return const SizedBox.shrink();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      onHorizontalDragUpdate: (details) {
        setState(() => _stroke = (_stroke + details.delta.dx.abs() * 0.02).clamp(0.0, 1.0).toDouble());
      },
      onHorizontalDragEnd: (_) async {
        if (_stroke > 0.25) {
          final controller = GameScope.read(context);
          await controller.audio.cuddleSound();
          controller.showToast('Мурзик мурчит от удовольствия', tone: ToastTone.good);
        }
        setState(() => _stroke = 0);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _StageGlow(palette.accent)),
          ),
          AnimatedBuilder(
            animation: Listenable.merge([_idle, _squash]),
            builder: (context, child) {
              final bob = math.sin(_idle.value * math.pi * 2) * 6;
              final squash = 1 - math.sin(_squash.value * math.pi) * 0.06;
              return Transform.translate(
                offset: Offset(0, bob),
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()
                    ..scale(1 + (1 - squash) * 0.5, squash),
                  child: child,
                ),
              );
            },
            child: Hero(
              tag: 'active-pet',
              child: Image.asset(
                pet.asset,
                key: ValueKey(pet.petId),
                fit: BoxFit.contain,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  width: 160,
                  height: 160,
                  color: Colors.white12,
                  alignment: Alignment.center,
                  child: const Icon(Icons.pets, size: 60, color: Colors.white54),
                ),
              ),
            ),
          ),
          if (_hearts)
            Positioned(
              top: 12,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                builder: (context, value, child) => Opacity(
                  opacity: 1 - value,
                  child: Transform.translate(offset: Offset(0, -value * 40), child: child),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [HeartShape(size: 20), HeartShape(size: 14), HeartShape(size: 17)],
                ),
              ),
            ),
          if (_stroke > 0)
            Positioned(
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HeartShape(size: 12),
                    const SizedBox(width: 6),
                    Text('Гладим ${pet.name}…', style: AppText.small),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: pet.rarity.color.withOpacity(0.8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StarShape(filled: true, size: 12),
                  const SizedBox(width: 5),
                  Text(
                    '${pet.name} · ур. ${pet.level}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.38),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.compact ? 'Погладьте Мурзика' : 'Коснитесь питомца или погладьте пальцем',
                style: AppText.tiny,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageGlow extends CustomPainter {
  _StageGlow(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.58);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withOpacity(0.34), color.withOpacity(0)],
      ).createShader(Rect.fromCircle(center: center, radius: size.shortestSide * 0.55));
    canvas.drawCircle(center, size.shortestSide * 0.55, paint);

    final ground = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.9), width: size.width * 0.5, height: size.height * 0.06),
      ground,
    );
  }

  @override
  bool shouldRepaint(covariant _StageGlow old) => old.color != color;
}

/// Подсказка в вертикальном режиме: горизонтальная композиция богаче.
class _RotateHint extends StatelessWidget {
  const _RotateHint();

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      radius: 12,
      child: Row(
        children: [
          const Icon(Icons.screen_rotation_rounded, size: 14, color: Palette.gold),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Поверните телефон — в горизонтальном режиме игра выглядит просторнее',
                style: AppText.tiny),
          ),
        ],
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final entries = <(_MenuEntry)>[
      _MenuEntry('Магазин', Icons.storefront_rounded, const Color(0xFFFFC46B), () => const ShopScreen()),
      _MenuEntry('События', Icons.event_available_rounded, Palette.rose, () => const EventsScreen()),
      _MenuEntry('Инвентарь', Icons.backpack_rounded, Palette.mint, () => const InventoryScreen()),
      _MenuEntry('Профиль', Icons.person_rounded, Palette.sky, () => const ProfileScreen()),
      _MenuEntry('Коллекция', Icons.pets_rounded, Palette.violet, () => const CollectionScreen()),
      _MenuEntry('Призыв', Icons.auto_awesome_rounded, palette.accent, () => const SummonScreen()),
    ];
    return GamePanel(
      padding: const EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 380 ? 3 : 2;
          final spacing = 8.0;
          final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final entry in entries)
                SizedBox(
                  width: width,
                  child: _MenuTile(entry: entry),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuEntry {
  _MenuEntry(this.label, this.icon, this.color, this.builder);
  final String label;
  final IconData icon;
  final Color color;
  final Widget Function() builder;
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.entry});

  final _MenuEntry entry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        GameScope.read(context).audio.tapSound();
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => entry.builder()));
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [entry.color.withOpacity(0.34), entry.color.withOpacity(0.14)],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: entry.color.withOpacity(0.6), width: 1.3),
        ),
        child: Row(
          children: [
            Icon(entry.icon, size: 19, color: Colors.white),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartPanel extends StatelessWidget {
  const _StartPanel({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final nextLevel = _nextLevel(state);
    return GamePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Следующая тренировка', style: AppText.tiny),
                    Text('Уровень $nextLevel', style: AppText.h1),
                  ],
                ),
              ),
              StarRow(stars: 0, max: 3, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          GameButton(
            label: 'Начать тренировку',
            tone: ButtonTone.gold,
            height: 50,
            icon: const Icon(Icons.play_arrow_rounded, size: 22, color: Palette.ink),
            onTap: () {
              GameScope.read(context).audio.tapSound();
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TrainingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  static int _nextLevel(GameState state) {
    final cleared = state.taskProgress['games'] ?? 0;
    return (cleared % 17) + 1;
  }
}

class _DailyStrip extends StatelessWidget {
  const _DailyStrip({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final claimed = !state.dailyCanClaim;
    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFFFFE7A8), Color(0xFFF2A32A)]),
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Palette.ink, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Ежедневная награда', style: AppText.h2),
                Text(
                  claimed
                      ? 'Уже получена. Возвращайтесь завтра!'
                      : 'День ${(state.dailyStreak % 7) + 1} из 7 · на 7-й день — питомец',
                  style: AppText.tiny,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GameButton(
            label: claimed ? 'Завтра' : 'Забрать',
            tone: claimed ? ButtonTone.plain : ButtonTone.mint,
            height: 36,
            width: 108,
            fontSize: 12.5,
            enabled: !claimed,
            onTap: () => controller.claimDaily(),
          ),
        ],
      ),
    );
  }
}
