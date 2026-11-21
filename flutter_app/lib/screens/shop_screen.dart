import 'package:flutter/material.dart';

import '../app/game_app.dart';
import '../data/models.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/ambient_effects.dart';
import '../widgets/game_ui.dart';
import '../widgets/top_bar.dart';

/// Магазин: яйца (с выбором количества) и предметы по категориям.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _category = 'eggs';
  int _eggCount = 1;

  static const _categories = [
    ('eggs', 'Яйца', Icons.egg_rounded),
    ('cosmetic', 'Косметика', Icons.auto_awesome_rounded),
    ('world', 'Темы мира', Icons.image_rounded),
    ('ui', 'Интерфейс', Icons.palette_rounded),
    ('collectible', 'Коллекция', Icons.diamond_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final state = controller.state;
    final cfg = controller.config;
    if (state == null || cfg == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final maxEggs = state.gems ~/ cfg.eggPrice;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SceneBackground(asset: 'assets/bg/shop_scene.webp', veil: 0.38, sparkles: true),
          SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                final portrait = orientation == Orientation.portrait;
                final items = cfg.shop.where((i) => i.kind == _category).toList();
                return Column(
                  children: [
                    GameTopBar(current: 'shop', compact: portrait),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                      child: Row(
                        children: [
                          Text('Магазин', style: AppText.h1),
                          const SizedBox(width: 10),
                          CurrencyPill(icon: const CoinIcon(size: 14), value: '${state.coins}', color: Palette.gold, compact: true),
                          const SizedBox(width: 6),
                          CurrencyPill(icon: GemIcon(size: 14), value: '${state.gems}', color: Palette.sky, compact: true),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        children: [
                          for (final category in _categories)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _CategoryChip(
                                label: category.$2,
                                icon: category.$3,
                                active: _category == category.$1,
                                onTap: () {
                                  controller.audio.tapSound();
                                  setState(() => _category = category.$1);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                        child: _category == 'eggs'
                            ? _EggShop(
                                state: state,
                                cfg: cfg,
                                count: _eggCount.clamp(1, maxEggs == 0 ? 1 : maxEggs).toInt(),
                                maxCount: maxEggs,
                                onCount: (v) => setState(() => _eggCount = v),
                                onBuy: () async {
                                  final count = _eggCount.clamp(1, maxEggs == 0 ? 1 : maxEggs).toInt();
                                  final ok = await controller.buyEggs(count);
                                  if (ok && mounted) setState(() => _eggCount = 1);
                                },
                              )
                            : items.isEmpty
                                ? Center(child: Text('Пока пусто — новинки скоро', style: AppText.small))
                                : GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: portrait ? 2 : 3,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      mainAxisExtent: portrait ? 260 : 236,
                                    ),
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      final owned = state.items.contains(item.id);
                                      return _ShopCard(
                                        item: item,
                                        owned: owned,
                                        equipped: state.equipped.contains(item.id) ||
                                            state.worldTheme == item.id ||
                                            state.uiTheme == item.id,
                                        onBuy: () => _preview(context, item, owned),
                                      );
                                    },
                                  ),
                      ),
                    ),
                    if (portrait) const GameBottomNav(current: 'shop'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _preview(BuildContext context, ShopItem item, bool owned) async {
    final controller = GameScope.read(context);
    controller.audio.tapSound();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Palette.violetTheme.panel,
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RarityBadge(rarity: item.rarity),
            const SizedBox(height: 6),
            SizedBox(height: 96, child: Image.asset(item.asset, fit: BoxFit.contain)),
            const SizedBox(height: 6),
            Text(item.name, style: AppText.h1, textAlign: TextAlign.center),
            Text(item.kindLabel, style: AppText.tiny),
            const SizedBox(height: 6),
            Text(item.desc, style: AppText.small, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(item.priceLabel, style: const TextStyle(color: Palette.gold, fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Закрыть')),
          if (owned)
            TextButton(
              onPressed: () => Navigator.of(context).pop('equip'),
              child: Text(item.kind == 'cosmetic' ? 'Надеть / снять' : 'Выбрать тему'),
            )
          else
            FilledButton(
              onPressed: () => Navigator.of(context).pop('buy'),
              child: const Text('Купить'),
            ),
        ],
      ),
    );
    if (!context.mounted || result == null) return;
    if (result == 'buy') {
      await controller.buyItem(item);
    } else if (result == 'equip') {
      final isEquipped = item.kind == 'cosmetic'
          ? controller.state!.equipped.contains(item.id)
          : (item.kind == 'world' ? controller.state!.worldTheme == item.id : controller.state!.uiTheme == item.id);
      await controller.equip(item.id, equipped: !isEquipped);
    }
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.icon, required this.active, required this.onTap});

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(colors: [palette.accent, Palette.goldDeep])
              : LinearGradient(colors: [Colors.white.withOpacity(0.14), Colors.white.withOpacity(0.06)]),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: active ? Colors.white : Colors.white.withOpacity(0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: active ? Palette.ink : Colors.white70),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: active ? Palette.ink : Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _EggShop extends StatelessWidget {
  const _EggShop({
    required this.state,
    required this.cfg,
    required this.count,
    required this.maxCount,
    required this.onCount,
    required this.onBuy,
  });

  final GameState state;
  final GameConfig cfg;
  final int count;
  final int maxCount;
  final void Function(int) onCount;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final total = count * cfg.eggPrice;
    final showcase = GamePanel(
      child: Column(
        children: [
          Text('Универсальное яйцо', style: AppText.h1, textAlign: TextAlign.center),
          Text('Один тип яйца на все редкости', style: AppText.tiny, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: FloatingArt(
                child: Image.asset('assets/ui/egg_0.png', fit: BoxFit.contain),
              ),
            ),
          ),
          Text(
            '${cfg.eggPrice} кристаллов за штуку',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.gold, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
    final controls = GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Сколько яиц?', style: AppText.h2),
          const SizedBox(height: 8),
          Row(
            children: [
              RoundIconButton(
                icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 20),
                tooltip: 'Уменьшить количество',
                size: 40,
                onTap: () => onCount((count - 1).clamp(1, maxCount == 0 ? 1 : maxCount).toInt()),
              ),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      '$count',
                      key: ValueKey(count),
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: palette.accent, height: 1),
                    ),
                  ),
                ),
              ),
              RoundIconButton(
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                tooltip: 'Увеличить количество',
                size: 40,
                onTap: () => onCount((count + 1).clamp(1, maxCount == 0 ? 1 : maxCount).toInt()),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            maxCount == 0
                ? 'Недостаточно кристаллов даже на одно яйцо'
                : 'Можно купить максимум: $maxCount',
            style: AppText.tiny,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GemIcon(size: 16),
              const SizedBox(width: 5),
              Text('Итого: $total', style: AppText.h2),
            ],
          ),
          const SizedBox(height: 10),
          GameButton(
            label: 'Купить',
            tone: ButtonTone.gold,
            height: 46,
            enabled: maxCount > 0 && total <= state.gems,
            onTap: onBuy,
          ),
          const SizedBox(height: 6),
          Text('Яйца попадут в инвентарь. Открыть их можно во вкладке «Призыв».',
              style: AppText.tiny, textAlign: TextAlign.center),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return ListView(
            children: [
              SizedBox(height: 230, child: showcase),
              const SizedBox(height: 10),
              controls,
            ],
          );
        }
        // На невысоких экранах содержимое остаётся доступным прокруткой.
        final height = constraints.maxHeight < 300 ? 300.0 : constraints.maxHeight;
        return SingleChildScrollView(
          child: SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 4, child: showcase),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: controls),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.item, required this.owned, required this.equipped, required this.onBuy});

  final ShopItem item;
  final bool owned;
  final bool equipped;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBuy,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [item.rarity.color.withOpacity(0.28), Colors.black.withOpacity(0.32)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: equipped ? Palette.mint : item.rarity.color.withOpacity(0.7),
            width: equipped ? 2 : 1.3,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                RarityBadge(rarity: item.rarity, compact: true),
                const Spacer(),
                if (equipped)
                  const Icon(Icons.check_circle_rounded, size: 16, color: Palette.mint)
                else if (owned)
                  const Icon(Icons.check_rounded, size: 15, color: Colors.white54),
              ],
            ),
            Expanded(child: Image.asset(item.asset, fit: BoxFit.contain)),
            Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h2),
            Text(item.desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.tiny),
            const SizedBox(height: 4),
            Row(
              children: [
                if (item.currency == 'coins') const CoinIcon(size: 14) else GemIcon(size: 14),
                const SizedBox(width: 5),
                Text('${item.price}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13)),
                const Spacer(),
                Text(owned ? 'Куплено' : 'Купить', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: owned ? Palette.mint : Palette.gold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
