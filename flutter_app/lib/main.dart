import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/game_app.dart';
import 'services/api.dart';
import 'services/audio.dart';
import 'services/device.dart';
import 'state/game_controller.dart';

/// Адрес игрового сервера. Переопределяется при сборке:
/// flutter run --dart-define=API_BASE_URL=https://api.example.com
const _apiBase = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  final controller = GameController(
    api: Api(baseUrl: _apiBase),
    audio: GameAudio(),
    device: DeviceStore(),
  );
  runApp(GameApp(controller: controller));
}
