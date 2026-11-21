import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Ошибка игрового API с кодом от сервера (insufficient_funds и т.п.).
class ApiError implements Exception {
  ApiError(this.code, this.status);
  final String code;
  final int status;

  String get message => switch (code) {
        'insufficient_funds' => 'Не хватает валюты',
        'not_enough_eggs' => 'Не хватает яиц',
        'already_claimed' => 'Награда уже получена',
        'task_incomplete' => 'Задание ещё не выполнено',
        'step_incomplete' => 'Условие ещё не выполнено',
        'evolution_not_ready' => 'Эволюция пока недоступна',
        'bad_secret' => 'Неверный код доступа',
        'admin_only' => 'Нужны права администратора',
        'layer_conflict' => 'Эффект этого слоя уже надет',
        'already_owned' => 'Предмет уже куплен',
        'not_owned' => 'Предмета нет в инвентаре',
        'no_token' || 'bad_token' => 'Нужно войти заново',
        _ when status == 0 => 'Нет связи с сервером',
        _ => 'Не получилось: $code',
      };

  @override
  String toString() => 'ApiError($code)';
}

/// HTTP-клиент игрового сервера. Клиент ничего не считает: только отправляет
/// действия и принимает подтверждённое состояние.
class Api {
  Api({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? _token;

  void setToken(String? token) => _token = token;

  String? get token => _token;

  Map<String, String> _headers({bool json = true}) => {
        if (json) 'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? extraHeaders,
  }) async {
    try {
      final headers = <String, String>{..._headers(), ...?extraHeaders};
      final payload = body == null ? null : jsonEncode(body);
      final http.Response response;
      if (method == 'POST') {
        response = await _client.post(_uri(path), headers: headers, body: payload);
      } else if (method == 'PATCH') {
        response = await _client.patch(_uri(path), headers: headers, body: payload);
      } else {
        response = await _client.get(_uri(path), headers: headers);
      }
      final decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
      if (response.statusCode >= 400) {
        final detail = decoded is Map ? decoded['detail'] : null;
        final code = detail is String ? detail : 'http_${response.statusCode}';
        throw ApiError(code, response.statusCode);
      }
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};
    } on ApiError {
      rethrow;
    } catch (_) {
      throw ApiError('network', 0);
    }
  }

  Future<Map<String, dynamic>> config() => _send('GET', '/api/config');

  Future<Map<String, dynamic>> register(String deviceId, {String? name}) => _send(
        'POST',
        '/api/register',
        body: {'deviceId': deviceId, if (name != null) 'name': name},
      );

  Future<Map<String, dynamic>> state() => _send('GET', '/api/state');

  Future<Map<String, dynamic>> updateProfile({String? name, String? avatar}) => _send(
        'PATCH',
        '/api/profile',
        body: {
          if (name != null) 'name': name,
          if (avatar != null) 'avatar': avatar,
        },
      );

  Future<Map<String, dynamic>> updateSettings({bool? sound, double? volume}) => _send(
        'PATCH',
        '/api/settings',
        body: {
          if (sound != null) 'sound': sound,
          if (volume != null) 'volume': volume,
        },
      );

  Future<Map<String, dynamic>> buyEggs(int count) => _send('POST', '/api/shop/eggs', body: {'count': count});

  Future<Map<String, dynamic>> buyItem(String itemId) => _send('POST', '/api/shop/buy', body: {'itemId': itemId});

  Future<Map<String, dynamic>> equip(String itemId, {required bool equipped}) =>
      _send('POST', '/api/inventory/equip?equipped=$equipped', body: {'itemId': itemId});

  Future<Map<String, dynamic>> summon(int count, String key) => _send(
        'POST',
        '/api/summon',
        body: {'count': count},
        extraHeaders: {'Idempotency-Key': key},
      );

  Future<Map<String, dynamic>> submitTest({
    required int levelId,
    required int score,
    required int stars,
    required int pairs,
    required int moves,
    required int errors,
    required int durationMs,
    required String key,
  }) =>
      _send(
        'POST',
        '/api/tests/submit',
        body: {
          'levelId': levelId,
          'score': score,
          'stars': stars,
          'pairs': pairs,
          'moves': moves,
          'errors': errors,
          'durationMs': durationMs,
        },
        extraHeaders: {'Idempotency-Key': key},
      );

  Future<Map<String, dynamic>> claimDaily() => _send('POST', '/api/daily/claim');

  Future<Map<String, dynamic>> claimTask(String taskId) => _send('POST', '/api/tasks/claim', body: {'taskId': taskId});

  Future<Map<String, dynamic>> claimEvent(String eventId, String stepId) =>
      _send('POST', '/api/events/claim', body: {'eventId': eventId, 'stepId': stepId});

  Future<Map<String, dynamic>> pat() => _send('POST', '/api/pets/pat');

  Future<Map<String, dynamic>> setActivePet(String petId) => _send('POST', '/api/pets/active', body: {'petId': petId});

  Future<Map<String, dynamic>> evolve(String petId) => _send('POST', '/api/pets/evolve', body: {'petId': petId});

  // --- админ-панель -------------------------------------------------------
  Future<Map<String, dynamic>> adminBootstrap(String secret) =>
      _send('POST', '/api/admin/bootstrap', body: {'secret': secret});

  Future<Map<String, dynamic>> adminWallet({int coins = 0, int gems = 0, int eggs = 0, String note = 'admin'}) =>
      _send('POST', '/api/admin/wallet', body: {'coins': coins, 'gems': gems, 'eggs': eggs, 'note': note});

  Future<Map<String, dynamic>> adminPet(String petId, {int? level, int? xp, int? form, bool active = false}) => _send(
        'POST',
        '/api/admin/pet',
        body: {
          'petId': petId,
          if (level != null) 'level': level,
          if (xp != null) 'xp': xp,
          if (form != null) 'form': form,
          'active': active,
        },
      );

  Future<Map<String, dynamic>> adminPity({int epic = 0, int legendary = 0, int? total}) =>
      _send(
        'POST',
        '/api/admin/pity',
        body: {
          'epic': epic,
          'legendary': legendary,
          if (total != null) 'total': total,
        },
      );

  Future<Map<String, dynamic>> adminItem(String itemId) => _send('POST', '/api/admin/item', body: {'itemId': itemId});

  Future<Map<String, dynamic>> adminUnlockAll() => _send('POST', '/api/admin/unlock-all');

  Future<Map<String, dynamic>> adminTransactions() => _send('GET', '/api/transactions');
}
