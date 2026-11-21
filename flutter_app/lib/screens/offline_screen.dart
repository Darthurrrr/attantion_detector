import 'package:flutter/material.dart';

import '../app/game_app.dart';
import '../state/game_controller.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/game_ui.dart';

/// Экран недоступного сервера: понятное объяснение и повторная попытка.
/// Офлайн-сохранение прогресса не подменяет серверные проверки (ТЗ 2.3, 25),
/// поэтому без подключения игра просит восстановить связь.
class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final palette = paletteOf(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SceneBackground(asset: 'assets/bg/home.webp', veil: 0.55, blur: 3),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: GamePanel(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [palette.accent, Palette.goldDeep]),
                              ),
                              child: const Icon(Icons.cloud_off_rounded, color: Palette.ink, size: 24),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Нет связи с сервером', style: AppText.h1),
                                  Text('Мир внимания ждёт подключения', style: AppText.tiny),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Игровые награды, призыв и коллекция проверяются на сервере, '
                          'поэтому без него прогресс не начисляется. Проверьте интернет и попробуйте снова.',
                          style: AppText.body,
                        ),
                        if (controller.errorText != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.32),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(controller.errorText!, style: AppText.tiny),
                          ),
                        ],
                        const SizedBox(height: 14),
                        GameButton(
                          label: _busy ? 'Подключаемся…' : 'Повторить',
                          tone: ButtonTone.gold,
                          height: 48,
                          enabled: !_busy,
                          onTap: () async {
                            setState(() => _busy = true);
                            await controller.boot();
                            if (!mounted) return;
                            setState(() => _busy = false);
                            if (controller.phase == LoadPhase.ready) widget.onRetry();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
