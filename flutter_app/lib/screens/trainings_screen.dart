import 'package:flutter/material.dart';

import '../app/game_app.dart';
import '../data/models.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/game_ui.dart';
import '../widgets/top_bar.dart';
import 'play_screen.dart';

/// Тренировки и тесты: главы, карта уровней и карточка выбранного уровня.
class TrainingsScreen extends StatefulWidget {
  const TrainingsScreen({super.key});

  @override
  State<TrainingsScreen> createState() => _TrainingsScreenState();
}

class _TrainingsScreenState extends State<TrainingsScreen> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final cfg = controller.config;
    final state = controller.state;
    if (cfg == null || state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (cfg.levels.isEmpty) {
      return Scaffold(
        body: Center(child: Text('Уровни ещё не загружены', style: AppText.body)),
      );
    }
    final palette = paletteOf(context);
    final selected = cfg.levels.firstWhere((l) => l.id == _selected, orElse: () => cfg.levels.first);
    final played = state.taskProgress['games'] ?? 0;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SceneBackground(asset: 'assets/bg/map.webp', veil: 0.42),
          SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                final portrait = orientation == Orientation.portrait;
                return Column(
                  children: [
                    GameTopBar(current: 'map', compact: portrait),
                    Expanded(
                      child: portrait
                          ? Column(
                              children: [
                                Expanded(child: _ChapterMap(cfg: cfg, selected: selected, onSelect: _select, played: played)),
                                _LevelCard(level: selected, palette: palette, onPlay: () => _play(selected)),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 5, child: _ChapterMap(cfg: cfg, selected: selected, onSelect: _select, played: played)),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 330,
                                    child: Column(
                                      children: [
                                        Expanded(child: _LevelCard(level: selected, palette: palette, onPlay: () => _play(selected))),
                                        const SizedBox(height: 10),
                                        _TestTips(palette: palette),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    if (portrait) const GameBottomNav(current: 'map'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _select(LevelDef level) {
    GameScope.read(context).audio.tapSound();
    setState(() => _selected = level.id);
  }

  Future<void> _play(LevelDef level) async {
    GameScope.read(context).audio.tapSound();
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlayScreen(level: level)));
    if (mounted) setState(() {});
  }
}

class _ChapterMap extends StatelessWidget {
  const _ChapterMap({required this.cfg, required this.selected, required this.onSelect, required this.played});

  final GameConfig cfg;
  final LevelDef selected;
  final void Function(LevelDef) onSelect;
  final int played;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return GamePanel(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.map_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Text('Глава 1 · Мир внимания', style: AppText.h2),
                const Spacer(),
                Text('Тренировок сегодня: $played', style: AppText.tiny),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              scrollDirection: Axis.horizontal,
              itemCount: cfg.levels.length,
              separatorBuilder: (_, __) => SizedBox(width: 8, child: Center(child: _PathDot(palette: palette))),
              itemBuilder: (context, index) {
                final level = cfg.levels[index];
                return SizedBox(
                  height: double.infinity,
                  child: _LevelTile(
                    level: level,
                    active: level.id == selected.id,
                    onTap: () => onSelect(level),
                    isLast: index == cfg.levels.length - 1,
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

class _PathDot extends StatelessWidget {
  const _PathDot({required this.palette});
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.accent.withOpacity(0.35),
        border: Border.all(color: palette.accent.withOpacity(0.6), width: 1.2),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.level, required this.active, required this.onTap, required this.isLast});

  final LevelDef level;
  final bool active;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final color = switch (level.type) {
      'match' => const Color(0xFF6AD1FF),
      'odd' => const Color(0xFFFFBF5E),
      'firefly' => const Color(0xFFFFD766),
      'simon' => const Color(0xFFC58BFF),
      _ => const Color(0xFF8EF0C0),
    };
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 128,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: active
                ? [color.withOpacity(0.62), color.withOpacity(0.2)]
                : [Colors.white.withOpacity(0.16), Colors.white.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? palette.accent : Colors.white.withOpacity(0.22),
            width: active ? 2 : 1.2,
          ),
          boxShadow: active
              ? [BoxShadow(color: color.withOpacity(0.55), blurRadius: 18, offset: const Offset(0, 6))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color.lerp(color, Colors.white, 0.3)!, color],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${level.id}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Palette.ink),
                  ),
                ),
                const Spacer(),
                if (isLast)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: palette.accent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('финал', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Palette.ink)),
                  ),
              ],
            ),
            const Spacer(),
            Icon(Icons.videogame_asset_rounded, size: 26, color: Colors.white.withOpacity(0.85)),
            const SizedBox(height: 6),
            Text(
              level.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15),
            ),
            const SizedBox(height: 4),
            Text(level.typeLabel, style: AppText.tiny, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            StarRow(stars: 0, size: 13),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.palette, required this.onPlay});

  final LevelDef level;
  final Palette palette;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [palette.accent, Palette.goldDeep]),
                  border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${level.id}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Palette.ink),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(level.name, style: AppText.h1, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${level.typeLabel} · ${level.xpLabel}', style: AppText.small),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GamePanel(
            padding: const EdgeInsets.all(10),
            radius: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded, size: 16, color: Palette.gold),
                const SizedBox(width: 8),
                Expanded(child: Text(level.tip, style: AppText.small)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MetaChip(icon: Icons.speed_rounded, label: 'Опыт: ${level.xpLabel}'),
              const SizedBox(width: 6),
              _MetaChip(icon: Icons.timer_rounded, label: _duration(level)),
            ],
          ),
          const Spacer(),
          GameButton(
            label: 'Играть',
            tone: ButtonTone.gold,
            height: 50,
            icon: const Icon(Icons.play_arrow_rounded, color: Palette.ink, size: 22),
            onTap: onPlay,
          ),
        ],
      ),
    );
  }

  static String _duration(LevelDef level) {
    return switch (level.type) {
      'match' => '~1–2 мин',
      'odd' => '${level.param('rounds', 4)} раунда',
      'firefly' => '${level.param('seconds', 26)} сек',
      'simon' => '${level.param('seq', 4)} сигнала',
      _ => '${level.param('rounds', 5)} раундов',
    };
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label, style: AppText.tiny),
        ],
      ),
    );
  }
}

class _TestTips extends StatelessWidget {
  const _TestTips({required this.palette});

  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const HeartShape(size: 13),
          const SizedBox(width: 8),
          Expanded(child: Text('Без энергии и ограничений: играйте сколько хотите.', style: AppText.tiny)),
        ],
      ),
    );
  }
}
