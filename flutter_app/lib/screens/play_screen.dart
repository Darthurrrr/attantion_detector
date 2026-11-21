import 'dart:async';

import 'package:flutter/material.dart';

import '../app/game_app.dart';
import '../data/models.dart';
import '../games/count_game.dart';
import '../games/firefly_game.dart';
import '../games/match_game.dart';
import '../games/odd_game.dart';
import '../games/outcome.dart';
import '../games/simon_game.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/game_ui.dart';

/// Экран прохождения тренировки: отсчёт, мини-игра, результат с наградами.
class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.level});

  final LevelDef level;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  int _countdown = 3;
  bool _running = false;
  bool _finished = false;
  GameOutcome? _outcome;
  TestReward? _reward;
  bool _sending = false;
  Timer? _timer;
  late final DateTime _startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        setState(() {
          _countdown = 0;
          _running = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _finish(GameOutcome outcome) async {
    if (_finished) return;
    setState(() {
      _finished = true;
      _running = false;
      _outcome = outcome;
      _sending = true;
    });
    final controller = GameScope.read(context);
    final reward = await controller.submitTest(
      levelId: widget.level.id,
      score: outcome.score,
      stars: outcome.stars,
      pairs: outcome.pairs,
      moves: outcome.moves,
      errors: outcome.errors,
      durationMs: DateTime.now().difference(_startedAt).inMilliseconds,
    );
    if (!mounted) return;
    controller.audio.rewardSound();
    setState(() {
      _reward = reward;
      _sending = false;
    });
  }

  void _sound(String kind) {
    final audio = GameScope.read(context).audio;
    switch (kind) {
      case 'reward':
        audio.rewardSound();
        break;
      case 'crystal':
        audio.crystalSound();
        break;
      case 'error':
        audio.tapSound();
        break;
      default:
        audio.tapSound();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final state = controller.state;
    final palette = paletteOf(context);
    if (state == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final assets = <String>{
      ...state.pets.map((p) => p.asset),
      ...?controller.config?.pets.map((p) => p.asset),
    }.toList();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SceneBackground(asset: _background(widget.level.type), veil: 0.45, blur: 2),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  _Header(
                    level: widget.level,
                    onExit: () => Navigator.of(context).pop(),
                    onRestart: _running
                        ? null
                        : () {
                            Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                              builder: (_) => PlayScreen(level: widget.level),
                            ));
                          },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        if (_running && !_finished) _game(assets, state),
                        if (_countdown > 0) _Countdown(value: _countdown, palette: palette, level: widget.level),
                        if (_finished) _ResultCard(
                          level: widget.level,
                          outcome: _outcome!,
                          reward: _reward,
                          sending: _sending,
                          onAgain: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                            builder: (_) => PlayScreen(level: widget.level),
                          )),
                          onMap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _game(List<String> assets, GameState state) {
    switch (widget.level.type) {
      case 'match':
        return MatchGame(
          key: ValueKey('match-${widget.level.id}'),
          pairs: widget.level.param('pairs', 4),
          assets: assets,
          onFinish: _finish,
          onSound: _sound,
        );
      case 'odd':
        return OddGame(
          key: ValueKey('odd-${widget.level.id}'),
          rounds: widget.level.param('rounds', 4),
          cells: widget.level.param('cells', 6),
          assets: assets,
          onFinish: _finish,
          onSound: _sound,
        );
      case 'firefly':
        return FireflyGame(
          key: ValueKey('firefly-${widget.level.id}'),
          targets: widget.level.param('targets', 6),
          seconds: widget.level.param('seconds', 26),
          onFinish: _finish,
          onSound: _sound,
        );
      case 'simon':
        return SimonGame(
          key: ValueKey('simon-${widget.level.id}'),
          sequence: widget.level.param('seq', 4),
          onFinish: _finish,
          onSound: _sound,
        );
      default:
        return CountGame(
          key: ValueKey('count-${widget.level.id}'),
          rounds: widget.level.param('rounds', 5),
          seconds: widget.level.param('seconds', 3),
          onFinish: _finish,
          onSound: _sound,
        );
    }
  }

  static String _background(String type) => switch (type) {
        'match' => 'assets/bg/collection.webp',
        'odd' => 'assets/bg/world.webp',
        'firefly' => 'assets/bg/world.webp',
        'simon' => 'assets/bg/cosmic.webp',
        _ => 'assets/bg/cosmic_portrait.webp',
      };
}

class _Header extends StatelessWidget {
  const _Header({required this.level, required this.onExit, required this.onRestart});

  final LevelDef level;
  final VoidCallback onExit;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RoundIconButton(
          icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white),
          onTap: onExit,
          size: 40,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Уровень ${level.id} · ${level.typeLabel}', style: AppText.tiny),
              Text(level.name, style: AppText.h1, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        RoundIconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
          onTap: onRestart ?? () {},
          size: 40,
        ),
      ],
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.value, required this.palette, required this.level});

  final int value;
  final Palette palette;
  final LevelDef level;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              key: ValueKey(value),
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeOutBack,
              builder: (context, v, child) => Transform.scale(scale: v, child: child),
              child: Text(
                '$value',
                style: TextStyle(fontSize: 92, fontWeight: FontWeight.w900, color: palette.accent, height: 1),
              ),
            ),
            const SizedBox(height: 6),
            Text(level.tip, textAlign: TextAlign.center, style: AppText.body),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Приготовьтесь', style: AppText.small),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.level,
    required this.outcome,
    required this.reward,
    required this.sending,
    required this.onAgain,
    required this.onMap,
  });

  final LevelDef level;
  final GameOutcome outcome;
  final TestReward? reward;
  final bool sending;
  final VoidCallback onAgain;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final state = reward?.state ?? controller.state;
    final pet = state?.activePet;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.42),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: FadeInUp(
            child: GamePanel(
              padding: const EdgeInsets.all(16),
              radius: 24,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: OrientationBuilder(
                  builder: (context, orientation) {
                    final portrait = orientation == Orientation.portrait;
                    final petBlock = pet == null
                        ? null
                        : SizedBox(
                            width: portrait ? 96 : 120,
                            child: Column(
                              children: [
                                Image.asset(pet.asset, height: portrait ? 78 : 110, fit: BoxFit.contain),
                                Text(pet.name, style: AppText.small, textAlign: TextAlign.center),
                                const SizedBox(height: 2),
                                if (reward != null)
                                  Text('+${reward!.xp} XP',
                                      style: const TextStyle(
                                          fontSize: 11, color: Palette.gold, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          );
                    final detailsColumn = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Тренировка пройдена', style: AppText.tiny),
                          Text(level.name, style: AppText.h1),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              StarRow(stars: outcome.stars, size: 30, animate: true),
                              const SizedBox(width: 10),
                              Text('${outcome.score} / 100',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (sending)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                  SizedBox(width: 8),
                                  Text('Сервер проверяет результат…', style: AppText.small),
                                ],
                              ),
                            )
                          else if (reward != null)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _RewardPill(icon: const CoinIcon(size: 14), label: '+${reward!.coins}', color: Palette.gold),
                                _RewardPill(icon: GemIcon(size: 14), label: '+${reward!.gems}', color: Palette.sky),
                                _RewardPill(icon: const Icon(Icons.pets, size: 14, color: Palette.mint), label: '+${reward!.xp} XP', color: Palette.mint),
                                if (reward!.petLevels.isNotEmpty)
                                  _RewardPill(
                                    icon: const StarShape(filled: true, size: 14),
                                    label: 'Уровень ${reward!.petLevels.last}!',
                                    color: Palette.violet,
                                  ),
                                if (reward!.evoItems.isNotEmpty)
                                  _RewardPill(
                                    icon: const Icon(Icons.upgrade_rounded, size: 14, color: Palette.rose),
                                    label: 'Предмет эволюции',
                                    color: Palette.rose,
                                  ),
                              ],
                            )
                          else
                            Text('Нет связи: результат не зачтён — сервер не подтвердил награду. '
                                'Проверьте интернет и попробуйте снова.',
                                style: AppText.small),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: GameButton(label: 'Ещё раз', tone: ButtonTone.plain, height: 46, onTap: onAgain),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GameButton(
                                  label: 'К тренировкам',
                                  tone: ButtonTone.gold,
                                  height: 46,
                                  onTap: onMap,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    if (portrait) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (pet != null && petBlock != null)
                            Row(
                              children: [
                                petBlock,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(pet.title, style: AppText.small, maxLines: 2),
                                      const SizedBox(height: 4),
                                      Text(
                                        pet.maxLevel
                                            ? 'Максимальный уровень'
                                            : '${pet.xp} / ${pet.xpNeeded} XP',
                                        style: AppText.tiny,
                                      ),
                                      const SizedBox(height: 4),
                                      ProgressBar(value: pet.progress, height: 7),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          if (petBlock != null) const SizedBox(height: 8),
                          detailsColumn,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (petBlock != null) petBlock,
                        if (petBlock != null) const SizedBox(width: 14),
                        Expanded(child: detailsColumn),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.icon, required this.label, required this.color});

  final Widget icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.7), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }
}
