import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/game_ui.dart';
import 'outcome.dart';

/// «Поймай светлячков»: золотые — цели, фиолетовые — обманки.
class FireflyGame extends StatefulWidget {
  const FireflyGame({
    super.key,
    required this.targets,
    required this.seconds,
    required this.onFinish,
    required this.onSound,
  });

  final int targets;
  final int seconds;
  final void Function(GameOutcome outcome) onFinish;
  final void Function(String sound) onSound;

  @override
  State<FireflyGame> createState() => _FireflyGameState();
}

class _FireflyState {
  _FireflyState({
    required this.id,
    required this.isDecoy,
    required this.position,
    required this.phase,
    required this.speed,
  });

  final int id;
  final bool isDecoy;
  Offset position;
  double phase;
  final double speed;
  bool caught = false;
}

class _FireflyGameState extends State<FireflyGame> with SingleTickerProviderStateMixin {
  final _rand = math.Random();
  final List<_FireflyState> _flies = [];
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  int _caught = 0;
  int _decoys = 0;
  late int _remaining = widget.seconds;
  Timer? _second;
  bool _done = false;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    _second = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_done) return;
      setState(() => _remaining--);
      if (_remaining <= 0) _finish();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _second?.cancel();
    super.dispose();
  }

  void _spawn(Size size) {
    _size = size;
    if (_flies.isNotEmpty) return;
    for (var i = 0; i < 9; i++) {
      _flies.add(_FireflyState(
        id: i,
        isDecoy: i % 3 == 2,
        position: Offset(
          40 + _rand.nextDouble() * math.max(20.0, size.width - 80),
          40 + _rand.nextDouble() * math.max(20.0, size.height - 80),
        ),
        phase: _rand.nextDouble() * math.pi * 2,
        speed: 0.5 + _rand.nextDouble() * 0.7,
      ));
    }
  }

  void _tick(Duration elapsed) {
    if (_done || _flies.isEmpty) return;
    final dt = (elapsed - _last).inMilliseconds / 1000.0;
    _last = elapsed;
    setState(() {
      for (final fly in _flies) {
        if (fly.caught) continue;
        fly.phase += dt * fly.speed;
        final dx = math.cos(fly.phase * 1.3) * 40 * dt;
        final dy = math.sin(fly.phase * 1.7) * 55 * dt;
        fly.position = Offset(
          (fly.position.dx + dx).clamp(28.0, math.max(28.0, _size.width - 28)).toDouble(),
          (fly.position.dy + dy).clamp(28.0, math.max(28.0, _size.height - 28)).toDouble(),
        );
      }
    });
  }

  void _catch(_FireflyState fly) {
    if (_done || fly.caught) return;
    if (fly.isDecoy) {
      widget.onSound('tap');
      _decoys++;
      setState(() => fly.caught = true);
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (mounted && !_done) setState(() => fly.caught = false);
      });
      return;
    }
    widget.onSound('crystal');
    setState(() {
      fly.caught = true;
      _caught++;
    });
    if (_caught >= widget.targets) {
      _finish();
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted && !_done) setState(() => fly.caught = false);
    });
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _ticker.stop();
    _second?.cancel();
    final score = Scoring.firefly(targets: widget.targets, caught: _caught, decoys: _decoys);
    widget.onFinish(GameOutcome(
      score: score,
      stars: Scoring.stars(score),
      errors: _decoys,
      moves: _caught,
      details: {'caught': _caught},
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
              _Badge(icon: Icons.circle, label: 'Цели', value: '$_caught/${widget.targets}', color: Palette.gold),
              const SizedBox(width: 6),
              _Badge(icon: Icons.warning_amber_rounded, label: 'Обманки', value: '$_decoys', color: Palette.violet),
              const SizedBox(width: 8),
              Expanded(child: ProgressBar(value: _caught / widget.targets, height: 10)),
              const SizedBox(width: 8),
              _Badge(icon: Icons.timer_rounded, label: '', value: '${_remaining}s', color: _remaining <= 6 ? Palette.rose : Palette.sky),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              _spawn(size);
              return ClipRRect(
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
                  child: Stack(
                    children: [
                      Positioned.fill(child: CustomPaint(painter: _MeadowPainter(palette))),
                      for (final fly in _flies) _FlyWidget(fly: fly, onTap: () => _catch(fly)),
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

class _FlyWidget extends StatelessWidget {
  const _FlyWidget({required this.fly, required this.onTap});

  final _FireflyState fly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = fly.isDecoy ? Palette.violet : Palette.gold;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 120),
      left: fly.position.dx - 24,
      top: fly.position.dy - 24,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: fly.caught ? 0.05 : 1,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [color.withOpacity(0.55), color.withOpacity(0)]),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [Colors.white, color]),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.85), blurRadius: 12, spreadRadius: 2)],
                  ),
                ),
                Positioned(
                  top: 6,
                  child: Opacity(
                    opacity: 0.7,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 9, height: 6, decoration: BoxDecoration(color: color.withOpacity(0.6), borderRadius: BorderRadius.circular(4))),
                        const SizedBox(width: 3),
                        Container(width: 9, height: 6, decoration: BoxDecoration(color: color.withOpacity(0.6), borderRadius: BorderRadius.circular(4))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.value, required this.color});

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          if (label.isNotEmpty) ...[Text('$label ', style: AppText.tiny), const SizedBox(width: 2)],
          Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class _MeadowPainter extends CustomPainter {
  _MeadowPainter(this.palette);
  final Palette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(7);
    final paint = Paint()..color = Colors.white.withOpacity(0.12);
    for (var i = 0; i < 60; i++) {
      final dx = rand.nextDouble() * size.width;
      final dy = rand.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), rand.nextDouble() * 1.8, paint);
    }
    final grass = Paint()..color = palette.bright.withOpacity(0.18);
    for (var i = 0; i < 26; i++) {
      final x = rand.nextDouble() * size.width;
      final h = 14 + rand.nextDouble() * 26;
      final path = Path()
        ..moveTo(x, size.height)
        ..quadraticBezierTo(x + 6, size.height - h * 0.6, x + 2, size.height - h);
      canvas.drawPath(path, grass..style = PaintingStyle.stroke..strokeWidth = 2.2);
    }
  }

  @override
  bool shouldRepaint(covariant _MeadowPainter old) => old.palette != palette;
}
