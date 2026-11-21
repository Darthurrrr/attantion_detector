import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/game_app.dart';
import '../data/models.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/game_ui.dart';
import '../widgets/top_bar.dart';

/// Инвентарь: яйца, косметика, темы и коллекционные предметы.
/// Питомцев здесь нет — они в коллекции.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final state = controller.state;
    final cfg = controller.config;
    if (state == null || cfg == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final palette = paletteOf(context);
    final ownedItems = cfg.shop.where((item) => state.items.contains(item.id)).toList();
    final cosmetics = ownedItems.where((i) => i.kind == 'cosmetic').toList();
    final worlds = ownedItems.where((i) => i.kind == 'world').toList();
    final uis = ownedItems.where((i) => i.kind == 'ui').toList();
    final collectibles = ownedItems.where((i) => i.kind == 'collectible').toList();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SceneBackground(asset: 'assets/bg/collection.webp', veil: 0.55, blur: 2),
          SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                final portrait = orientation == Orientation.portrait;
                return Column(
                  children: [
                    GameTopBar(current: 'inventory', compact: portrait),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                      child: Row(
                        children: [
                          Text('Инвентарь', style: AppText.h1),
                          const Spacer(),
                          Text('Открывать яйца — во вкладке «Призыв»', style: AppText.tiny),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _EggRow(state: state),
                              const SizedBox(height: 10),
                              _ActivePetStrip(state: state),
                              const SizedBox(height: 10),
                              _Section(
                                title: 'Косметика питомца',
                                items: cosmetics,
                                state: state,
                                onTap: (item) => _toggle(context, item),
                                empty: 'Купите эффекты в магазине — они добавляют сияние вокруг питомца.',
                              ),
                              const SizedBox(height: 10),
                              _Section(
                                title: 'Темы мира',
                                items: worlds,
                                state: state,
                                onTap: (item) => controller.equip(item.id, equipped: true),
                                empty: 'Темы мира меняют фон игровой сцены.',
                              ),
                              const SizedBox(height: 10),
                              _Section(
                                title: 'Темы интерфейса',
                                items: uis,
                                state: state,
                                onTap: (item) => controller.equip(item.id, equipped: true),
                                empty: 'Темы интерфейса меняют палитру кнопок и панелей.',
                              ),
                              const SizedBox(height: 10),
                              _Section(
                                title: 'Коллекционные предметы',
                                items: collectibles,
                                state: state,
                                onTap: null,
                                empty: 'Уникальные предметы за достижения и события.',
                              ),
                              const SizedBox(height: 12),
                              GamePanel(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.extension_rounded, size: 18, color: Palette.gold),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Дубликаты предметов автоматически превращаются в монеты, дубликаты питомцев — в кристаллы.',
                                        style: AppText.tiny,
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
                    if (portrait) const GameBottomNav(current: 'inventory'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(BuildContext context, ShopItem item) async {
    final controller = GameScope.read(context);
    final equipped = controller.state!.equipped.contains(item.id);
    await controller.equip(item.id, equipped: !equipped);
  }
}

/// Питомец с надетой косметикой: видно, как эффекты смотрятся вместе.
class _ActivePetStrip extends StatelessWidget {
  const _ActivePetStrip({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final pet = state.activePet;
    if (pet == null) return const SizedBox.shrink();
    final effects = state.equipped;
    return GamePanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(96, 96),
                  painter: _CosmeticAura(effects: effects),
                ),
                Image.asset(pet.asset, fit: BoxFit.contain),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Активный питомец', style: AppText.tiny),
                Text('${pet.name} · ур. ${pet.level}', style: AppText.h2),
                const SizedBox(height: 2),
                Text(
                  effects.isEmpty
                      ? 'Эффекты не надеты — выберите косметику ниже'
                      : 'Надето эффектов: ${effects.length}',
                  style: AppText.small,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Лёгкая аура косметики: пузырьки, искры, звёзды, огонь, нимб.
class _CosmeticAura extends CustomPainter {
  _CosmeticAura({required this.effects});

  final List<String> effects;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    if (effects.isEmpty) return;
    for (final effect in effects) {
      final color = switch (effect) {
        'cosmo_bubbles' => Palette.sky,
        'cosmo_sparks' => Palette.gold,
        'cosmo_stars' => Palette.violet,
        'cosmo_fire' => const Color(0xFFFF8F6B),
        _ => Palette.gold,
      };
      if (effect == 'cosmo_halo') {
        final halo = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = color.withOpacity(0.85);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(center.dx, center.dy - size.height * 0.34), width: size.width * 0.42, height: size.height * 0.14),
          halo,
        );
        continue;
      }
      final glow = Paint()
        ..shader = RadialGradient(colors: [color.withOpacity(0.35), color.withOpacity(0)])
            .createShader(Rect.fromCircle(center: center, radius: size.shortestSide * 0.5));
      canvas.drawCircle(center, size.shortestSide * 0.5, glow);
      final dot = Paint()..color = color.withOpacity(0.9);
      for (var i = 0; i < 6; i++) {
        final angle = i * 1.05 + effect.length;
        final radius = size.shortestSide * (0.3 + (i % 3) * 0.06);
        canvas.drawCircle(
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
          1.8 + (i % 2),
          dot,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CosmeticAura old) => old.effects.length != effects.length;
}

class _EggRow extends StatelessWidget {
  const _EggRow({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return GamePanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(height: 74, child: Image.asset('assets/ui/egg_0.png', fit: BoxFit.contain)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Универсальные яйца', style: AppText.h2),
                Text('В инвентаре: ${state.eggs} шт.', style: AppText.small),
                const SizedBox(height: 2),
                Text('Открыть яйцо можно только во вкладке «Призыв».', style: AppText.tiny),
              ],
            ),
          ),
          GameButton(
            label: 'К призыву',
            tone: ButtonTone.gold,
            height: 38,
            width: 116,
            fontSize: 12,
            onTap: () => GameTopBar.open(context, 'summon'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.state,
    required this.onTap,
    required this.empty,
  });

  final String title;
  final List<ShopItem> items;
  final GameState state;
  final void Function(ShopItem)? onTap;
  final String empty;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return GamePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppText.h2),
              const Spacer(),
              Text('${items.length}', style: AppText.tiny),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(empty, style: AppText.small)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in items)
                  _ItemTile(
                    item: item,
                    equipped: state.equipped.contains(item.id) ||
                        state.worldTheme == item.id ||
                        state.uiTheme == item.id,
                    onTap: onTap == null ? null : () => onTap!(item),
                    palette: palette,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.equipped, required this.onTap, required this.palette});

  final ShopItem item;
  final bool equipped;
  final VoidCallback? onTap;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: item.rarity.color.withOpacity(0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: equipped ? Palette.mint : item.rarity.color.withOpacity(0.6), width: equipped ? 2 : 1.2),
        ),
        child: Column(
          children: [
            SizedBox(height: 40, child: Image.asset(item.asset, fit: BoxFit.contain)),
            Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(
              onTap == null ? 'коллекция' : (equipped ? 'надето' : 'надеть'),
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: equipped ? Palette.mint : Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
