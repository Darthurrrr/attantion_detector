import 'package:flutter/material.dart';

import '../app/game_app.dart';
import '../data/models.dart';
import '../state/game_controller.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/game_ui.dart';
import '../widgets/top_bar.dart';

/// События: ежедневный вход, ежедневные задания и новичковое событие.
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final state = controller.state;
    final cfg = controller.config;
    if (state == null || cfg == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final palette = paletteOf(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SceneBackground(asset: 'assets/bg/world.webp', veil: 0.45, blur: 1),
          SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                final portrait = orientation == Orientation.portrait;
                return Column(
                  children: [
                    GameTopBar(current: 'events', compact: portrait),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                      child: Row(
                        children: [
                          Text('События и задания', style: AppText.h1),
                          const Spacer(),
                          if (state.dailyCanClaim)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Palette.mint.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Palette.mint),
                              ),
                              child: Text('Есть награда', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Palette.mint)),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                        child: portrait
                            ? ListView(
                                children: [
                                  _DailyCard(state: state, cfg: cfg, controller: controller),
                                  const SizedBox(height: 10),
                                  _TasksCard(state: state, cfg: cfg, controller: controller),
                                  const SizedBox(height: 10),
                                  _EventCard(state: state, cfg: cfg, controller: controller),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: ListView(
                                      children: [
                                        _DailyCard(state: state, cfg: cfg, controller: controller),
                                        const SizedBox(height: 10),
                                        _EventCard(state: state, cfg: cfg, controller: controller),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(flex: 5, child: _TasksCard(state: state, cfg: cfg, controller: controller)),
                                ],
                              ),
                      ),
                    ),
                    if (portrait) const GameBottomNav(current: 'events'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.state, required this.cfg, required this.controller});

  final GameState state;
  final GameConfig cfg;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final day = (state.dailyStreak % 7);
    return GamePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, size: 18, color: Palette.gold),
              const SizedBox(width: 6),
              Text('Ежедневный вход', style: AppText.h2),
              const Spacer(),
              Text('Серия: ${state.dailyStreak} дн.', style: AppText.tiny),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: i < day
                              ? [Palette.mint.withOpacity(0.7), Palette.mint.withOpacity(0.35)]
                              : i == 6
                                  ? [Palette.gold, Palette.goldDeep]
                                  : [Colors.white.withOpacity(0.16), Colors.white.withOpacity(0.06)],
                        ),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: i == 6 ? Colors.white : Colors.white.withOpacity(0.2),
                          width: i == 6 ? 1.6 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          if (i == 6)
                            const Icon(Icons.pets, size: 13, color: Palette.ink)
                          else
                            Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: i < day ? Palette.ink : Colors.white70)),
                          const SizedBox(height: 2),
                          Text(
                            i == 6 ? 'питомец' : 'день',
                            style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: i == 6 ? Palette.ink : Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  state.dailyCanClaim ? 'Заберите награду за сегодня' : 'Награда получена. Возвращайтесь завтра!',
                  style: AppText.small,
                ),
              ),
              GameButton(
                label: state.dailyCanClaim ? 'Забрать' : 'Завтра',
                tone: state.dailyCanClaim ? ButtonTone.mint : ButtonTone.plain,
                height: 38,
                width: 110,
                fontSize: 12,
                enabled: state.dailyCanClaim,
                onTap: () => controller.claimDaily(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TasksCard extends StatelessWidget {
  const _TasksCard({required this.state, required this.cfg, required this.controller});

  final GameState state;
  final GameConfig cfg;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final tasks = cfg.tasks;
    return GamePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded, size: 18, color: Palette.mint),
              const SizedBox(width: 6),
              Text('Ежедневные задания', style: AppText.h2),
              const Spacer(),
              Text('Награду забираете сами', style: AppText.tiny),
            ],
          ),
          const SizedBox(height: 8),
          for (final task in tasks) ...[
            _TaskRow(task: task, state: state, controller: controller),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.state, required this.controller});

  final Map<String, dynamic> task;
  final GameState state;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final id = task['id'] as String;
    final metric = task['metric'] as String;
    final goal = (task['goal'] as num).toInt();
    final progress = state.taskProgress[metric] ?? 0;
    final done = progress >= goal;
    final claimed = state.taskClaimed.contains(id);
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: done && !claimed ? Palette.gold : Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(task['title'] as String, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              if ((task['coins'] as num).toInt() > 0) ...[
                const CoinIcon(size: 13),
                const SizedBox(width: 3),
                Text('${task['coins']}', style: AppText.tiny),
                const SizedBox(width: 6),
              ],
              if ((task['gems'] as num).toInt() > 0) ...[
                GemIcon(size: 13),
                const SizedBox(width: 3),
                Text('${task['gems']}', style: AppText.tiny),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: ProgressBar(
                  value: progress / goal,
                  height: 7,
                  colors: done ? const [Palette.mint, Color(0xFF2FA98A)] : const [Palette.gold, Palette.goldDeep],
                ),
              ),
              const SizedBox(width: 6),
              Text('${progress.clamp(0, goal).toInt()}/$goal', style: AppText.tiny),
              const SizedBox(width: 8),
              GameButton(
                label: claimed ? 'Получено' : (done ? 'Забрать' : 'Не готово'),
                tone: claimed ? ButtonTone.plain : ButtonTone.gold,
                height: 30,
                width: 100,
                fontSize: 10.5,
                enabled: done && !claimed,
                onTap: () => controller.claimTask(id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.state, required this.cfg, required this.controller});

  final GameState state;
  final GameConfig cfg;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final event = cfg.events.isEmpty ? null : cfg.events.first;
    if (event == null) return const SizedBox.shrink();
    final steps = (event['steps'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final claims = state.eventClaims[event['id'] as String] ?? const <String, bool>{};
    return GamePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 18, color: Palette.rose),
              const SizedBox(width: 6),
              Text(event['name'] as String? ?? 'Событие', style: AppText.h2),
              const Spacer(),
              Text('Одноразовое', style: AppText.tiny),
            ],
          ),
          const SizedBox(height: 6),
          for (final step in steps) ...[
            _EventStep(step: step, claimed: claims[step['id']] ?? false, state: state, controller: controller, eventId: event['id'] as String),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _EventStep extends StatelessWidget {
  const _EventStep({
    required this.step,
    required this.claimed,
    required this.state,
    required this.controller,
    required this.eventId,
  });

  final Map<String, dynamic> step;
  final bool claimed;
  final GameState state;
  final GameController controller;
  final String eventId;

  int get _progress {
    final metric = step['metric'] as String;
    if (metric == 'pets_patted') return state.petsPatted;
    if (metric == 'days') {
      final created = state.createdAt;
      if (created == null) return 1;
      return DateTime.now().difference(created).inDays + 1;
    }
    return state.taskProgress[metric] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final goal = (step['goal'] as num).toInt();
    final progress = _progress;
    final done = progress >= goal;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: done && !claimed ? Palette.rose : Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step['title'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                Text(step['desc'] as String, style: AppText.tiny, maxLines: 2),
                const SizedBox(height: 4),
                ProgressBar(value: progress / goal, height: 5),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GameButton(
            label: claimed ? 'Забрано' : (done ? 'Забрать' : '$progress/$goal'),
            tone: claimed ? ButtonTone.plain : ButtonTone.mint,
            height: 30,
            width: 92,
            fontSize: 10.5,
            enabled: done && !claimed,
            onTap: () => controller.claimEvent(eventId, step['id'] as String),
          ),
        ],
      ),
    );
  }
}
