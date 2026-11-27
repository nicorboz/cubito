// Grosse tuile colorée de l'écran d'accueil (facile à toucher pour un enfant).
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';

class BigTile extends StatelessWidget {
  const BigTile({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(28),
        elevation: 3,
        shadowColor: color.withValues(alpha: 0.5),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            HapticFeedback.lightImpact(); // petite vibration de confirmation
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: kMinTouchTarget * 2,
              minWidth: kMinTouchTarget * 2,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              // Réduit le contenu si la tuile est petite (paysage, petit écran).
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 52, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
