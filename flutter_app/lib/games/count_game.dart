import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/game_ui.dart';
import 'outcome.dart';

/// «Посчитай искры»: искры вспыхивают, затем игрок выбирает число.
class CountGame extends StatefulWidget {
  const CountGame({
    super.key,
    required this.rounds,
    required this.seconds,
    required this.onFinish,
    required this.onSound,
  });

  final int rounds;
  final int seconds;
  final void Function(GameOutcome outcome) onFinish;
  final void Function(String sound) onSound;

  @override
  State<CountGame> createState() => _CountGameState();
}

class _CountGameState extends State<CountGame> {
  final _rand = math.Random();
  int _round = 0;
  int _correct = 0;
  int _answer = 0;
  List<Offset> _sparks = const [];
  List<int> _options = const [];
  bool _showing = false;
  bool _answered = false;
  int? _picked;
  int _answerStart = 0;
  int _totalAnswerMs = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRound() {
    final count = 4 + _round + _rand.nextInt(3);
    _answer = count;
    _sparks = _spread(count);
    final options = <int>{count};
    while (options.length < 4) {
      final candidate = count + _rand.nextInt(7) - 3;
      if (candidate > 1) options.add(candidate);
    }
    _options = options.toList()..shuffle(_rand);
    setState(() {
      _showing = true;
      _answered = false;
      _picked = null;
    });
    _timer = Timer(Duration(seconds: widget.seconds), () {
      if (!mounted) return;
      setState(() {
        _showing = false;
        _answerStart = DateTime.now().millisecondsSinceEpoch;
      });
      widget.onSound('crystal');
    });
  }

  List<Offset> _spread(int count) {
    final points = <Offset>[];
    var attempts = 0;
    while (points.length < count && attempts < 400) {
      attempts++;
      final p = Offset(0.12 + _rand.nextDouble() * 0.76, 0.14 + _rand.nextDouble() * 0.7);
      if (points.every((q) => (q - p).distance > 0.15)) points.add(p);
    }
    return points;
  }

  void _pick(int value) {
    if (!_answered && (value == 0 || _showing)) return;
    if (_answered) return;
    final ms = DateTime.now().millisecondsSinceEpoch - _answerStart;
    _totalAnswerMs += ms;
    final correct = value == _answer;
    if (correct) _correct++;
    widget.onSound(correct ? 'reward' : 'tap');
    setState(() {
      _answered = true;
      _picked = value;
    });
    _timer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_round + 1 >= widget.rounds) {
        _finish();
        return;
      }
      setState(() => _round++);
      _startRound();
    });
  }

  void _finish() {
    final per = _totalAnswerMs ~/ widget.rounds;
    final score = Scoring.count(correct: _correct, rounds: widget.rounds, msPerRound: per);
    widget.onFinish(GameOutcome(
      score: score,
      stars: Scoring.stars(score),
      errors: widget.rounds - _correct,
      moves: widget.rounds,
      details: {'correct': _correct, 'msPerRound': per},
    ));
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<GamePaletteExt>()?.palette ?? Palette.violetTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Palette.mint.withOpacity(0.6)),
                ),
                child: Text('Раунд ${_round + 1}/${widget.rounds}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Expanded(child: ProgressBar(value: (_round + (_answered ? 1 : 0)) / widget.rounds, height: 9)),
              const SizedBox(width: 8),
              Text('Счёт: $_correct', style: AppText.tiny),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.deep, palette.mid],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return Stack(
                    children: [
                      Positioned.fill(child: CustomPaint(painter: _SkyPainter(palette))),
                      if (_showing)
                        for (final p in _sparks)
                          Positioned(
                            left: p.dx * size.width - 18,
                            top: p.dy * size.height - 18,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.4, end: 1),
                              duration: const Duration(milliseconds: 520),
                              curve: Curves.easeOutBack,
                              builder: (context, v, _) => Transform.scale(
                                scale: v,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(colors: [
                                      Colors.white,
                                      Palette.gold.withOpacity(0.85),
                                      Palette.gold.withOpacity(0),
                                    ]),
                                    boxShadow: [BoxShadow(color: Palette.gold.withOpacity(0.75), blurRadius: 14)],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      if (!_showing && !_answered)
                        const Positioned.fill(child: Center(child: Text('Сколько искр было?', style: AppText.h1))),
                      if (_answered)
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: _picked == _answer ? Palette.mint : Palette.rose,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _picked == _answer ? 'Точно!' : 'Почти',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: _picked == _answer ? Palette.mint : Palette.rose,
                                    ),
                                  ),
                                  Text('Искр было: $_answer', style: AppText.body),
                                  const SizedBox(height: 2),
                                  Text('Считайте вспышки по группам — так проще', style: AppText.tiny),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < _options.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _AnswerButton(
                  value: _options[i],
                  enabled: !_showing && !_answered,
                  picked: _picked == _options[i],
                  correct: _answered && _options[i] == _answer,
                  onTap: () => _pick(_options[i]),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.value,
    required this.enabled,
    required this.picked,
    required this.correct,
    required this.onTap,
  });

  final int value;
  final bool enabled;
  final bool picked;
  final bool correct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = correct
        ? ButtonTone.mint
        : picked
            ? ButtonTone.violet
            : ButtonTone.plain;
    return GameButton(
      label: '$value',
      tone: tone,
      height: 48,
      fontSize: 18,
      enabled: enabled,
      onTap: onTap,
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.palette);
  final Palette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(11);
    final paint = Paint();
    for (var i = 0; i < 46; i++) {
      final dx = rand.nextDouble() * size.width;
      final dy = rand.nextDouble() * size.height;
      final r = 0.8 + rand.nextDouble() * 1.8;
      paint.color = Colors.white.withOpacity(0.18 + rand.nextDouble() * 0.4);
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [palette.bright.withOpacity(0.35), palette.bright.withOpacity(0)],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.55), radius: size.shortestSide * 0.7));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glow);
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) => old.palette != palette;
}
