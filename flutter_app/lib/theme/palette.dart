import 'package:flutter/material.dart';

/// Палитра мира внимания. Тема интерфейса может быть переопределена предметом.
class Palette {
  const Palette({
    required this.id,
    required this.name,
    required this.deep,
    required this.mid,
    required this.bright,
    required this.accent,
    required this.panel,
    required this.soft,
  });

  final String id;
  final String name;
  final Color deep;
  final Color mid;
  final Color bright;
  final Color accent;
  final Color panel;
  final Color soft;

  static const gold = Color(0xFFFFD36A);
  static const goldDeep = Color(0xFFF29B1D);
  static const mint = Color(0xFF7BE495);
  static const rose = Color(0xFFFF8FBE);
  static const sky = Color(0xFF7FD8FF);
  static const violet = Color(0xFFC07BFF);
  static const ink = Color(0xFF3A1766);
  static const paper = Color(0xFFFFF7E6);

  static const violetTheme = Palette(
    id: 'ui_violet',
    name: 'Фиолетовая тема',
    deep: Color(0xFF2A1046),
    mid: Color(0xFF45206F),
    bright: Color(0xFF8A4FD0),
    accent: Color(0xFFFFD36A),
    panel: Color(0xFF3A1A63),
    soft: Color(0xFF6B3AA8),
  );

  static const mintTheme = Palette(
    id: 'ui_mint',
    name: 'Мятная тема',
    deep: Color(0xFF0C2E28),
    mid: Color(0xFF16483C),
    bright: Color(0xFF2FA98A),
    accent: Color(0xFFFFE7A8),
    panel: Color(0xFF175344),
    soft: Color(0xFF2C7A63),
  );

  static const goldTheme = Palette(
    id: 'ui_gold',
    name: 'Золотая тема',
    deep: Color(0xFF3A2408),
    mid: Color(0xFF6B4310),
    bright: Color(0xFFC98A2A),
    accent: Color(0xFFFFF3C4),
    panel: Color(0xFF5C3A0E),
    soft: Color(0xFF8C5B1C),
  );

  static const all = <Palette>[violetTheme, mintTheme, goldTheme];

  static Palette byId(String? id) {
    return all.firstWhere((p) => p.id == id, orElse: () => violetTheme);
  }

  LinearGradient get background => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [mid, deep],
      );

  LinearGradient get button => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.lerp(bright, Colors.white, 0.18)!, bright],
      );
}

/// Пять редкостей: цвет, подпись и порядок.
class RarityStyle {
  const RarityStyle({
    required this.id,
    required this.label,
    required this.color,
    required this.order,
    required this.rate,
    required this.dupGems,
    required this.glow,
  });

  final String id;
  final String label;
  final Color color;
  final int order;
  final double rate;
  final int dupGems;

  /// Цвет свечения при раскрытии яйца: серебро, изумруд, синий, фиолет, золото.
  final Color glow;

  static const common = RarityStyle(
    id: 'common',
    label: 'Обычный',
    color: Color(0xFF9FB6D9),
    order: 0,
    rate: 50,
    dupGems: 2,
    glow: Color(0xFFE7EEFF),
  );
  static const uncommon = RarityStyle(
    id: 'uncommon',
    label: 'Необычный',
    color: Color(0xFF6BDD8F),
    order: 1,
    rate: 25,
    dupGems: 4,
    glow: Color(0xFF62F0A0),
  );
  static const rare = RarityStyle(
    id: 'rare',
    label: 'Редкий',
    color: Color(0xFF5FAFFF),
    order: 2,
    rate: 15,
    dupGems: 8,
    glow: Color(0xFF63C2FF),
  );
  static const epic = RarityStyle(
    id: 'epic',
    label: 'Эпический',
    color: Color(0xFFC07BFF),
    order: 3,
    rate: 8,
    dupGems: 20,
    glow: Color(0xFFD08BFF),
  );
  static const legendary = RarityStyle(
    id: 'legendary',
    label: 'Легендарный',
    color: Color(0xFFFFB93E),
    order: 4,
    rate: 2,
    dupGems: 60,
    glow: Color(0xFFFFD76A),
  );

  static const all = <RarityStyle>[common, uncommon, rare, epic, legendary];

  static RarityStyle byId(String id) =>
      all.firstWhere((r) => r.id == id, orElse: () => common);
}
