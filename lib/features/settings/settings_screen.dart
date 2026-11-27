// Réglages : voix, sons, vitesse, mode daltonien, gaucher, espace parent.
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/progress.dart';
import '../../shared/settings.dart';
import '../../shared/speech.dart';
import '../../shared/stats.dart';
import '../../shared/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final t = Theme.of(context).textTheme;

    Widget toggle(
      String title,
      String help,
      bool value,
      ValueChanged<bool> on,
    ) => SwitchListTile(
      title: Text(title, style: t.titleMedium),
      subtitle: Text(help, style: t.bodyMedium),
      value: value,
      onChanged: on,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l.settings),
        leading: IconButton(
          tooltip: l.back,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            toggle(
              l.settingsVoice,
              l.settingsVoiceHelp,
              s.voice,
              (v) => n.update(s.copyWith(voice: v)),
            ),
            if (s.voice)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        ref.read(speechProvider).speak(l.voiceSample),
                    icon: const Icon(Icons.record_voice_over_rounded, size: 28),
                    label: Text(
                      l.settingsTryVoice,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            toggle(
              l.settingsSounds,
              l.settingsSoundsHelp,
              s.sounds,
              (v) => n.update(s.copyWith(sounds: v)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(l.settingsSpeed, style: t.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedButton<AnimationSpeed>(
                segments: [
                  ButtonSegment(
                    value: AnimationSpeed.lent,
                    label: Text(l.speedSlow),
                  ),
                  ButtonSegment(
                    value: AnimationSpeed.normal,
                    label: Text(l.speedNormal),
                  ),
                  ButtonSegment(
                    value: AnimationSpeed.rapide,
                    label: Text(l.speedFast),
                  ),
                ],
                selected: {s.speed},
                onSelectionChanged: (v) => n.update(s.copyWith(speed: v.first)),
                showSelectedIcon: false,
                style: const ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(Size(0, kMinTouchTarget)),
                  textStyle: WidgetStatePropertyAll(
                    TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            toggle(
              l.settingsColorBlind,
              l.settingsColorBlindHelp,
              s.colorBlind,
              (v) => n.update(s.copyWith(colorBlind: v)),
            ),
            toggle(
              l.settingsLeftHanded,
              l.settingsLeftHandedHelp,
              s.leftHanded,
              (v) => n.update(s.copyWith(leftHanded: v)),
            ),
            const Divider(height: 32),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 6,
              ),
              leading: const Icon(
                Icons.lock_rounded,
                size: 32,
                color: CubeColors.ink,
              ),
              title: Text(l.parentArea, style: t.titleMedium),
              onTap: () async {
                if (await askParent(context)) {
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ParentScreen(),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Petit calcul pour vérifier que c'est un adulte.
Future<bool> askParent(BuildContext context, {Random? random}) async {
  final rnd = random ?? Random();
  final a = 11 + rnd.nextInt(19), b = 6 + rnd.nextInt(14);
  final controller = TextEditingController();
  final l = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.parentArea),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.parentQuestion(a, b), style: const TextStyle(fontSize: 22)),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 24),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(ctx, int.tryParse(controller.text.trim()) == a + b),
          child: Text(l.parentOk),
        ),
      ],
    ),
  );
  if (ok == false && controller.text.isNotEmpty && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.parentWrong, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
  return ok ?? false;
}

class ParentScreen extends ConsumerWidget {
  const ParentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.parentArea),
        leading: IconButton(
          tooltip: l.back,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l.parentPrivacy, style: t.bodyLarge),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: CubeColors.practice,
              ),
              icon: const Icon(Icons.delete_forever_rounded),
              label: Text(l.parentReset),
              onPressed: () async {
                final yes = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l.parentReset),
                    content: Text(
                      l.parentResetConfirm,
                      style: const TextStyle(fontSize: 18),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l.parentOk),
                      ),
                    ],
                  ),
                );
                if (yes == true) {
                  ref.read(progressProvider.notifier).reset();
                  ref.read(statsProvider.notifier).reset();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l.parentResetDone,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
