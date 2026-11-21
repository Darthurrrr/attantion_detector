import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/game_ui.dart';

/// Полноценная сцена открытия яйца: удары по скорлупе, силуэт, вспышка и
/// карточка получения. Результат уже подтверждён сервером до анимации.
class EggReveal extends StatefulWidget {
  const EggReveal({
    super.key,
    required this.results,
    required this.onDone,
    required this.onSound,
  });

  final List<SummonResult> results;
  final VoidCallback onDone;
  final void Function(String sound) onSound;

  @override
  State<EggReveal> createState() => _EggRevealState();
}

enum _RevealPhase { shell, silhouette, reveal }

class _EggRevealState extends State<EggReveal> with TickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);
  int _index = 0;
  int _hits = 0;
  _RevealPhase _phase = _RevealPhase.shell;
  final List<Offset> _trail = [];
  Timer? _advance;

  SummonResult get _current =>
      widget.results[_index < widget.results.length ? _index : widget.results.length - 1];

  @override
  void dispose() {
    _shake.dispose();
    _idle.dispose();
    _advance?.cancel();
    super.dispose();
  }

  void _hit(Offset local) {
    if (_phase != _RevealPhase.shell) return;
    setState(() {
      _trail.add(local);
      if (_trail.length > 12) _trail.removeAt(0);
      _hits++;
    });
    _shake.forward(from: 0);
    widget.onSound('tap');
    if (_hits >= 5) _toSilhouette();
  }

  void _toSilhouette() {
    setState(() => _phase = _RevealPhase.silhouette);
    widget.onSound('crystal');
    _advance = Timer(const Duration(milliseconds: 1100), _toReveal);
  }

  void _toReveal() {
    setState(() => _phase = _RevealPhase.reveal);
    if (_current.rarity.id == 'legendary') {
      widget.onSound('legendary');
    } else {
      widget.onSound('reward');
    }
  }

  void _next() {
    if (_index + 1 >= widget.results.length) {
      widget.onDone();
      return;
    }
    _advance?.cancel();
    setState(() {
      _index++;
      _hits = 0;
      _phase = _RevealPhase.shell;
      _trail.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rarity = _current.rarity;
    return Container(
      color: const Color(0xFF120525),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const SceneBackground(asset: 'assets/bg/summon.webp', veil: 0.55, blur: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  rarity.glow.withOpacity(_phase == _RevealPhase.shell ? 0.10 : 0.42),
                  Colors.transparent,
                ],
                radius: 0.9,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Row(
                    children: [
                      Text('Призыв ${_index + 1} из ${widget.results.length}', style: AppText.h2),
                      const Spacer(),
                      if (_phase == _RevealPhase.shell)
                        Text('Проведите пальцем по яйцу', style: AppText.tiny),
                      if (_phase != _RevealPhase.shell)
                        TextButton(
                          onPressed: _toReveal,
                          child: const Text('Пропустить', style: TextStyle(color: Colors.white70)),
                        ),
                      IconButton(
                        onPressed: widget.onDone,
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        tooltip: 'Закрыть',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stage = Size(constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (d) => _hit(d.localPosition),
                        onTapDown: (d) => _hit(d.localPosition),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_phase != _RevealPhase.reveal)
                              AnimatedBuilder(
                                animation: Listenable.merge([_shake, _idle]),
                                builder: (context, child) {
                                  final wobble = math.sin(_shake.value * math.pi * 6) * (1 - _shake.value) * 8;
                                  final breathe = math.sin(_idle.value * math.pi * 2) * 4;
                                  return Transform.translate(
                                    offset: Offset(wobble, breathe),
                                    child: Transform.rotate(angle: wobble * 0.004, child: child),
                                  );
                                },
                                child: SizedBox(
                                  height: math.min(stage.height * 0.62, 280),
                                  child: Image.asset(
                                    _eggAsset(_hits),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.egg_rounded, size: 120, color: Colors.white70),
                                  ),
                                ),
                              ),
                            if (_phase == _RevealPhase.silhouette) _Silhouette(asset: _current.asset, glow: rarity.glow),
                            if (_phase == _RevealPhase.reveal)
                              _PetCard(result: _current, onNext: _next, isLast: _index + 1 >= widget.results.length),
                            Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _TrailPainter(trail: _trail)))),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _eggAsset(int hits) {
    if (hits >= 4) return 'assets/ui/egg_8.png';
    if (hits >= 3) return 'assets/ui/egg_6.png';
    if (hits >= 2) return 'assets/ui/egg_4.png';
    if (hits >= 1) return 'assets/ui/egg_2.png';
    return 'assets/ui/egg_0.png';
  }
}

class _Silhouette extends StatelessWidget {
  const _Silhouette({required this.asset, required this.glow});

  final String asset;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          builder: (context, v, child) => Container(
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: glow.withOpacity(v * 0.9), blurRadius: 40 + v * 40, spreadRadius: v * 12)],
            ),
            child: child,
          ),
          child: SizedBox(
            height: 230,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcATop),
              child: Image.asset(asset, fit: BoxFit.contain),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1100),
          builder: (context, v, child) => Opacity(opacity: v, child: child),
          child: Text('Кто-то просыпается…', style: AppText.body),
        ),
      ],
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.result, required this.onNext, required this.isLast});

  final SummonResult result;
  final VoidCallback onNext;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final rarity = result.rarity;
    final legendary = rarity.id == 'legendary';
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.scale(scale: 0.82 + v * 0.18, child: Opacity(opacity: v.clamp(0, 1), child: child)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [rarity.color.withOpacity(0.42), const Color(0xFF1D0B33)],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: rarity.color, width: 2.4),
              boxShadow: [
                BoxShadow(color: rarity.glow.withOpacity(legendary ? 0.75 : 0.45), blurRadius: legendary ? 46 : 26, spreadRadius: legendary ? 8 : 2),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RarityBadge(rarity: rarity),
                const SizedBox(height: 6),
                Row(
                  children: [
                    SizedBox(
                      height: 150,
                      width: 130,
                      child: Image.asset(result.asset, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(result.isNew ? 'Получен питомец' : 'Дубликат', style: AppText.tiny),
                          Text(result.name, style: AppText.title, maxLines: 2),
                          Text(result.title, style: AppText.small),
                          const SizedBox(height: 8),
                          if (result.isNew)
                            _Line(text: 'Добавлен в коллекцию', color: Palette.mint)
                          else
                            _Line(text: '+${result.gems} кристаллов за дубликат', color: Palette.sky),
                          if (result.pity) _Line(text: 'Сработал гарант', color: Palette.gold),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GameButton(
                  label: isLast ? 'Забрать' : 'Дальше',
                  tone: ButtonTone.gold,
                  height: 46,
                  onTap: onNext,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color))),
        ],
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({required this.trail});
  final List<Offset> trail;

  @override
  void paint(Canvas canvas, Size size) {
    if (trail.length < 2) return;
    final path = Path()..moveTo(trail.first.dx, trail.first.dy);
    for (final point in trail.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          trail.first,
          trail.last,
          [Palette.gold.withOpacity(0), Palette.gold.withOpacity(0.9)],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) => old.trail.length != trail.length;
}
