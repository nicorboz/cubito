// Partie 5 « Fiche » : la formule à retenir (quand, et geste par geste).
// La fiche s'exporte en image PNG (menu « Partager » : imprimer, envoyer…).
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/cube/cube.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/move_text.dart';
import '../../../shared/theme.dart';
import '../lessons.dart';
import 'common.dart';

class MemoPart extends StatefulWidget {
  const MemoPart({super.key, required this.lesson});
  final Lesson lesson;

  @override
  State<MemoPart> createState() => _MemoPartState();
}

class _MemoPartState extends State<MemoPart> {
  final _cardKey = GlobalKey();
  bool _sharing = false;

  /// Transforme la fiche en image PNG et ouvre le menu « Partager » du
  /// téléphone (imprimer, enregistrer, envoyer à un parent…).
  Future<void> _share() async {
    final l = AppLocalizations.of(context);
    setState(() => _sharing = true);
    try {
      final png = await memoToPng(_cardKey);
      final name = 'fiche-cubito-lecon-${widget.lesson.number}.png';
      if (kIsWeb) {
        // Navigateur : menu « Partager » s'il existe, sinon l'image est
        // simplement téléchargée.
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile.fromData(png, mimeType: 'image/png', name: name)],
            fileNameOverrides: [name],
            text: l.memoShareText,
          ),
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(png);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: l.memoShareText,
        ),
      );
    } catch (_) {
      // Pas de partage possible : on n'embête pas l'enfant avec une erreur.
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RepaintBoundary(
                key: _cardKey,
                child: MemoCard(lesson: widget.lesson),
              ),
              const SizedBox(height: 16),
              Center(
                child: FilledButton.icon(
                  onPressed: _sharing ? null : _share,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.lesson.color,
                  ),
                  icon: const Icon(Icons.print_rounded, size: 28),
                  label: Text(l.memoShare),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: NextButton(
                  label: l.backToMap,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Capture la fiche en image PNG haute définition (pour l'impression).
Future<Uint8List> memoToPng(GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 3);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// La fiche elle-même (réutilisée pour l'export PNG).
class MemoCard extends StatelessWidget {
  const MemoCard({super.key, required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lesson.color, width: 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l.memoTitle} · ${l.lessonNumber(lesson.number)}',
            style: t.bodyMedium,
          ),
          Text(
            '${lesson.emoji()} ${lesson.title(l)}',
            style: t.headlineMedium?.copyWith(color: lesson.color),
          ),
          Text(lesson.when(l), style: t.titleMedium),
          const SizedBox(height: 4),
          Text(lesson.goal(l), style: t.bodyLarge),
          const Divider(height: 24),
          _Moves(moves: lesson.moves),
        ],
      ),
    );
  }
}

class _Moves extends StatelessWidget {
  const _Moves({required this.moves});
  final List<Move> moves;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < moves.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${i + 1}. ${moveLabel(l, moves[i])}',
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: CubeColors.ink),
            ),
          ),
      ],
    );
  }
}
