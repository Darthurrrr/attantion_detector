import 'package:flutter/material.dart';

import '../app/game_app.dart';
import '../state/game_controller.dart';
import '../widgets/game_ui.dart';

/// Слой всплывающих уведомлений поверх текущего экрана.
class ToastOverlay extends StatelessWidget {
  const ToastOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    return Stack(
      children: [
        child,
        Positioned(
          top: 74,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Column(
              children: [
                for (final toast in controller.toasts)
                  ToastBanner(key: ValueKey(toast.id), text: toast.text, tone: toast.tone),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
