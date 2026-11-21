import '../theme/palette.dart';

/// Питомец в коллекции игрока (данные приходят с сервера).
class Pet {
  const Pet({
    required this.petId,
    required this.name,
    required this.title,
    required this.rarity,
    required this.asset,
    required this.desc,
    required this.stats,
    required this.level,
    required this.xp,
    required this.xpNeeded,
    required this.form,
    required this.evoItems,
    required this.maxLevel,
    required this.canEvolve,
  });

  final String petId;
  final String name;
  final String title;
  final RarityStyle rarity;
  final String asset;
  final String desc;
  final List<int> stats;
  final int level;
  final int xp;
  final int xpNeeded;
  final int form;
  final int evoItems;
  final bool maxLevel;
  final bool canEvolve;

  static Pet fromJson(Map<String, dynamic> json) {
    return Pet(
      petId: json['petId'] as String,
      name: json['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      rarity: RarityStyle.byId(json['rarity'] as String? ?? 'common'),
      asset: json['asset'] as String? ?? 'assets/pets/slime.png',
      desc: json['desc'] as String? ?? '',
      stats: (json['stats'] as List<dynamic>? ?? const [0, 0, 0]).map((e) => (e as num).toInt()).toList(),
      level: (json['level'] as num?)?.toInt() ?? 1,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      xpNeeded: (json['xpNeeded'] as num?)?.toInt() ?? 0,
      form: (json['form'] as num?)?.toInt() ?? 1,
      evoItems: (json['evoItems'] as num?)?.toInt() ?? 0,
      maxLevel: json['maxLevel'] as bool? ?? false,
      canEvolve: json['canEvolve'] as bool? ?? false,
    );
  }

  double get progress => maxLevel || xpNeeded == 0 ? 1 : (xp / xpNeeded).clamp(0.0, 1.0).toDouble();

  String get formLabel => switch (form) {
        1 => 'Первая форма',
        2 => 'Вторая форма',
        _ => 'Третья форма',
      };
}

/// Каталог питомцев (из /api/config) — включая ещё не полученных.
class PetCatalog {
  const PetCatalog({
    required this.id,
    required this.name,
    required this.title,
    required this.rarity,
    required this.asset,
    required this.desc,
    required this.stats,
  });

  final String id;
  final String name;
  final String title;
  final RarityStyle rarity;
  final String asset;
  final String desc;
  final List<int> stats;

  static PetCatalog fromJson(Map<String, dynamic> json) => PetCatalog(
        id: json['id'] as String,
        name: json['name'] as String,
        title: json['title'] as String? ?? '',
        rarity: RarityStyle.byId(json['rarity'] as String),
        asset: json['asset'] as String,
        desc: json['desc'] as String? ?? '',
        stats: (json['stats'] as List<dynamic>? ?? const []).map((e) => (e as num).toInt()).toList(),
      );
}

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.rarity,
    required this.price,
    required this.currency,
    required this.asset,
    required this.desc,
    required this.layer,
  });

  final String id;
  final String name;
  final String kind;
  final RarityStyle rarity;
  final int price;
  final String currency;
  final String asset;
  final String desc;
  final String? layer;

  static ShopItem fromJson(Map<String, dynamic> json) => ShopItem(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: json['kind'] as String,
        rarity: RarityStyle.byId(json['rarity'] as String),
        price: (json['price'] as num).toInt(),
        currency: json['currency'] as String,
        asset: json['asset'] as String,
        desc: json['desc'] as String? ?? '',
        layer: json['layer'] as String?,
      );

  String get kindLabel => switch (kind) {
        'cosmetic' => 'Косметика',
        'world' => 'Тема мира',
        'ui' => 'Тема интерфейса',
        'collectible' => 'Коллекция',
        _ => 'Товар',
      };

  String get priceLabel => currency == 'coins' ? '$price монет' : '$price кристаллов';
}

class LevelDef {
  const LevelDef({
    required this.id,
    required this.type,
    required this.name,
    required this.tip,
    required this.difficulty,
    required this.params,
  });

  final int id;
  final String type;
  final String name;
  final String tip;
  final String difficulty;
  final Map<String, dynamic> params;

  int param(String key, int fallback) => (params[key] as num?)?.toInt() ?? fallback;

  static LevelDef fromJson(Map<String, dynamic> json) => LevelDef(
        id: (json['id'] as num).toInt(),
        type: json['type'] as String,
        name: json['name'] as String,
        tip: json['tip'] as String? ?? '',
        difficulty: json['difficulty'] as String? ?? 'easy',
        params: (json['params'] as Map<String, dynamic>?) ?? const {},
      );

  String get typeLabel => switch (type) {
        'match' => 'Найди пару',
        'odd' => 'Найди лишнего',
        'firefly' => 'Поймай светлячков',
        'simon' => 'Повтори мелодию',
        'count' => 'Посчитай искры',
        _ => 'Тренировка',
      };

  String get xpLabel => switch (difficulty) {
        'easy' => '20 XP',
        'medium' => '35 XP',
        'hard' => '50 XP',
        _ => '75 XP',
      };
}

class Chapter {
  const Chapter({required this.id, required this.name, required this.from, required this.to, required this.eggs, required this.gems});

  final int id;
  final String name;
  final int from;
  final int to;
  final int eggs;
  final int gems;

  static Chapter fromJson(Map<String, dynamic> json) {
    final reward = (json['reward'] as Map<String, dynamic>?) ?? const {};
    return Chapter(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      from: (json['from'] as num).toInt(),
      to: (json['to'] as num).toInt(),
      eggs: (reward['eggs'] as num?)?.toInt() ?? 0,
      gems: (reward['gems'] as num?)?.toInt() ?? 0,
    );
  }
}

class GameConfig {
  GameConfig({
    required this.pets,
    required this.levels,
    required this.chapters,
    required this.shop,
    required this.tasks,
    required this.daily,
    required this.events,
    required this.rules,
  });

  final List<PetCatalog> pets;
  final List<LevelDef> levels;
  final List<Chapter> chapters;
  final List<ShopItem> shop;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> daily;
  final List<Map<String, dynamic>> events;
  final Map<String, dynamic> rules;

  int get eggPrice => (rules['eggPrice'] as num?)?.toInt() ?? 60;

  static GameConfig fromJson(Map<String, dynamic> json) => GameConfig(
        pets: (json['pets'] as List<dynamic>).map((e) => PetCatalog.fromJson(e as Map<String, dynamic>)).toList(),
        levels: (json['levels'] as List<dynamic>).map((e) => LevelDef.fromJson(e as Map<String, dynamic>)).toList(),
        chapters: (json['chapters'] as List<dynamic>).map((e) => Chapter.fromJson(e as Map<String, dynamic>)).toList(),
        shop: (json['shop'] as List<dynamic>).map((e) => ShopItem.fromJson(e as Map<String, dynamic>)).toList(),
        tasks: (json['tasks'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        daily: (json['daily'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        events: (json['events'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        rules: Map<String, dynamic>.from(json['rules'] as Map),
      );
}

/// Состояние игрока: единственный источник данных для экранов.
class GameState {
  const GameState({
    required this.name,
    required this.avatar,
    required this.level,
    required this.xp,
    required this.xpNeeded,
    required this.isAdmin,
    required this.coins,
    required this.gems,
    required this.eggs,
    required this.activePetId,
    required this.pets,
    required this.items,
    required this.equipped,
    required this.worldTheme,
    required this.uiTheme,
    required this.pityEpic,
    required this.pityLegendary,
    required this.pityTotal,
    required this.history,
    required this.dailyStreak,
    required this.dailyCanClaim,
    required this.taskProgress,
    required this.taskClaimed,
    required this.eventClaims,
    required this.sound,
    required this.volume,
    required this.petsPatted,
    required this.createdAt,
  });

  final String name;
  final String avatar;
  final int level;
  final int xp;
  final int xpNeeded;
  final bool isAdmin;
  final int coins;
  final int gems;
  final int eggs;
  final String? activePetId;
  final List<Pet> pets;
  final List<String> items;
  final List<String> equipped;
  final String worldTheme;
  final String uiTheme;
  final int pityEpic;
  final int pityLegendary;
  final int pityTotal;
  final List<Map<String, dynamic>> history;
  final int dailyStreak;
  final bool dailyCanClaim;
  final Map<String, int> taskProgress;
  final List<String> taskClaimed;
  final Map<String, Map<String, bool>> eventClaims;
  final bool sound;
  final double volume;
  final int petsPatted;
  final DateTime? createdAt;

  Pet? get activePet {
    for (final pet in pets) {
      if (pet.petId == activePetId) return pet;
    }
    return pets.isEmpty ? null : pets.first;
  }

  bool owns(String petId) => pets.any((p) => p.petId == petId);

  double get accountProgress => xpNeeded == 0 ? 1 : (xp / xpNeeded).clamp(0.0, 1.0).toDouble();

  static GameState fromJson(Map<String, dynamic> json) {
    final player = json['player'] as Map<String, dynamic>;
    final wallet = json['wallet'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;
    final tasks = json['tasks'] as Map<String, dynamic>;
    final settings = json['settings'] as Map<String, dynamic>;
    final themes = json['themes'] as Map<String, dynamic>;
    final events = (json['events'] as Map<String, dynamic>?) ?? const {};
    return GameState(
      name: player['name'] as String? ?? 'Детектив',
      avatar: player['avatar'] as String? ?? 'assets/hero_avatar.png',
      level: (player['level'] as num?)?.toInt() ?? 1,
      xp: (player['xp'] as num?)?.toInt() ?? 0,
      xpNeeded: (player['xpNeeded'] as num?)?.toInt() ?? 100,
      isAdmin: player['isAdmin'] as bool? ?? false,
      coins: (wallet['coins'] as num?)?.toInt() ?? 0,
      gems: (wallet['gems'] as num?)?.toInt() ?? 0,
      eggs: (wallet['eggs'] as num?)?.toInt() ?? 0,
      activePetId: json['activePetId'] as String?,
      pets: (json['pets'] as List<dynamic>).map((e) => Pet.fromJson(e as Map<String, dynamic>)).toList(),
      items: (json['items'] as List<dynamic>).map((e) => e as String).toList(),
      equipped: (json['equipped'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
      worldTheme: themes['world'] as String? ?? 'world_meadow',
      uiTheme: themes['ui'] as String? ?? 'ui_violet',
      pityEpic: (json['pity']?['epic'] as num?)?.toInt() ?? 0,
      pityLegendary: (json['pity']?['legendary'] as num?)?.toInt() ?? 0,
      pityTotal: (json['pity']?['total'] as num?)?.toInt() ?? 0,
      history: (json['history'] as List<dynamic>? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      dailyStreak: (daily['streak'] as num?)?.toInt() ?? 0,
      dailyCanClaim: daily['canClaim'] as bool? ?? true,
      taskProgress: (tasks['progress'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, (v as num).toInt())),
      taskClaimed: (tasks['claimed'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
      eventClaims: events.map(
        (k, v) => MapEntry(
          k,
          Map<String, bool>.from(v as Map),
        ),
      ),
      sound: settings['sound'] as bool? ?? true,
      volume: (settings['volume'] as num?)?.toDouble() ?? 0.8,
      petsPatted: (json['petsPatted'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(player['createdAt'] as String? ?? ''),
    );
  }
}

class SummonResult {
  const SummonResult({
    required this.petId,
    required this.name,
    required this.title,
    required this.asset,
    required this.rarity,
    required this.isNew,
    required this.gems,
    required this.pity,
  });

  final String petId;
  final String name;
  final String title;
  final String asset;
  final RarityStyle rarity;
  final bool isNew;
  final int gems;
  final bool pity;

  static SummonResult fromJson(Map<String, dynamic> json) => SummonResult(
        petId: json['petId'] as String,
        name: json['name'] as String,
        title: json['title'] as String? ?? '',
        asset: json['asset'] as String,
        rarity: RarityStyle.byId(json['rarity'] as String),
        isNew: json['isNew'] as bool? ?? false,
        gems: (json['gems'] as num?)?.toInt() ?? 0,
        pity: json['pity'] as bool? ?? false,
      );
}

/// Результат теста: сервер считает награды, клиент показывает.
class TestReward {
  const TestReward({
    required this.coins,
    required this.gems,
    required this.xp,
    required this.petLevels,
    required this.evoItems,
    required this.state,
  });

  final int coins;
  final int gems;
  final int xp;
  final List<int> petLevels;
  final List<int> evoItems;
  final GameState state;
}
