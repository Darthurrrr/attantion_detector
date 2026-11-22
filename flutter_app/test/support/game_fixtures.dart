import 'package:attention_detector/data/models.dart';
import 'package:attention_detector/services/api.dart';
import 'package:attention_detector/services/audio.dart';
import 'package:attention_detector/services/device.dart';
import 'package:attention_detector/state/game_controller.dart';
import 'package:attention_detector/theme/palette.dart';

/// Тестовые данные не обращаются к серверу или нативному аудиоплагину.
class SilentAudio implements GameAudio {
  @override
  bool enabled = false;
  @override
  double volume = 0;
  @override
  Future<void> play(String asset, {double? gain}) async {}
  @override
  Future<void> tapSound() async {}
  @override
  Future<void> rewardSound() async {}
  @override
  Future<void> crystalSound() async {}
  @override
  Future<void> cuddleSound() async {}
  @override
  Future<void> transitionSound() async {}
  @override
  Future<void> legendaryFanfare() async {}
  @override
  Future<void> dispose() async {}
}

GameController makeController({String worldTheme = 'world_meadow'}) {
  final controller = GameController(
    api: Api(baseUrl: 'https://example.invalid'),
    audio: SilentAudio(),
    device: DeviceStore(),
  );
  controller.settingsHaptics = false;
  controller.state = GameState.fromJson({
    'player': {'name': 'Детектив', 'avatar': 'assets/hero_avatar.png', 'level': 1},
    'wallet': {'coins': 2000, 'gems': 220, 'eggs': 1},
    'activePetId': 'slime',
    'pets': [
      {'petId': 'slime', 'name': 'Гоша', 'title': 'Мягкий оптимист', 'asset': 'assets/pets/slime.png'},
    ],
    'items': <String>[],
    'equipped': <String>[],
    'themes': <String, dynamic>{'world': worldTheme},
    'daily': {'streak': 0, 'canClaim': true},
    'tasks': {'progress': <String, dynamic>{}, 'claimed': <String>[]},
    'events': <String, dynamic>{},
    'settings': {'sound': false},
  });
  controller.config = GameConfig(
    pets: const [
      PetCatalog(
        id: 'slime',
        name: 'Гоша',
        title: 'Мягкий оптимист',
        rarity: RarityStyle.common,
        asset: 'assets/pets/slime.png',
        desc: 'Питомец',
        stats: [40, 30, 50],
      ),
    ],
    levels: const [
      LevelDef(
        id: 1,
        type: 'match',
        name: 'Первые пары',
        tip: 'Запоминайте, где спрятались питомцы.',
        difficulty: 'easy',
        params: {'pairs': 4},
      ),
    ],
    chapters: const [],
    shop: const [],
    tasks: List.generate(5, (i) => {
      'id': 'task$i',
      'title': 'Пройдите тренировку ${i + 1}',
      'metric': 'games',
      'goal': i + 1,
      'coins': 80,
      'gems': 2,
    }),
    daily: [for (var i = 0; i < 6; i++) <String, dynamic>{}, {'pet': 'slime'}],
    events: [
      {
        'id': 'starter',
        'name': 'Первые шаги',
        'steps': [
          {'id': 'welcome', 'title': 'Знакомство', 'desc': 'Погладьте питомца', 'metric': 'pets_patted', 'goal': 1},
        ],
      },
    ],
    rules: {'eggPrice': 60},
  );
  return controller;
}
