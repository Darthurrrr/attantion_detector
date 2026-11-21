import 'package:flutter/material.dart';

import '../app/game_app.dart';
import '../data/models.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/game_ui.dart';
import '../widgets/top_bar.dart';

/// Коллекция: сетка питомцев, детали, эволюция и выбор активного.
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final state = controller.state;
    final cfg = controller.config;
    if (state == null || cfg == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final owned = {for (final pet in state.pets) pet.petId};
    final catalog = cfg.pets;
    final selectedId = _selected ?? state.activePetId;
    final Pet? selectedPet = _firstWhereOrNull<Pet>(state.pets, (p) => p.petId == selectedId);
    final PetCatalog? selectedCatalog = _firstWhereOrNull<PetCatalog>(catalog, (p) => p.id == selectedId);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SceneBackground(asset: 'assets/bg/collection.webp', veil: 0.4),
          SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                final portrait = orientation == Orientation.portrait;
                final grid = _PetGrid(
                  catalog: catalog,
                  owned: owned,
                  selectedId: selectedId,
                  onSelect: (id) => setState(() => _selected = id),
                );
                final details = _PetDetails(
                  pet: selectedPet,
                  fallback: selectedCatalog,
                  isActive: selectedId != null && selectedId == state.activePetId,
                  onActivate: selectedPet == null ? null : () => controller.setActivePet(selectedPet.petId),
                  onEvolve: selectedPet == null || !selectedPet.canEvolve
                      ? null
                      : () => _confirmEvolution(context, selectedPet),
                );
                return Column(
                  children: [
                    GameTopBar(current: 'collection', compact: portrait),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                      child: Row(
                        children: [
                          Text('Коллекция', style: AppText.h1),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: Palette.violet.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Palette.violet.withOpacity(0.7)),
                            ),
                            child: Text('${owned.length} / ${catalog.length}', style: AppText.tiny),
                          ),
                          const Spacer(),
                          Text('Нажмите на питомца, чтобы открыть карточку', style: AppText.tiny),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                        child: portrait
                            ? Column(
                                children: [
                                  SizedBox(height: 230, child: details),
                                  const SizedBox(height: 8),
                                  Expanded(child: grid),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 5, child: grid),
                                  const SizedBox(width: 14),
                                  SizedBox(width: 340, child: details),
                                ],
                              ),
                      ),
                    ),
                    if (portrait) const GameBottomNav(current: 'collection'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmEvolution(BuildContext context, Pet pet) async {
    final controller = GameScope.read(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Palette.violetTheme.panel,
        title: const Text('Эволюция питомца'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${pet.name} перейдёт в новую форму.', style: AppText.body),
            const SizedBox(height: 8),
            const Text('Награды: новая форма, эксклюзивный эффект и иконка питомца.',
                style: TextStyle(color: Palette.gold, fontSize: 12)),
            const SizedBox(height: 8),
            Text('Предмет эволюции: ${pet.evoItems} шт. Накопленный опыт сохранится.',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Эволюция')),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await controller.evolvePet(pet.petId);
    if (ok && context.mounted) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Palette.violetTheme.panel,
          title: const Text('Новая форма!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 120, child: Image.asset(pet.asset, fit: BoxFit.contain)),
              Text('${pet.name} стал сильнее', style: AppText.h2),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отлично'))],
        ),
      );
    }
  }
}

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

class _PetGrid extends StatelessWidget {
  const _PetGrid({required this.catalog, required this.owned, required this.selectedId, required this.onSelect});

  final List<PetCatalog> catalog;
  final Set<String> owned;
  final String? selectedId;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return GamePanel(
      padding: const EdgeInsets.all(10),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 112,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.82,
        ),
        itemCount: catalog.length,
        itemBuilder: (context, index) {
          final pet = catalog[index];
          final isOwned = owned.contains(pet.id);
          final active = pet.id == selectedId;
          return GestureDetector(
            onTap: () {
              GameScope.read(context).audio.tapSound();
              onSelect(pet.id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isOwned
                      ? [pet.rarity.color.withOpacity(0.34), Colors.white.withOpacity(0.05)]
                      : [Colors.black.withOpacity(0.45), Colors.black.withOpacity(0.3)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: active ? palette.accent : pet.rarity.color.withOpacity(isOwned ? 0.7 : 0.2),
                  width: active ? 2.2 : 1.2,
                ),
              ),
              padding: const EdgeInsets.all(5),
              child: Column(
                children: [
                  Expanded(
                    child: isOwned
                        ? Image.asset(pet.asset, fit: BoxFit.contain)
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: 0.22,
                                child: ColorFiltered(
                                  colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcATop),
                                  child: Image.asset(pet.asset, fit: BoxFit.contain),
                                ),
                              ),
                              Text('?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.5))),
                            ],
                          ),
                  ),
                  Text(
                    isOwned ? pet.name : '???',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  RarityBadge(rarity: pet.rarity, compact: true),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PetDetails extends StatelessWidget {
  const _PetDetails({
    required this.pet,
    required this.fallback,
    required this.isActive,
    required this.onActivate,
    required this.onEvolve,
  });

  final Pet? pet;
  final PetCatalog? fallback;
  final bool isActive;
  final VoidCallback? onActivate;
  final VoidCallback? onEvolve;

  @override
  Widget build(BuildContext context) {
    final data = pet ?? fallback;
    if (data == null) {
      return GamePanel(child: Center(child: Text('Выберите питомца', style: AppText.body)));
    }
    final rarity = pet?.rarity ?? fallback!.rarity;
    final name = pet?.name ?? fallback!.name;
    final title = pet?.title ?? fallback!.title;
    final asset = pet?.asset ?? fallback!.asset;
    final desc = pet?.desc ?? fallback!.desc;
    final stats = pet?.stats ?? fallback!.stats;

    return GamePanel(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(
                  height: 92,
                  width: 92,
                  child: Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 40),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RarityBadge(rarity: rarity),
                      const SizedBox(height: 4),
                      Text(name, style: AppText.h1, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(title, style: AppText.small, maxLines: 2),
                      if (pet != null)
                        Text(pet!.formLabel, style: TextStyle(fontSize: 10.5, color: Palette.gold, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(desc, style: AppText.small, maxLines: 3),
            const SizedBox(height: 8),
            if (pet != null) ...[
              Row(
                children: [
                  Text('Уровень ${pet!.level}', style: AppText.h2),
                  const Spacer(),
                  Text(pet!.maxLevel ? 'Максимальный уровень' : '${pet!.xp} / ${pet!.xpNeeded} XP', style: AppText.tiny),
                ],
              ),
              const SizedBox(height: 4),
              ProgressBar(value: pet!.progress, height: 9),
              const SizedBox(height: 8),
              for (var i = 0; i < stats.length && i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 74,
                        child: Text(['Внимание', 'Скорость', 'Удача'][i], style: AppText.tiny),
                      ),
                      Expanded(child: ProgressBar(value: stats[i] / 100, height: 7, colors: const [Palette.mint, Color(0xFF2FA98A)])),
                      const SizedBox(width: 6),
                      Text('${stats[i]}', style: AppText.tiny),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.upgrade_rounded, size: 13, color: pet!.evoItems > 0 ? Palette.gold : Colors.white38),
                  const SizedBox(width: 5),
                  Text(
                    'Предметы эволюции: ${pet!.evoItems} · форма ${pet!.form}/3',
                    style: AppText.tiny,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GameButton(
                    label: isActive ? 'Активен' : 'Сделать активным',
                    tone: isActive ? ButtonTone.plain : ButtonTone.gold,
                    height: 42,
                    fontSize: 12,
                    enabled: !isActive && onActivate != null,
                    onTap: onActivate,
                  ),
                ),
                if (pet != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: GameButton(
                      label: pet!.canEvolve ? 'Эволюция' : 'Нет предмета',
                      tone: ButtonTone.violet,
                      height: 42,
                      fontSize: 12,
                      enabled: pet!.canEvolve,
                      onTap: onEvolve,
                    ),
                  ),
                ],
              ],
            ),
            if (pet != null && !pet!.canEvolve)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  pet!.form >= 3
                      ? 'Питомец достиг третьей формы.'
                      : 'Эволюция откроется на ${pet!.form == 1 ? 33 : 66}-м уровне вместе с предметом эволюции.',
                  style: AppText.tiny,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
