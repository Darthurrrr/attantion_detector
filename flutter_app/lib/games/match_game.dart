import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/game_ui.dart';
import 'outcome.dart';

/// «Найди пару»: карточки с питомцами, серии и бонус за три пары подряд.
class MatchGame extends StatefulWidget {
  const MatchGame({
    super.key,
    required this.pairs,
    required this.assets,
    required this.onFinish,
    required this.onSound,
  });

  final int pairs;
  final List<String> assets;
  final void Function(GameOutcome outcome) onFinish;
  final void Function(String sound) onSound;

  @override
  State<MatchGame> createState() => _MatchGameState();
}

class _MatchGameState extends State<MatchGame> with TickerProviderStateMixin {
  late final List<_Card> _cards;
  final List<int> _open = [];
  int _moves = 0;
  int _matched = 0;
  int _streak = 0;
  int _bonus = 0;
  bool _locked = false;
  bool _comboToast = false;
  Timer? _timer;
  Timer? _clock;
  int _seconds = 0;
  final _startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cards = _buildDeck();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds = DateTime.now().difference(_startedAt).inSeconds);
    });
  }

  List<_Card> _buildDeck() {
    final rand = math.Random();
    final source = widget.assets.isEmpty ? const ['assets/pets/slime.png'] : widget.assets;
    final pool = [...source]..shuffle(rand);
    final chosen = <String>[];
    for (var i = 0; i < widget.pairs; i++) {
      chosen.add(pool[i % pool.length]);
    }
    final deck = <_Card>[
      for (var i = 0; i < chosen.length; i++) ...[
        _Card(id: i, asset: chosen[i], pair: chosen[i]),
        _Card(id: i + 1000, asset: chosen[i], pair: chosen[i]),
      ],
    ]..shuffle(rand);
    return deck;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  void _tap(int index) {
    if (_locked) return;
    final card = _cards[index];
    if (card.faceUp || card.done) return;
    widget.onSound('tap');
    setState(() => card.faceUp = true);
    _open.add(index);
    if (_open.length < 2) return;

    _moves++;
    final first = _cards[_open[0]];
    final second = _cards[_open[1]];
    if (first.pair == second.pair) {
      _timer?.cancel();
      setState(() {
        first.done = true;
        second.done = true;
        _matched++;
        _streak++;
        _open.clear();
      });
      widget.onSound('reward');
      if (_streak % 3 == 0) {
        final plus = math.min(12, 4 + (_streak ~/ 3 - 1) * 2);
        setState(() {
          _bonus += plus;
          _comboToast = true;
        });
        widget.onSound('crystal');
        Future<void>.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) setState(() => _comboToast = false);
        });
      }
      if (_matched == widget.pairs) _finish();
      return;
    }

    _locked = true;
    setState(() => _streak = 0);
    _timer = Timer(const Duration(milliseconds: 620), () {
      if (!mounted) return;
      setState(() {
        first.faceUp = false;
        second.faceUp = false;
        _open.clear();
        _locked = false;
      });
    });
  }

  void _finish() {
    final score = Scoring.match(pairs: widget.pairs, moves: _moves, seconds: _seconds) + _bonus;
    final clamped = score.clamp(0, 100).toInt();
    widget.onFinish(GameOutcome(
      score: clamped,
      stars: Scoring.stars(clamped),
      pairs: widget.pairs,
      moves: _moves,
      errors: math.max(0, _moves - widget.pairs),
      details: {'bonus': _bonus},
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
              _Stat(label: 'Пары', value: '$_matched/${widget.pairs}', color: Palette.mint),
              const SizedBox(width: 6),
              _Stat(label: 'Ходы', value: '$_moves', color: Palette.sky),
              const SizedBox(width: 6),
              _Stat(label: 'Время', value: '${_seconds}s', color: Palette.gold),
              const SizedBox(width: 6),
              _Stat(label: 'Серия', value: '$_streak', color: Palette.rose),
              if (_bonus > 0) ...[
                const SizedBox(width: 6),
                _Stat(label: 'Бонус', value: '+$_bonus', color: Palette.violet),
              ],
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final count = _cards.length;
                  final columns = count <= 8 ? 4 : count <= 12 ? 4 : 5;
                  final rows = (count / columns).ceil();
                  final gap = 7.0;
                  final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
                  final height = math.min((constraints.maxHeight - gap * (rows - 1)) / rows, width * 1.12);
                  return Center(
                    child: SizedBox(
                      width: width * columns + gap * (columns - 1),
                      height: height * rows + gap * (rows - 1),
                      child: Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (var i = 0; i < _cards.length; i++)
                            SizedBox(
                              width: width,
                              height: height,
                              child: _MemoryCard(
                                card: _cards[i],
                                palette: palette,
                                onTap: () => _tap(i),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (_comboToast)
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 320),
                    builder: (context, v, child) => Opacity(
                      opacity: v,
                      child: Transform.scale(scale: 0.8 + v * 0.25, child: child),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFFF3A8), Color(0xFFF9A91F)]),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 22)],
                      ),
                      child: Text('Серия ×$_streak! Бонус к счёту',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Palette.ink)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.55)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.tiny, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 1),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color, height: 1.05)),
          ],
        ),
      ),
    );
  }
}

class _Card {
  _Card({required this.id, required this.asset, required this.pair});
  final int id;
  final String asset;
  final String pair;
  bool faceUp = false;
  bool done = false;
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.card, required this.palette, required this.onTap});

  final _Card card;
  final Palette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final revealed = card.faceUp || card.done;
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: revealed ? 0 : 1),
        duration: const Duration(milliseconds: 240),
        builder: (context, flip, child) {
          final showFront = flip < 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(flip.abs() < 0.15 ? 0.15 : 1.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: showFront
                      ? [palette.bright, palette.soft]
                      : [
                          Colors.white.withOpacity(card.done ? 0.36 : 0.22),
                          Colors.white.withOpacity(0.10),
                        ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: card.done ? Palette.mint : Colors.white.withOpacity(0.34),
                  width: card.done ? 2 : 1.4,
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: showFront
                  ? Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CustomPaint(painter: _PawPainter(Colors.white.withOpacity(0.55))),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(5),
                      child: Image.asset(card.asset, fit: BoxFit.contain),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _PawPainter extends CustomPainter {
  _PawPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.66), width: w * 0.56, height: h * 0.46), paint);
    for (var i = 0; i < 4; i++) {
      final dx = w * (0.24 + i * 0.175);
      canvas.drawCircle(Offset(dx, h * 0.30), w * 0.085, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PawPainter old) => old.color != color;
}
