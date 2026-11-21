import 'package:flutter/material.dart';

import '../app/game_app.dart';
import '../theme/app_text.dart';
import '../widgets/game_ui.dart';
import '../widgets/top_bar.dart';

/// Административный режим: валюта, питомцы, гаранты, предметы.
/// Доступен только после ввода секрета и проверки прав на сервере.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _secret = TextEditingController();
  final _level = TextEditingController(text: '33');
  String _petId = 'murzik';

  @override
  void dispose() {
    _secret.dispose();
    _level.dispose();
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

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SceneBackground(asset: 'assets/bg/cosmic.webp', veil: 0.6, blur: 2),
          SafeArea(
            child: Column(
              children: [
                GameTopBar(current: 'admin'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!state.isAdmin)
                          GamePanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Вход в админ-режим', style: AppText.h1),
                                Text('Секрет задаётся переменной ADMIN_SECRET на сервере.', style: AppText.tiny),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _secret,
                                        obscureText: true,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'Секрет',
                                          filled: true,
                                          fillColor: Colors.black.withOpacity(0.3),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GameButton(
                                      label: 'Войти',
                                      tone: ButtonTone.gold,
                                      height: 42,
                                      width: 96,
                                      fontSize: 13,
                                      onTap: () => controller.becomeAdmin(_secret.text),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        else ...[
                          GamePanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Валюта и яйца', style: AppText.h2),
                                const SizedBox(height: 6),
                                Text('Баланс: ${state.coins} монет, ${state.gems} кристаллов, ${state.eggs} яиц',
                                    style: AppText.small),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    GameButton(label: '+1000 монет', tone: ButtonTone.gold, height: 34, width: 132, fontSize: 11, onTap: () => controller.adminWallet(coins: 1000)),
                                    GameButton(label: '+500 кристаллов', tone: ButtonTone.violet, height: 34, width: 148, fontSize: 11, onTap: () => controller.adminWallet(gems: 500)),
                                    GameButton(label: '+10 яиц', tone: ButtonTone.mint, height: 34, width: 110, fontSize: 11, onTap: () => controller.adminWallet(eggs: 10)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          GamePanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Питомцы и эволюция', style: AppText.h2),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _petId,
                                        dropdownColor: palette.panel,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.black.withOpacity(0.3),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          isDense: true,
                                        ),
                                        items: [
                                          for (final pet in cfg.pets)
                                            DropdownMenuItem(value: pet.id, child: Text(pet.name)),
                                        ],
                                        onChanged: (v) => setState(() => _petId = v ?? 'murzik'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 74,
                                      child: TextField(
                                        controller: _level,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'Ур.',
                                          filled: true,
                                          fillColor: Colors.black.withOpacity(0.3),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    GameButton(
                                      label: 'Задать уровень',
                                      tone: ButtonTone.gold,
                                      height: 34,
                                      width: 146,
                                      fontSize: 11,
                                      onTap: () {
                                        final level = int.tryParse(_level.text) ?? 1;
                                        controller.adminPet(_petId, level: level.clamp(1, 99).toInt());
                                      },
                                    ),
                                    GameButton(label: 'Сделать активным', tone: ButtonTone.violet, height: 34, width: 156, fontSize: 11, onTap: () => controller.adminPet(_petId, active: true)),
                                    GameButton(label: 'Выдать всех', tone: ButtonTone.mint, height: 34, width: 122, fontSize: 11, onTap: () => controller.adminUnlockAll()),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          GamePanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Гаранты', style: AppText.h2),
                                Text('Эпик: ${state.pityEpic}/5 · Легендарный: ${state.pityLegendary}/10', style: AppText.small),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    GameButton(label: 'Гарант эпика', tone: ButtonTone.plain, height: 32, width: 128, fontSize: 11, onTap: () => controller.adminPity(epic: 4, legendary: 0)),
                                    GameButton(label: 'Гарант легенды', tone: ButtonTone.plain, height: 32, width: 138, fontSize: 11, onTap: () => controller.adminPity(epic: 0, legendary: 9)),
                                    GameButton(label: 'Сбросить', tone: ButtonTone.plain, height: 32, width: 96, fontSize: 11, onTap: () => controller.adminPity()),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          GamePanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Предметы', style: AppText.h2),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final item in cfg.shop.take(9))
                                      GameButton(
                                        label: item.name,
                                        tone: ButtonTone.plain,
                                        height: 30,
                                        width: 140,
                                        fontSize: 10,
                                        onTap: () => controller.adminItem(item.id),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          GamePanel(
                            child: Text(
                              'Все действия проверяются на сервере: без прав администратора запросы отклоняются. '
                              'Изменения записываются в журнал операций.',
                              style: AppText.tiny,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
