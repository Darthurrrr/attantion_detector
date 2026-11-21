import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Локальные ключи устройства и токена (не игровые данные).
class DeviceStore {
  static const _deviceKey = 'attention_device_id';
  static const _tokenKey = 'attention_token';

  Future<String> deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceKey);
    if (id == null || id.isEmpty) {
      final rand = Random.secure();
      id = List<int>.generate(16, (_) => rand.nextInt(256)).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString(_deviceKey, id);
    }
    return id;
  }

  Future<String?> token() async => (await SharedPreferences.getInstance()).getString(_tokenKey);

  Future<void> saveToken(String token) async =>
      (await SharedPreferences.getInstance()).setString(_tokenKey, token);

  Future<void> clearToken() async => (await SharedPreferences.getInstance()).remove(_tokenKey);

  /// Сколько раз приложение уже запускалось — для гостевого режима.
  Future<int> launchCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt('attention_launch') ?? 0) + 1;
    await prefs.setInt('attention_launch', count);
    return count;
  }
}
