import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ненавязчивые искры на фоне: не перехватывают касания и не влияют на игру.
class AmbientSparkles extends StatefulWidget {
  const AmbientSparkles({
    super.key,
    this.color = const Color(0xFFFFE7A3),
    this.count = 16,
  });

  final Color color;
  final int count;

  @override
  State<AmbientSparkles> createState() => _AmbientSparklesState();
}

class _AmbientSparklesState extends State<AmbientSparkles> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = !MediaQuery.of(context).disableAnimations && TickerMode.of(context);
    if (animate && !_clock.isAnimating) {
      _clock.repeat();
    } else if (!animate && _clock.isAnimating) {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: ClipRect(
            child: CustomPaint(painter: _SparklesPainter(_clock, widget.color, widget.count)),
          ),
        ),
      ),
    );
  }
}

class _SparklesPainter extends CustomPainter {
  _SparklesPainter(this.clock, this.color, this.count) : super(repaint: clock);

  final Animation<double> clock;
  final Color color;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < count; i++) {
      final phase = (clock.value + i * 0.137) % 1.0;
      final xFraction = 0.05 + ((i * 47 % 100) / 100) * 0.9;
      final yFraction = (0.10 + ((i * 71 % 100) / 100) * 0.8 - phase * 0.08 + 1) % 1.0;
      final center = Offset(size.width * xFraction, size.height * yFraction);
      final opacity = math.sin(phase * math.pi) * 0.52;
      final radius = 1.3 + (i % 3) * 0.55;
      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(center, radius, paint);
      if (i % 3 == 0) {
        paint.strokeWidth = 1.1;
        canvas.drawLine(center.translate(-radius * 2, 0), center.translate(radius * 2, 0), paint);
        canvas.drawLine(center.translate(0, -radius * 2), center.translate(0, radius * 2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklesPainter oldDelegate) =>
      oldDelegate.clock != clock || oldDelegate.color != color || oldDelegate.count != count;
}

/// Плавное левитирование иллюстрации без изменения её размеров и пропорций.
class FloatingArt extends StatefulWidget {
  const FloatingArt({
    super.key,
    required this.child,
    this.distance = 5,
    this.duration = const Duration(milliseconds: 3200),
  });

  final Widget child;
  final double distance;
  final Duration duration;

  @override
  State<FloatingArt> createState() => _FloatingArtState();
}

class _FloatingArtState extends State<FloatingArt> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this, duration: widget.duration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = !MediaQuery.of(context).disableAnimations && TickerMode.of(context);
    if (animate && !_clock.isAnimating) {
      _clock.repeat();
    } else if (!animate && _clock.isAnimating) {
      _clock.stop();
    }
  }

  @override
  void didUpdateWidget(covariant FloatingArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _clock.duration = widget.duration;
      if (_clock.isAnimating) _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _clock,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, math.sin(_clock.value * 2 * math.pi) * widget.distance),
        child: child,
      ),
    );
  }
}
