import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/game_ui.dart';
import 'outcome.dart';

/// «Найди лишнего»: один питомец отличается цветом, поворотом или размером.
class OddGame extends StatefulWidget {
  const OddGame({
    super.key,
    required this.rounds,
    required this.cells,
    required this.assets,
    required this.onFinish,
    required this.onSound,
  });

  final int rounds;
  final int cells;
  final List<String> assets;
  final void Function(GameOutcome outcome) onFinish;
  final void Function(String sound) onSound;

  @override
  State<OddGame> createState() => _OddGameState();
}

class _OddGameState extends State<OddGame> {
  final _rand = math.Random();
  int _round = 0;
  int _errors = 0;
  int _oddIndex = 0;
  String _asset = '';
  int _variant = 0;
  int _roundStart = DateTime.now().millisecondsSinceEpoch;
  int _totalMs = 0;
  int _wrongTap = -1;

  @override
  void initState() {
    super.initState();
    _nextRound();
  }

  void _nextRound() {
    final assets = widget.assets.isEmpty ? const ['assets/pets/slime.png'] : widget.assets;
    _asset = assets[_rand.nextInt(assets.length)];
    _oddIndex = _rand.nextInt(widget.cells);
    _variant = _rand.nextInt(3);
    _roundStart = DateTime.now().millisecondsSinceEpoch;
    _wrongTap = -1;
  }

  void _tap(int index) {
    if (index != _oddIndex) {
      widget.onSound('tap');
      setState(() {
        _errors++;
        _wrongTap = index;
      });
      Timer(const Duration(milliseconds: 380), () {
        if (mounted) setState(() => _wrongTap = -1);
      });
      return;
    }
    widget.onSound('reward');
    _totalMs += DateTime.now().millisecondsSinceEpoch - _roundStart;
    final next = _round + 1;
    if (next >= widget.rounds) {
      final per = _totalMs ~/ widget.rounds;
      final score = Scoring.odd(rounds: widget.rounds, errors: _errors, msPerRound: per);
      widget.onFinish(GameOutcome(
        score: score,
        stars: Scoring.stars(score),
        errors: _errors,
        moves: widget.rounds,
        details: {'msPerRound': per},
      ));
      return;
    }
    setState(() {
      _round = next;
      _nextRound();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<GamePaletteExt>()?.palette ?? Palette.violetTheme;
    final columns = widget.cells <= 6 ? 3 : widget.cells <= 9 ? 3 : 4;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              _Chip(label: 'Раунд', value: '${_round + 1}/${widget.rounds}', color: Palette.sky),
              const SizedBox(width: 6),
              _Chip(label: 'Ошибки', value: '$_errors', color: Palette.rose),
              const SizedBox(width: 6),
              Expanded(
                child: ProgressBar(value: (_round + 1) / widget.rounds, height: 10, colors: const [Palette.mint, Color(0xFF2FA98A)]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rows = (widget.cells / columns).ceil();
              final gap = 8.0;
              final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
              final height = math.min((constraints.maxHeight - gap * (rows - 1)) / rows, width);
              return Center(
                child: SizedBox(
                  width: width * columns + gap * (columns - 1),
                  height: height * rows + gap * (rows - 1),
                  child: Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (var i = 0; i < widget.cells; i++)
                        SizedBox(
                          width: width,
                          height: height,
                          child: _OddCell(
                            asset: _asset,
                            odd: i == _oddIndex,
                            variant: _variant,
                            palette: palette,
                            wrong: _wrongTap == i,
                            onTap: () => _tap(i),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ', style: AppText.tiny),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class _OddCell extends StatelessWidget {
  const _OddCell({
    required this.asset,
    required this.odd,
    required this.variant,
    required this.palette,
    required this.wrong,
    required this.onTap,
  });

  final String asset;
  final bool odd;
  final int variant;
  final Palette palette;
  final bool wrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Отличие: 0 — поворот, 1 — цвет, 2 — размер.
    final scale = odd && variant == 2 ? 1.16 : 1.0;
    final rotation = odd && variant == 0 ? math.pi : 0.0;
    final tint = odd && variant == 1 ? const Color(0xFFFF8FBE) : null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.06)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: wrong ? const Color(0xFFFF6B7F) : Colors.white.withOpacity(0.24),
            width: wrong ? 2.4 : 1.3,
          ),
        ),
        padding: const EdgeInsets.all(6),
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: tint == null
                ? Image.asset(asset, fit: BoxFit.contain)
                : ColorFiltered(
                    colorFilter: ColorFilter.mode(tint.withOpacity(0.55), BlendMode.srcATop),
                    child: Image.asset(asset, fit: BoxFit.contain),
                  ),
          ),
        ),
      ),
    );
  }
}
