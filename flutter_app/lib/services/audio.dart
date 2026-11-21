import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Звуковая подсистема: мягкие эффекты, громкость из настроек.
class GameAudio {
  GameAudio();

  final _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  bool enabled = true;
  double volume = 0.8;
  final Map<String, AudioPlayer> _parallel = {};
  int _seq = 0;

  static const tap = 'sounds/ui_tap.wav';
  static const reward = 'sounds/success_chime.wav';
  static const crystal = 'sounds/crystal_reward.wav';
  static const cuddle = 'sounds/pet_cuddle.wav';
  static const transition = 'sounds/soft_transition.wav';

  Future<void> play(String asset, {double? gain}) async {
    if (!enabled) return;
    try {
      _seq++;
      // Отдельные плееры дают возможность накладывать короткие эффекты.
      final player = _seq % 3 == 0 ? _player : (_parallel[asset] ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop));
      await player.stop();
      await player.setVolume(((gain ?? 1) * volume).clamp(0.0, 1.0).toDouble());
      await player.play(AssetSource(asset));
    } catch (_) {
      // Звук — не критичный путь: сбой не должен ронять игру.
    }
  }

  Future<void> tapSound() => play(tap, gain: 0.7);
  Future<void> rewardSound() => play(reward, gain: 0.95);
  Future<void> crystalSound() => play(crystal, gain: 0.9);
  Future<void> cuddleSound() => play(cuddle, gain: 0.85);
  Future<void> transitionSound() => play(transition, gain: 0.65);

  /// Последовательность для легендарного открытия.
  Future<void> legendaryFanfare() async {
    await play(crystal, gain: 1);
    await Future<void>.delayed(const Duration(milliseconds: 260));
    await play(reward, gain: 1);
    await Future<void>.delayed(const Duration(milliseconds: 380));
    await play(crystal, gain: 0.7);
  }

  Future<void> dispose() async {
    for (final player in _parallel.values) {
      await player.dispose();
    }
    await _player.dispose();
  }
}
