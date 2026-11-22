import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ambient_effects.dart';
import 'game_ui.dart';

/// Локальная миниатюра новой поляны; серверные цены и данные не меняются.
String worldPreviewAsset(String itemId, String fallback) =>
    itemId == 'world_meadow' ? 'assets/bg/meadow_landscape.webp' : fallback;

/// Ориентационные фоны и независимые декоративные планы игровых сцен.
/// Внутри нет ни элементов управления, ни логики игры.
class LayeredScene extends StatelessWidget {
  const LayeredScene.meadow({super.key}) : _summon = false;
  const LayeredScene.summon({super.key}) : _summon = true;

  final bool _summon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final portrait = height >= width;
        final background = _summon
            ? (portrait ? 'assets/bg/summon_portrait.webp' : 'assets/bg/summon_landscape.webp')
            : (portrait ? 'assets/bg/meadow_portrait.webp' : 'assets/bg/meadow_landscape.webp');
        final islandWidth = math.min(width * (portrait ? 0.18 : 0.12), height * 0.22);

        return IgnorePointer(
          child: ExcludeSemantics(
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SceneBackground(asset: background, veil: _summon ? 0.28 : 0.18, sparkles: true),
                  if (!_summon)
                    Positioned(
                      left: width * (portrait ? 0.10 : 0.37),
                      top: height * (portrait ? 0.22 : 0.18),
                      width: islandWidth,
                      child: FloatingArt(
                        distance: 4,
                        duration: const Duration(seconds: 7),
                        child: Image.asset(
                          'assets/layers/floating_island.png',
                          key: const ValueKey('meadow-floating-island'),
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Передний план поляны. Расположен по краям сцены, не заслоняя питомца.
class MeadowForeground extends StatelessWidget {
  const MeadowForeground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(125.0, math.min(constraints.maxWidth * 0.22, constraints.maxHeight * 0.42));
            return ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    bottom: 0,
                    width: width,
                    child: Image.asset('assets/layers/meadow_foreground.png', fit: BoxFit.contain, excludeFromSemantics: true),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    width: width * 0.82,
                    child: Transform.flip(
                      flipX: true,
                      child: Image.asset('assets/layers/meadow_foreground.png', fit: BoxFit.contain, excludeFromSemantics: true),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Отдельные кристаллы вокруг единственного универсального яйца.
class SummonStageCrystals extends StatelessWidget {
  const SummonStageCrystals({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(105.0, math.min(constraints.maxWidth * 0.21, constraints.maxHeight * 0.38));
            final bottom = constraints.maxHeight * 0.14;
            return ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: constraints.maxWidth * 0.03,
                    bottom: bottom,
                    width: width,
                    child: FloatingArt(
                      distance: 3,
                      duration: const Duration(seconds: 6),
                      child: Image.asset(
                        'assets/layers/summon_crystals.png',
                        key: const ValueKey('summon-crystal-left'),
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                  Positioned(
                    right: constraints.maxWidth * 0.03,
                    bottom: bottom * 1.3,
                    width: width * 0.82,
                    child: FloatingArt(
                      distance: 2,
                      duration: const Duration(seconds: 8),
                      child: Transform.flip(
                        flipX: true,
                        child: Image.asset(
                          'assets/layers/summon_crystals.png',
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
