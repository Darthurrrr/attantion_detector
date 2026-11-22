import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/game_app.dart';
import '../data/models.dart';
import '../state/game_controller.dart';
import '../games/egg_reveal.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/game_ui.dart';
import '../widgets/layered_scene.dart';
import '../widgets/top_bar.dart';

/// Вкладка «Призыв»: универсальное яйцо, гаранты, история и правила.
class SummonScreen extends StatefulWidget {
  const SummonScreen({super.key});

  @override
  State<SummonScreen> createState() => _SummonScreenState();
}

class _SummonScreenState extends State<SummonScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  bool _busy = false;
  String? _filter;
  bool _historyHintShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  Future<void> _open(int count) async {
    if (_busy) return;
    final controller = GameScope.read(context);
    setState(() => _busy = true);
    final outcome = await controller.summon(count);
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome == null) return;
    await Navigator.of(context).push(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, animation, __) => FadeTransition(
        opacity: animation,
        child: EggReveal(
          results: outcome.results,
          onDone: () => Navigator.of(context).pop(),
          onSound: (kind) {
            switch (kind) {
              case 'legendary':
                controller.audio.legendaryFanfare();
                break;
              case 'reward':
                controller.audio.rewardSound();
                break;
              case 'crystal':
                controller.audio.crystalSound();
                break;
              default:
                controller.audio.tapSound();
            }
          },
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final state = controller.state;
    final cfg = controller.config;
    if (state == null || cfg == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final palette = paletteOf(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LayeredScene.summon(),
          SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                final portrait = orientation == Orientation.portrait;
                if (!_historyHintShown && state.history.isNotEmpty) {
                  // Подсказка о восстановлении: результаты уже на сервере.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || _historyHintShown) return;
                    _historyHintShown = true;
                    controller.showToast('Результаты призыва сохранены — они в истории', tone: ToastTone.info);
                  });
                }
                return Column(
                  children: [
                    GameTopBar(current: 'summon', compact: portrait),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                        child: portrait
                            ? Column(
                                children: [
                                  Expanded(flex: 5, child: _EggStage(controller: _float, state: state, cfg: cfg)),
                                  const SizedBox(height: 8),
                                  _OpenPanel(
                                    state: state,
                                    cfg: cfg,
                                    busy: _busy,
                                    onOpen: _open,
                                    onBuy: () => GameTopBar.open(context, 'shop'),
                                    onRules: () => _showRules(cfg, palette),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 150,
                                    child: _History(
                                      state: state,
                                      filter: _filter,
                                      onFilter: (f) => setState(() => _filter = f),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 5, child: _EggStage(controller: _float, state: state, cfg: cfg)),
                                  const SizedBox(width: 14),
                                  SizedBox(
                                    width: 360,
                                    child: Column(
                                      children: [
                                        _OpenPanel(
                                          state: state,
                                          cfg: cfg,
                                          busy: _busy,
                                          onOpen: _open,
                                          onBuy: () => GameTopBar.open(context, 'shop'),
                                          onRules: () => _showRules(cfg, palette),
                                        ),
                                        const SizedBox(height: 10),
                                        Expanded(
                                          child: _History(
                                            state: state,
                                            filter: _filter,
                                            onFilter: (f) => setState(() => _filter = f),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    if (portrait) const GameBottomNav(current: 'summon'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRules(GameConfig cfg, Palette palette) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RulesSheet(cfg: cfg, palette: palette),
    );
  }
}

class _EggStage extends StatelessWidget {
  const _EggStage({required this.controller, required this.state, required this.cfg});

  final AnimationController controller;
  final GameState state;
  final GameConfig cfg;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return GamePanel(
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _AuraPainter(palette.accent))),
          const Positioned.fill(child: SummonStageCrystals()),
          Center(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, (controller.value - 0.5) * 16),
                child: Transform.rotate(angle: (controller.value - 0.5) * 0.05, child: child),
              ),
              child: Image.asset('assets/ui/egg_0.png', fit: BoxFit.contain),
            ),
          ),
          Positioned(
            left: 8,
            top: 6,
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 15, color: Palette.gold),
                const SizedBox(width: 5),
                Text('Универсальное яйцо', style: AppText.h2),
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.42),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Palette.gold.withOpacity(0.7)),
              ),
              child: Text('${cfg.eggPrice} кристаллов', style: AppText.small),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 4,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PityRing(value: state.pityEpic, max: 5, label: 'Эпический', color: Palette.violet),
                  const SizedBox(width: 10),
                  _PityRing(value: state.pityLegendary, max: 10, label: 'Легендарный', color: Palette.gold),
                  const SizedBox(width: 10),
                  Text('Призывов: ${state.pityTotal}', style: AppText.tiny),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PityRing extends StatelessWidget {
  const _PityRing({required this.value, required this.max, required this.label, required this.color});

  final int value;
  final int max;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: (value / max).clamp(0.0, 1.0).toDouble(),
                strokeWidth: 4,
                backgroundColor: Colors.white.withOpacity(0.16),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Text('$value/$max', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppText.tiny),
            Text(
              value == 0 ? 'пока пусто' : 'ещё ${max - value}',
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ],
    );
  }
}

class _AuraPainter extends CustomPainter {
  _AuraPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..shader = RadialGradient(colors: [color.withOpacity(0.35), color.withOpacity(0)])
          .createShader(Rect.fromCircle(center: center, radius: size.shortestSide * 0.55));
    canvas.drawCircle(center, size.shortestSide * 0.55, paint);
    final rand = math.Random(3);
    for (var i = 0; i < 34; i++) {
      final angle = rand.nextDouble() * math.pi * 2;
      final radius = rand.nextDouble() * size.shortestSide * 0.5;
      final point = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      canvas.drawCircle(point, 1.2 + rand.nextDouble() * 1.6, Paint()..color = Colors.white.withOpacity(0.35));
    }
  }

  @override
  bool shouldRepaint(covariant _AuraPainter old) => old.color != color;
}

class _OpenPanel extends StatelessWidget {
  const _OpenPanel({
    required this.state,
    required this.cfg,
    required this.busy,
    required this.onOpen,
    required this.onBuy,
    required this.onRules,
  });

  final GameState state;
  final GameConfig cfg;
  final bool busy;
  final void Function(int) onOpen;
  final VoidCallback onBuy;
  final VoidCallback onRules;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.all(12),
      background: paletteOf(context).deep.withOpacity(0.75),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const EggIcon(size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Semantics(
                  label: 'Яиц в инвентаре: ${state.eggs}',
                  excludeSemantics: true,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('Яиц: ${state.eggs}', style: AppText.h2),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onRules,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 26)),
                child: const Text('Правила',
                    style: TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: GameButton(
                  label: busy ? '…' : 'Открыть 1',
                  tone: ButtonTone.gold,
                  height: 46,
                  enabled: !busy && state.eggs >= 1,
                  onTap: () => onOpen(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GameButton(
                  label: busy ? '…' : 'Открыть 5',
                  tone: ButtonTone.violet,
                  height: 46,
                  enabled: !busy && state.eggs >= 5,
                  onTap: () => onOpen(5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  state.eggs == 0 ? 'Яиц нет — купите в магазине за кристаллы' : 'Открытие списывает яйца из инвентаря',
                  style: AppText.tiny,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 6),
              TextButton.icon(
                onPressed: onBuy,
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 15, color: Palette.gold),
                label: Text('Купить за ${cfg.eggPrice}',
                    style: const TextStyle(fontSize: 11.5, color: Palette.gold, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.state, required this.filter, required this.onFilter});

  final GameState state;
  final String? filter;
  final void Function(String?) onFilter;

  @override
  Widget build(BuildContext context) {
    final rows = filter == null ? state.history : state.history.where((h) => h['rarity'] == filter).toList();
    return GamePanel(
      padding: const EdgeInsets.all(10),
      background: paletteOf(context).deep.withOpacity(0.75),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('История призывов', style: AppText.h2),
                ),
              ),
              const SizedBox(width: 6),
              Text('${state.history.length}', style: AppText.tiny),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(label: 'Все', active: filter == null, onTap: () => onFilter(null)),
                for (final rarity in RarityStyle.all)
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: _FilterChip(
                      label: rarity.label,
                      color: rarity.color,
                      active: filter == rarity.id,
                      onTap: () => onFilter(rarity.id),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Text('Пока пусто. Откройте первое яйцо!',
                        style: AppText.small, textAlign: TextAlign.center))
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 5),
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final rarity = RarityStyle.byId(row['rarity'] as String? ?? 'common');
                      final at = DateTime.tryParse(row['at'] as String? ?? '')?.toLocal();
                      final isNew = row['isNew'] as bool? ?? false;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: rarity.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: rarity.color.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 30,
                              height: 30,
                              child: Image.asset(row['asset'] as String? ?? 'assets/pets/slime.png',
                                  fit: BoxFit.contain),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(row['name'] as String? ?? '',
                                      style: const TextStyle(
                                          fontSize: 11.5, fontWeight: FontWeight.w900, color: Colors.white)),
                                  Text(at == null ? '' : _format(at), style: AppText.tiny),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                RarityBadge(rarity: rarity, compact: true),
                                const SizedBox(height: 2),
                                Text(
                                  isNew ? 'новый' : '+${row['gems']} кр.',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: isNew ? Palette.mint : Palette.sky,
                                  ),
                                ),
                              ],
                            ),
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

  static String _format(DateTime at) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(at.day)}.${two(at.month)} ${two(at.hour)}:${two(at.minute)}';
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active, required this.onTap, this.color});

  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Palette.gold;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: active ? c.withOpacity(0.3) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? c : Colors.white.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: active ? Colors.white : Colors.white70),
        ),
      ),
    );
  }
}

class _RulesSheet extends StatelessWidget {
  const _RulesSheet({required this.cfg, required this.palette});

  final GameConfig cfg;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final rules = cfg.rules;
    final rates = (rules['rates'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final dups = (rules['duplicates'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [palette.mid, palette.deep]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.accent.withOpacity(0.5), width: 1.6),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Правила призыва', style: AppText.h1),
            const SizedBox(height: 8),
            Text('Стоимость яйца — ${rules['eggPrice']} кристаллов. Результат определяет сервер.', style: AppText.small),
            const SizedBox(height: 10),
            for (final rate in rates)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    RarityBadge(rarity: RarityStyle.byId(rate['rarity'] as String)),
                    const Spacer(),
                    Text('${rate['rate']}%', style: AppText.body),
                  ],
                ),
              ),
            const Divider(color: Colors.white24, height: 18),
            Text('Гаранты', style: AppText.h2),
            Text('Каждое 5-е открытие — эпик или выше. Каждое 10-е — легендарный питомец (приоритет).',
                style: AppText.small),
            const SizedBox(height: 8),
            Text('Дубликаты', style: AppText.h2),
            for (final dup in dups)
              Row(
                children: [
                  RarityBadge(rarity: RarityStyle.byId(dup['rarity'] as String), compact: true),
                  const Spacer(),
                  Text('+${dup['gems']} кристаллов', style: AppText.small),
                ],
              ),
            const SizedBox(height: 8),
            Text('«Открыть 1» и «Открыть 5» списывают яйца. Купленные яйца сначала попадают в инвентарь.',
                style: AppText.tiny),
          ],
        ),
      ),
    );
  }
}
