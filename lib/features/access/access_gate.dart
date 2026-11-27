// Écran « code d'accès » de la version web (GitHub Pages).
//
// Le site est public : ce code évite simplement que n'importe qui tombe sur
// l'appli. Il est vérifié dans le navigateur (pas de serveur) : seule son
// empreinte SHA-256 est dans le code, jamais le code lui-même.
// Une fois le bon code saisi, il n'est plus demandé sur cet appareil.
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/mascot/cubito.dart';
import '../../shared/prefs.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/pill_button.dart';

/// Préfixe ajouté avant de calculer l'empreinte (« sel »).
const _salt = 'cubito-web-v1:';

/// Empreinte SHA-256 de « _salt + code ». Pour changer le code :
/// `python3 -c "import hashlib;print(hashlib.sha256(b'cubito-web-v1:NOUVEAU').hexdigest())"`
const accessCodeHash =
    'b538d1f4838131a936b0163a9510c3746bc733e6e2dd12cedc1c44917e77e373';

/// Clé de stockage : le code a déjà été donné sur cet appareil.
const accessPrefKey = 'webAccessHash';

/// Le code saisi est-il le bon ?
bool isAccessCode(String code) =>
    sha256.convert(utf8.encode('$_salt${code.trim()}')).toString() ==
    accessCodeHash;

/// Affiche [child] si le code a déjà été donné, sinon l'écran du code.
class AccessGate extends ConsumerStatefulWidget {
  const AccessGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AccessGate> createState() => _AccessGateState();
}

class _AccessGateState extends ConsumerState<AccessGate> {
  final _field = TextEditingController();
  final _focus = FocusNode();
  late bool _open =
      ref.read(prefsProvider).getString(accessPrefKey) == accessCodeHash;
  bool _wrong = false;

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    if (isAccessCode(_field.text)) {
      ref.read(prefsProvider).setString(accessPrefKey, accessCodeHash);
      setState(() => _open = true);
    } else {
      setState(() => _wrong = true);
      // On garde le curseur dans la case pour réessayer tout de suite.
      _field.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _field.text.length,
      );
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_open) return widget.child;
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Cubito(size: 140),
                  const SizedBox(height: 16),
                  Text(
                    l.accessTitle,
                    textAlign: TextAlign.center,
                    style: t.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.accessHelp,
                    textAlign: TextAlign.center,
                    style: t.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _field,
                    focusNode: _focus,
                    autofocus: true,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: const TextStyle(fontSize: 22),
                    textInputAction: TextInputAction.go,
                    onChanged: (_) {
                      if (_wrong) setState(() => _wrong = false);
                    },
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: l.accessLabel,
                      errorText: _wrong ? l.accessWrong : null,
                      errorStyle: const TextStyle(fontSize: 18),
                      labelStyle: const TextStyle(fontSize: 18),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  PillButton(
                    icon: Icons.lock_open_rounded,
                    label: l.accessEnter,
                    color: CubeColors.solve,
                    onTap: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
