import 'package:flutter/material.dart';

import '../app/game_app.dart';
import '../data/models.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/game_ui.dart';
import '../widgets/top_bar.dart';

/// Профиль игрока: аватар, имя, уровень, статистика и настройки.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: GameScope.read(context).state?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final state = controller.state;
    final cfg = controller.config;
    if (state == null || cfg == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final palette = paletteOf(context);
    final totalPets = cfg.pets.length;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SceneBackground(asset: 'assets/bg/home.webp', veil: 0.5, blur: 2),
          SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                final portrait = orientation == Orientation.portrait;
                return Column(
                  children: [
                    GameTopBar(current: 'profile', compact: portrait),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        child: portrait
                            ? ListView(
                                children: [
                                  _ProfileCard(state: state, totalPets: totalPets),
                                  const SizedBox(height: 10),
                                  _StatsCard(state: state),
                                  const SizedBox(height: 10),
                                  _SettingsCard(state: state, controller: controller, nameController: _name),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 4, child: _ProfileCard(state: state, totalPets: totalPets)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 4,
                                    child: ListView(
                                      children: [
                                        _StatsCard(state: state),
                                        const SizedBox(height: 10),
                                        _SettingsCard(state: state, controller: controller, nameController: _name),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    if (portrait) const GameBottomNav(current: 'profile'),
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.state, required this.totalPets});

  final GameState state;
  final int totalPets;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return GamePanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [palette.bright, palette.soft]),
                  border: Border.all(color: palette.accent, width: 2.4),
                ),
                child: ClipOval(child: Image.asset(state.avatar, fit: BoxFit.cover)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.name, style: AppText.h1, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Уровень аккаунта ${state.level}', style: AppText.small),
                    const SizedBox(height: 4),
                    ProgressBar(value: state.accountProgress, height: 7),
                    const SizedBox(height: 2),
                    Text('${state.xp} / ${state.xpNeeded} XP', style: AppText.tiny),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Metric(label: 'Питомцы', value: '${state.pets.length}/$totalPets', color: Palette.violet)),
              const SizedBox(width: 6),
              Expanded(child: _Metric(label: 'Монеты', value: '${state.coins}', color: Palette.gold)),
              const SizedBox(width: 6),
              Expanded(child: _Metric(label: 'Кристаллы', value: '${state.gems}', color: Palette.sky)),
            ],
          ),
          const SizedBox(height: 10),
          if (state.activePet != null)
            Row(
              children: [
                SizedBox(height: 82, width: 82, child: Image.asset(state.activePet!.asset, fit: BoxFit.contain)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Активный питомец', style: AppText.tiny),
                      Text(state.activePet!.name, style: AppText.h2),
                      Text('${state.activePet!.formLabel} · ур. ${state.activePet!.level}', style: AppText.small),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color, height: 1.1)),
          Text(label, style: AppText.tiny, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final games = state.taskProgress['games'] ?? 0;
    final pairs = state.taskProgress['pairs'] ?? 0;
    final stars = state.taskProgress['stars'] ?? 0;
    final summons = state.taskProgress['summons'] ?? 0;
    return GamePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Статистика тренировок', style: AppText.h2),
          const SizedBox(height: 8),
          _StatRow(label: 'Тренировок сегодня', value: '$games'),
          _StatRow(label: 'Найдено пар сегодня', value: '$pairs'),
          _StatRow(label: 'Звёзд сегодня', value: '$stars'),
          _StatRow(label: 'Открыто яиц сегодня', value: '$summons'),
          _StatRow(label: 'Всего поглаживаний', value: '${state.petsPatted}'),
          _StatRow(label: 'Призывов всего', value: '${state.pityTotal}'),
          const Divider(color: Colors.white24, height: 16),
          Text(
            'Приложение тренирует внимание и показывает результаты выполнения. '
            'Оно не ставит медицинских диагнозов — при вопросах о здоровье обратитесь к родителям или врачу.',
            style: AppText.tiny,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.small)),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.state, required this.controller, required this.nameController});

  final GameState state;
  final dynamic controller;
  final TextEditingController nameController;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return GamePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Настройки', style: AppText.h2),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: nameController,
                  maxLength: 16,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    counterText: '',
                    labelText: 'Имя игрока',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.25),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GameButton(
                label: 'Сохранить',
                tone: ButtonTone.violet,
                height: 40,
                width: 108,
                fontSize: 12,
                onTap: () => controller.rename(nameController.text),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.volume_up_rounded, size: 18, color: Colors.white70),
              const SizedBox(width: 6),
              Text('Звук', style: AppText.small),
              const Spacer(),
              Switch(
                value: state.sound,
                activeColor: palette.accent,
                onChanged: (v) => controller.updateSettings(sound: v),
              ),
            ],
          ),
          Row(
            children: [
              Text('Громкость', style: AppText.small),
              Expanded(
                child: Slider(
                  value: state.volume.clamp(0.0, 1.0).toDouble(),
                  activeColor: palette.accent,
                  onChanged: (v) => controller.updateSettings(volume: v),
                ),
              ),
              SizedBox(width: 34, child: Text('${(state.volume * 100).round()}%', style: AppText.tiny)),
            ],
          ),
          if (state.isAdmin)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: GameButton(
                label: 'Админ-панель',
                tone: ButtonTone.plain,
                height: 38,
                icon: const Icon(Icons.settings_suggest_rounded, size: 16, color: Colors.white),
                onTap: () => GameTopBar.open(context, 'admin'),
              ),
            ),
          const SizedBox(height: 6),
          Text('Версия 1.0 · сохранение на сервере', style: AppText.tiny),
        ],
      ),
    );
  }
}
