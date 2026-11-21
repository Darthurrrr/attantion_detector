import 'package:attention_detector/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _state(Map<String, dynamic> overrides) => {
      'player': {
        'name': 'Тест',
        'avatar': 'assets/hero_avatar.png',
        'level': 2,
        'xp': 40,
        'xpNeeded': 180,
        'isAdmin': false,
        'createdAt': '2026-11-20T10:00:00+00:00',
      },
      'wallet': {'coins': 100, 'gems': 60, 'eggs': 2},
      'activePetId': 'slime',
      'pets': [
        {
          'petId': 'slime',
          'name': 'Слизень Гоша',
          'title': 'Мягкий оптимист',
          'rarity': 'common',
          'asset': 'assets/pets/slime.png',
          'desc': '',
          'stats': [42, 30, 55],
          'level': 33,
          'xp': 5,
          'xpNeeded': 31,
          'form': 1,
          'evoItems': 1,
          'maxLevel': false,
          'canEvolve': true,
        },
      ],
      'items': ['world_meadow'],
      'equipped': <String>[],
      'themes': {'world': 'world_meadow', 'ui': 'ui_violet'},
      'pity': {'epic': 0, 'legendary': 0, 'total': 0},
      'history': <dynamic>[],
      'daily': {'streak': 0, 'canClaim': true},
      'tasks': {
        'progress': {'games': 1},
        'claimed': <String>[],
      },
      'events': <String, dynamic>{},
      'settings': {'sound': true, 'volume': 0.8},
      'petsPatted': 3,
      ...overrides,
    };

void main() {
  test('состояние читается из ответа сервера', () {
    final state = GameState.fromJson(_state({}));
    expect(state.coins, 100);
    expect(state.gems, 60);
    expect(state.pets, hasLength(1));
    expect(state.activePet?.petId, 'slime');
    expect(state.activePet?.canEvolve, isTrue);
    expect(state.petsPatted, 3);
    expect(state.dailyCanClaim, isTrue);
  });

  test('опыт и прогресс формы', () {
    final pet = GameState.fromJson(_state({})).pets.first;
    expect(pet.progress, closeTo(5 / 31, 0.0001));
    expect(pet.formLabel, 'Первая форма');
  });

  test('неизвестная редкость не роняет парсинг', () {
    final raw = _state({});
    (raw['pets'] as List)[0]['rarity'] = 'unknown';
    final state = GameState.fromJson(raw);
    expect(state.pets.first.rarity.id, 'common');
  });

  test('активный питомец падает на первого при отсутствии совпадения', () {
    final raw = _state({'activePetId': 'ghost'});
    final state = GameState.fromJson(raw);
    expect(state.activePet?.petId, 'slime');
  });
}
