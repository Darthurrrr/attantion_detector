import 'package:flutter/material.dart';

import '../app/game_app.dart';
import '../data/models.dart';
import '../screens/admin_screen.dart';
import '../screens/collection_screen.dart';
import '../screens/events_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/trainings_screen.dart';
import '../screens/shop_screen.dart';
import '../screens/summon_screen.dart';
import '../theme/app_text.dart';
import '../widgets/game_ui.dart';

/// Верхняя панель в горизонтальной композиции: профиль, кошелёк, навигация.
class GameTopBar extends StatelessWidget {
  const GameTopBar({
    super.key,
    required this.current,
    this.compact = false,
  });

  final String current;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final state = controller.state;
    final palette = paletteOf(context);
    if (state == null) return const SizedBox.shrink();

    final navItems = <_NavItem>[
      _NavItem('home', 'Главная', Icons.home_rounded, null),
      _NavItem('map', 'Тренировки', Icons.play_circle_fill_rounded, null),
      _NavItem('collection', 'Коллекция', Icons.pets_rounded, null),
      _NavItem('summon', 'Призыв', Icons.auto_awesome_rounded, state.eggs),
      _NavItem('shop', 'Магазин', Icons.storefront_rounded, null),
      _NavItem('inventory', 'Инвентарь', Icons.backpack_rounded, null),
      _NavItem('events', 'События', Icons.event_available_rounded, _eventBadge(state)),
      _NavItem('profile', 'Профиль', Icons.person_rounded, null),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 6 : 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.deep.withOpacity(0.94), palette.mid.withOpacity(0.82)],
        ),
        border: Border(bottom: BorderSide(color: palette.accent.withOpacity(0.28), width: 1.4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => GameTopBar.open(context, 'profile'),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: compact ? 34 : 38,
                    height: compact ? 34 : 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [palette.bright, palette.soft]),
                      border: Border.all(color: palette.accent.withOpacity(0.8), width: 1.6),
                    ),
                    child: Image.asset(state.avatar, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person)),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.name,
                      style: TextStyle(fontSize: compact ? 12 : 13, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    Row(
                      children: [
                        Text('Ур. ${state.level}', style: AppText.tiny),
                        const SizedBox(width: 6),
                        SizedBox(width: compact ? 42 : 54, child: ProgressBar(value: state.accountProgress, height: 5)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CurrencyPill(icon: const CoinIcon(size: 15), value: '${state.coins}', color: Palette.gold, compact: compact),
          const SizedBox(width: 6),
          CurrencyPill(
            icon: GemIcon(size: 15),
            value: '${state.gems}',
            color: Palette.sky,
            compact: compact,
            onTap: () => GameTopBar.open(context, 'shop'),
          ),
          const SizedBox(width: 6),
          CurrencyPill(
            icon: EggIcon(size: 15),
            value: '${state.eggs}',
            color: Palette.violet,
            compact: compact,
            onTap: () => GameTopBar.open(context, 'summon'),
          ),
          const Spacer(),
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: [
                  for (final item in navItems)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: _NavButton(item: item, active: current == item.key, compact: compact),
                    ),
                  if (state.isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _NavButton(
                        item: const _NavItem('admin', 'Админ', Icons.settings_suggest_rounded, null),
                        active: current == 'admin',
                        compact: compact,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static int _eventBadge(GameState state) {
    final active = state.eventClaims['starter'] ?? const <String, bool>{};
    return active.values.where((v) => v).isEmpty ? 1 : 0;
  }

  static void open(BuildContext context, String key) {
    final controller = GameScope.read(context);
    controller.audio.transitionSound();
    if (key == 'home') {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    final Widget page;
    switch (key) {
      case 'map':
        page = const TrainingsScreen();
      case 'collection':
        page = const CollectionScreen();
      case 'summon':
        page = const SummonScreen();
      case 'shop':
        page = const ShopScreen();
      case 'inventory':
        page = const InventoryScreen();
      case 'events':
        page = const EventsScreen();
      case 'profile':
        page = const ProfileScreen();
      case 'admin':
        page = const AdminScreen();
      default:
        page = const TrainingsScreen();
    }
    Navigator.of(context).push(_route(page));
  }

  static Route<void> _route(Widget page) => PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation),
            child: page,
          ),
        ),
      );
}

class _NavItem {
  const _NavItem(this.key, this.label, this.icon, this.badge);
  final String key;
  final String label;
  final IconData icon;
  final int? badge;
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.active, required this.compact});

  final _NavItem item;
  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return Tooltip(
      message: item.label,
      child: GestureDetector(
        onTap: () => GameTopBar.open(context, item.key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 6 : 7),
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(colors: [palette.accent, Palette.goldDeep])
                : LinearGradient(colors: [Colors.white.withOpacity(0.14), Colors.white.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: active ? Colors.white.withOpacity(0.85) : Colors.white.withOpacity(0.18),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: compact ? 15 : 16, color: active ? Palette.ink : Colors.white.withOpacity(0.92)),
              if (!compact) ...[
                const SizedBox(width: 5),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: active ? Palette.ink : Colors.white.withOpacity(0.92),
                  ),
                ),
              ],
              if ((item.badge ?? 0) > 0)
                Container(
                  margin: const EdgeInsets.only(left: 5),
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: Color(0xFFFF5B7A), shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Нижняя навигация для вертикальной ориентации.
class GameBottomNav extends StatelessWidget {
  const GameBottomNav({super.key, required this.current});

  final String current;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final items = <_NavItem>[
      const _NavItem('home', 'Главная', Icons.home_rounded, null),
      const _NavItem('map', 'Тренировки', Icons.play_circle_fill_rounded, null),
      const _NavItem('collection', 'Коллекция', Icons.pets_rounded, null),
      const _NavItem('summon', 'Призыв', Icons.auto_awesome_rounded, null),
      const _NavItem('profile', 'Профиль', Icons.person_rounded, null),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [palette.mid.withOpacity(0.95), palette.deep]),
        border: Border(top: BorderSide(color: palette.accent.withOpacity(0.3), width: 1.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final item in items)
            Expanded(
              child: GestureDetector(
                onTap: () => GameTopBar.open(context, item.key),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color: current == item.key ? palette.accent : Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: current == item.key ? palette.accent : Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
