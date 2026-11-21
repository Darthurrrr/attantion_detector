import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../services/api.dart';
import '../services/audio.dart';
import '../services/device.dart';

enum LoadPhase { booting, offline, ready, error }

/// Центральный контроллер: хранит подтверждённое сервером состояние,
/// отправляет действия и раздаёт звуки/тосты.
class GameController extends ChangeNotifier {
  GameController({required this.api, required this.audio, required this.device});

  final Api api;
  final GameAudio audio;
  final DeviceStore device;

  LoadPhase phase = LoadPhase.booting;
  String? errorText;
  GameConfig? config;
  GameState? state;

  final List<Toast> toasts = [];
  int _toastSeq = 0;

  // Локальный счётчик поглаживаний для гостевого режима.
  int offlinePats = 0;
  int offlineGames = 0;

  bool get ready => state != null && config != null;

  Future<void> boot() async {
    try {
      final rawConfig = await api.config();
      config = GameConfig.fromJson(rawConfig);
      final deviceId = await device.deviceId();
      String? token = await device.token();
      Map<String, dynamic> payload;
      if (token != null) {
        api.setToken(token);
        try {
          payload = await api.state();
        } on ApiError catch (e) {
          if (e.status == 401) {
            payload = await registerDevice(deviceId);
          } else {
            rethrow;
          }
        }
      } else {
        payload = await registerDevice(deviceId);
      }
      state = GameState.fromJson(payload);
      audio.enabled = state!.sound;
      audio.volume = state!.volume;
      phase = LoadPhase.ready;
    } on ApiError catch (e) {
      phase = LoadPhase.offline;
      errorText = e.message;
    } catch (_) {
      phase = LoadPhase.offline;
      errorText = 'Нет связи с сервером';
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> registerDevice(String deviceId) async {
    final result = await api.register(deviceId, name: 'Детектив');
    final token = result['token'] as String;
    await device.saveToken(token);
    api.setToken(token);
    return Map<String, dynamic>.from(result['state'] as Map);
  }

  Future<void> refresh() async {
    if (api.token == null) return;
    try {
      final payload = await api.state();
      state = GameState.fromJson(payload);
      notifyListeners();
    } on ApiError {
      // Молча: экран остаётся с последним подтверждённым состоянием.
    }
  }

  // ------------------------------------------------------------- утилиты
  void showToast(String text, {ToastTone tone = ToastTone.info}) {
    final toast = Toast(id: _toastSeq++, text: text, tone: tone);
    toasts.add(toast);
    if (toasts.length > 3) toasts.removeAt(0);
    notifyListeners();
    Future<void>.delayed(const Duration(milliseconds: 2900), () {
      toasts.removeWhere((t) => t.id == toast.id);
      notifyListeners();
    });
  }

  Future<T?> guard<T>(Future<T> Function() action, {bool sound = true}) async {
    try {
      if (sound) unawaitedTap();
      final result = await action();
      return result;
    } on ApiError catch (e) {
      showToast(e.message, tone: ToastTone.bad);
      return null;
    }
  }

  void unawaitedTap() {
    audio.tapSound();
  }

  /// Выход из локальной сессии: очищаем токен, следующий запуск создаст новую.
  Future<void> signOutLocally() async {
    await device.clearToken();
    api.setToken(null);
    phase = LoadPhase.booting;
    notifyListeners();
  }

  void _applyState(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      state = GameState.fromJson(payload);
      notifyListeners();
    }
  }

  // ------------------------------------------------------------- действия
  Future<bool> claimDaily() async {
    final result = await guard(() => api.claimDaily());
    if (result == null) return false;
    _applyState(result['state']);
    await audio.rewardSound();
    final reward = result['reward'] as Map<String, dynamic>;
    showToast(
      'День ${result['day']}: +${reward['coins']} монет, +${reward['gems']} кристаллов',
      tone: ToastTone.good,
    );
    if (result['pet'] != null) {
      showToast('Уникальный питомец добавлен в коллекцию!', tone: ToastTone.good);
    }
    return true;
  }

  Future<bool> claimTask(String taskId) async {
    final result = await guard(() => api.claimTask(taskId));
    if (result == null) return false;
    _applyState(result['state']);
    await audio.rewardSound();
    showToast('Награда за задание получена', tone: ToastTone.good);
    return true;
  }

  Future<bool> claimEvent(String eventId, String stepId) async {
    final result = await guard(() => api.claimEvent(eventId, stepId));
    if (result == null) return false;
    _applyState(result['state']);
    await audio.rewardSound();
    showToast('Награда события получена', tone: ToastTone.good);
    return true;
  }

  Future<bool> buyEggs(int count) async {
    final result = await guard(() => api.buyEggs(count));
    if (result == null) return false;
    await refresh();
    await audio.crystalSound();
    showToast('Куплено яиц: $count — они уже в инвентаре', tone: ToastTone.good);
    return true;
  }

  Future<bool> buyItem(ShopItem item) async {
    final result = await guard(() => api.buyItem(item.id));
    if (result == null) return false;
    _applyState(result['state']);
    await audio.rewardSound();
    if (result['duplicate'] == true) {
      showToast('Дубликат: +${result['coins']} монет', tone: ToastTone.good);
    } else {
      showToast('«${item.name}» теперь в инвентаре', tone: ToastTone.good);
    }
    return true;
  }

  Future<bool> equip(String itemId, {required bool equipped}) async {
    final result = await guard(() => api.equip(itemId, equipped: equipped));
    if (result == null) return false;
    _applyState(result);
    await audio.tapSound();
    return true;
  }

  Future<bool> setActivePet(String petId) async {
    final result = await guard(() => api.setActivePet(petId));
    if (result == null) return false;
    _applyState(result);
    await audio.cuddleSound();
    showToast('Активный питомец обновлён', tone: ToastTone.good);
    return true;
  }

  Future<bool> evolvePet(String petId) async {
    final result = await guard(() => api.evolve(petId));
    if (result == null) return false;
    _applyState(result['state']);
    await audio.rewardSound();
    showToast('Эволюция завершена! Новая форма и эксклюзивный эффект', tone: ToastTone.good);
    return true;
  }

  Future<void> patPet() async {
    offlinePats++;
    await audio.cuddleSound();
    if (api.token == null) return;
    try {
      await api.pat();
    } on ApiError {
      // Поглаживание не должно зависать при потере сети.
    }
  }

  Future<SummonOutcome?> summon(int count) async {
    final key = 'summon-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}';
    final result = await guard(() => api.summon(count, key));
    if (result == null) return null;
    final results = (result['results'] as List<dynamic>)
        .map((e) => SummonResult.fromJson(e as Map<String, dynamic>))
        .toList();
    await refresh();
    return SummonOutcome(results: results);
  }

  Future<TestReward?> submitTest({
    required int levelId,
    required int score,
    required int stars,
    required int pairs,
    required int moves,
    required int errors,
    required int durationMs,
  }) async {
    final key = 'test-$levelId-${DateTime.now().microsecondsSinceEpoch}';
    final result = await guard(
      () => api.submitTest(
        levelId: levelId,
        score: score,
        stars: stars,
        pairs: pairs,
        moves: moves,
        errors: errors,
        durationMs: durationMs,
        key: key,
      ),
      sound: false,
    );
    if (result == null) {
      offlineGames++;
      return null;
    }
    final reward = result['reward'] as Map<String, dynamic>;
    final newState = GameState.fromJson(Map<String, dynamic>.from(result['state'] as Map));
    state = newState;
    notifyListeners();
    return TestReward(
      coins: (reward['coins'] as num).toInt(),
      gems: (reward['gems'] as num).toInt(),
      xp: (reward['xp'] as num).toInt(),
      petLevels: (reward['petLevels'] as List<dynamic>).map((e) => (e as num).toInt()).toList(),
      evoItems: (reward['evoItems'] as List<dynamic>).map((e) => (e as num).toInt()).toList(),
      state: newState,
    );
  }

  Future<bool> updateSettings({bool? sound, double? volume}) async {
    if (sound != null) {
      audio.enabled = sound;
      audio.volume = volume ?? audio.volume;
      if (sound) await audio.tapSound();
    }
    if (volume != null) audio.volume = volume;
    notifyListeners();
    try {
      await api.updateSettings(sound: sound, volume: volume);
      await refresh();
      return true;
    } on ApiError {
      showToast('Настройки сохранены только на устройстве', tone: ToastTone.bad);
      return false;
    }
  }

  Future<bool> rename(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return false;
    final result = await guard(() => api.updateProfile(name: clean));
    if (result == null) return false;
    _applyState(result);
    showToast('Имя обновлено', tone: ToastTone.good);
    return true;
  }

  // ------------------------------------------------------------- админка
  Future<bool> becomeAdmin(String secret) async {
    final result = await guard(() => api.adminBootstrap(secret));
    if (result == null) return false;
    await refresh();
    showToast('Админ-режим включён', tone: ToastTone.good);
    return true;
  }

  Future<bool> adminWallet({int coins = 0, int gems = 0, int eggs = 0}) async {
    final result = await guard(() => api.adminWallet(coins: coins, gems: gems, eggs: eggs));
    if (result == null) return false;
    _applyState(result);
    return true;
  }

  Future<bool> adminPet(String petId, {int? level, int? xp, int? form, bool active = false}) async {
    final result = await guard(() => api.adminPet(petId, level: level, xp: xp, form: form, active: active));
    if (result == null) return false;
    _applyState(result);
    return true;
  }

  Future<bool> adminPity({int epic = 0, int legendary = 0}) async {
    final result = await guard(() => api.adminPity(epic: epic, legendary: legendary));
    if (result == null) return false;
    await refresh();
    return true;
  }

  Future<bool> adminItem(String itemId) async {
    final result = await guard(() => api.adminItem(itemId));
    if (result == null) return false;
    _applyState(result);
    return true;
  }

  Future<bool> adminUnlockAll() async {
    final result = await guard(() => api.adminUnlockAll());
    if (result == null) return false;
    _applyState(result);
    showToast('Все питомцы и предметы выданы', tone: ToastTone.good);
    return true;
  }
}

class Toast {
  Toast({required this.id, required this.text, required this.tone});
  final int id;
  final String text;
  final ToastTone tone;
}

enum ToastTone { info, good, bad }

class SummonOutcome {
  SummonOutcome({required this.results});
  final List<SummonResult> results;
}
