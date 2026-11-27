// Gros bouton coloré avec icône et texte (zone tactile ≥ 56 dp).
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  /// Version icône seule (le texte devient l'info-bulle et le libellé
  /// lu par TalkBack).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    void tap() {
      HapticFeedback.lightImpact();
      onTap!();
    }

    if (compact) {
      return Tooltip(
        message: label,
        child: FilledButton(
          onPressed: onTap == null ? null : tap,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
          ),
          child: Icon(icon, size: 30, semanticLabel: label),
        ),
      );
    }
    return FilledButton.icon(
      onPressed: onTap == null ? null : tap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(kMinTouchTarget * 2, kMinTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: 18),
      ),
      icon: Icon(icon, size: 28),
      label: Text(label),
    );
  }
}
