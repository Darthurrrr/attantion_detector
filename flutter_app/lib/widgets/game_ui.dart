import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../state/game_controller.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';

/// Главная «игровая» кнопка с бликом и лёгким нажатием.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.width,
    this.height = 52,
    this.tone = ButtonTone.gold,
    this.enabled = true,
    this.fontSize = 16,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget? icon;
  final double? width;
  final double height;
  final ButtonTone tone;
  final bool enabled;
  final double fontSize;

  @override
  State<GameButton> createState() => _GameButtonState();
}

enum ButtonTone { gold, violet, mint, plain }

class _GameButtonState extends State<GameButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<GamePaletteExt>()?.palette ?? Palette.violetTheme;
    final (colors, textColor, border) = switch (widget.tone) {
      ButtonTone.gold => (
          [const Color(0xFFFFF3A8), const Color(0xFFF9A91F)],
          Palette.ink,
          const Color(0xFFFFE9A0),
        ),
      ButtonTone.violet => (
          [Color.lerp(palette.bright, Colors.white, 0.35)!, palette.bright],
          Colors.white,
          Colors.white.withOpacity(0.55),
        ),
      ButtonTone.mint => (
          [const Color(0xFFB6FFD0), const Color(0xFF3FCB7A)],
          const Color(0xFF10402A),
          const Color(0xFFD6FFE6),
        ),
      ButtonTone.plain => (
          [Colors.white.withOpacity(0.18), Colors.white.withOpacity(0.10)],
          Colors.white,
          Colors.white.withOpacity(0.35),
        ),
    };
    final disabled = !widget.enabled || widget.onTap == null;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _down = true),
      onTapCancel: disabled ? null : () => setState(() => _down = false),
      onTapUp: disabled ? null : (_) => setState(() => _down = false),
      onTap: disabled ? null : widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 90),
        child: Opacity(
          opacity: disabled ? 0.5 : 1,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(widget.height / 2.4),
              border: Border.all(color: border, width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withOpacity(0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 3)),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 14,
                  right: 14,
                  top: 4,
                  child: Container(
                    height: widget.height * 0.18,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.34),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 8)],
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: widget.fontSize,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
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

/// Полупрозрачная игровая панель (стекло + рамка).
class GamePanel extends StatelessWidget {
  const GamePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 20,
    this.tint,
    this.border,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? tint;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (tint ?? Colors.white).withOpacity(0.18),
            (tint ?? Colors.white).withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border ?? Colors.white.withOpacity(0.24), width: 1.4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

/// Круглая иконка-кнопка для панелей навигации.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.badge,
    this.tooltip,
    this.highlight = false,
  });

  final Widget icon;
  final VoidCallback onTap;
  final double size;
  final int? badge;
  final String? tooltip;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: highlight
                ? [const Color(0xFFFFF0B0), const Color(0xFFF2A32A)]
                : [Colors.white.withOpacity(0.28), Colors.white.withOpacity(0.12)],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.4),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(child: icon),
            if (badge != null && badge! > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8425B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.4),
                  ),
                  child: Text(
                    badge! > 9 ? '9+' : '${badge!}',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Пилюля валюты: монеты, кристаллы, яйца.
class CurrencyPill extends StatelessWidget {
  const CurrencyPill({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    this.onTap,
    this.compact = false,
  });

  final Widget icon;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.32),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.7), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: compact ? 11.5 : 12.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Полоса прогресса с золотой заливкой.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.colors = const [Color(0xFFFFE58A), Color(0xFFF29B1D)],
    this.background,
    this.radius,
  });

  final double value;
  final double height;
  final List<Color> colors;
  final Color? background;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? height;
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: Container(
        height: height,
        color: background ?? Colors.black.withOpacity(0.35),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0).toDouble(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(r),
            ),
          ),
        ),
      ),
    );
  }
}

/// Бейдж редкости (цветная плашка с подписью).
class RarityBadge extends StatelessWidget {
  const RarityBadge({super.key, required this.rarity, this.compact = false});

  final RarityStyle rarity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 9, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: rarity.color.withOpacity(0.22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: rarity.color, width: 1.1),
      ),
      child: Text(
        rarity.label,
        style: TextStyle(
          fontSize: compact ? 9 : 10.5,
          fontWeight: FontWeight.w900,
          color: Color.lerp(rarity.color, Colors.white, 0.35),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Звёзды результата (своя отрисовка, без эмодзи-глифов).
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 22, this.max = 3});

  final int stars;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: StarShape(filled: i < stars, size: size),
        );
      }),
    );
  }
}

/// Векторная звезда: золотая при filled, тёмная при пустой.
class StarShape extends StatelessWidget {
  const StarShape({super.key, required this.filled, this.size = 22});

  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _StarPainter(filled: filled)),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter({required this.filled});
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = size.width / 2;
    final inner = outer * 0.46;
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isEven ? outer : inner;
      final x = cx + math.cos(angle) * radius;
      final y = cy + math.sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    if (filled) {
      final paint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF6C4), Color(0xFFF6A61C)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(path, paint);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.07
          ..color = const Color(0xFFC97A0B),
      );
    } else {
      canvas.drawPath(path, Paint()..color = Colors.black.withOpacity(0.35));
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withOpacity(0.28),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.filled != filled;
}

/// Сердечко для тёплых подписей (векторное, вместо эмодзи).
class HeartShape extends StatelessWidget {
  const HeartShape({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _HeartPainter()),
    );
  }
}

class _HeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w / 2, h * 0.92)
      ..cubicTo(w * -0.10, h * 0.52, w * 0.12, h * 0.02, w / 2, h * 0.28)
      ..cubicTo(w * 0.88, h * 0.02, w * 1.10, h * 0.52, w / 2, h * 0.92)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF9ECB), Color(0xFFE44A88)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.09
        ..color = const Color(0xFFC93A76),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Иконки в едином стиле: монета, кристалл, яйцо, звезда.
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 16});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF4B0), Color(0xFFF2A31F)],
        ),
        border: Border.all(color: const Color(0xFFB9740F), width: size * 0.08),
      ),
      child: Center(
        child: Text(
          'М',
          style: TextStyle(
            fontSize: size * 0.48,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF8A5406),
            height: 1,
          ),
        ),
      ),
    );
  }
}

class GemIcon extends StatelessWidget {
  const GemIcon({super.key, this.size = 16});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GemPainter()),
    );
  }
}

class _GemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.38)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.38)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB7F3FF), Color(0xFF3DA9F5)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, 0)
        ..lineTo(w * 0.5, h)
        ..moveTo(0, h * 0.38)
        ..lineTo(w, h * 0.38),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(0.55),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.07
        ..color = const Color(0xFF1B6BA8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EggIcon extends StatelessWidget {
  const EggIcon({super.key, this.size = 16});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 0.8,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(size), bottom: Radius.circular(size * 0.6)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFCF2), Color(0xFFE7D6FF)],
          ),
          border: Border.all(color: const Color(0xFF9F86C9), width: size * 0.07),
        ),
      ),
    );
  }
}

/// Фон игровой сцены: изображение мира без растяжения + мягкая виньетка.
class SceneBackground extends StatelessWidget {
  const SceneBackground({super.key, required this.asset, this.blur = 0, this.veil = 0.35});

  final String asset;
  final double blur;
  final double veil;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      asset,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (context, error, stack) => Container(color: Palette.violetTheme.deep),
    );
    if (blur > 0) image = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: image);
    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(veil * 0.5),
                Colors.black.withOpacity(veil),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Плавное появление снизу для карточек и панелей.
class FadeInUp extends StatefulWidget {
  const FadeInUp({super.key, required this.child, this.delay = 0, this.duration = 380});

  final Widget child;
  final int delay;
  final int duration;

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.duration),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(curve),
        child: widget.child,
      ),
    );
  }
}

/// Заголовок секции с линией.
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.text, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text, style: AppText.h2),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1.2, color: Colors.white.withOpacity(0.18))),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}

/// Тост-сообщение.
class ToastBanner extends StatelessWidget {
  const ToastBanner({super.key, required this.text, required this.tone});

  final String text;
  final ToastTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      ToastTone.good => Palette.mint,
      ToastTone.bad => const Color(0xFFFF8F9E),
      ToastTone.info => Palette.gold,
    };
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, (1 - value) * -14), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Color.lerp(Palette.violetTheme.deep, color, 0.28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.8), width: 1.4),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tone == ToastTone.bad ? Icons.priority_high_rounded : Icons.auto_awesome, size: 16, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white, height: 1.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Расширение для доступа к палитре из любого виджета.
class GamePaletteExt extends ThemeExtension<GamePaletteExt> {
  const GamePaletteExt({required this.palette});
  final Palette palette;

  @override
  GamePaletteExt copyWith({Palette? palette}) => GamePaletteExt(palette: palette ?? this.palette);

  @override
  GamePaletteExt lerp(ThemeExtension<GamePaletteExt>? other, double t) {
    if (other is! GamePaletteExt) return this;
    return GamePaletteExt(palette: t < 0.5 ? palette : other.palette);
  }
}
