#!/usr/bin/env python3
"""Prépare les voix enregistrées de Cubito (Google Cloud TTS, voix Chirp 3 HD).

Les phrases viennent :
  - de lib/l10n/app_fr.arb (toutes les phrases sans paramètre),
  - de build/voice_lines.json (phrases composées, produites par
    `VOICE_DUMP=build/voice_lines.json flutter test test/tool/voice_lines_test.dart`).

Chaque phrase devient assets/voice/<clé>.mp3 ; assets/voice/index.json relie
le texte (normalisé) au fichier. La clé API est lue dans la variable
d'environnement GOOGLE_TTS_KEY : elle n'est jamais écrite dans le projet.
Les fichiers déjà générés sont gardés (relancer ne coûte que les nouvelles phrases).
"""
import base64, hashlib, json, os, re, sys, time, urllib.request

VOICE = os.environ.get('VOICE_NAME', 'fr-FR-Chirp3-HD-Pulcherrima')
RATE = float(os.environ.get('VOICE_RATE', '0.95'))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'assets', 'voice')


def normalize(text: str) -> str:
    """Même normalisation que lib/shared/speech.dart (voiceKey)."""
    t = text.replace(' ', ' ').replace(' ', ' ')
    return re.sub(r'\s+', ' ', t).strip()


def key_of(text: str) -> str:
    return hashlib.sha1(normalize(text).encode('utf-8')).hexdigest()[:16]


EMOJI = re.compile('[\U0001F300-\U0001FAFF☀-➿⭐⬆←-⇿️]')


def spoken(text: str) -> str:
    """Texte réellement envoyé à la voix (sans émojis ni symboles)."""
    t = EMOJI.sub('', normalize(text))
    t = t.replace(' · ', ' ').replace('·', ' ')
    t = re.sub(r'\b2e\b', 'deuxième', t)
    # MOTS EN CAPITALES → minuscules (sinon la voix peut épeler)
    t = re.sub(r'\b[A-ZÀ-Ý]{2,}(?:\s+[A-ZÀ-Ý]{2,})*\b', lambda m: m.group(0).lower(), t)
    return re.sub(r'\s+', ' ', t).strip()


def phrases():
    arb = json.load(open(os.path.join(ROOT, 'lib', 'l10n', 'app_fr.arb'), encoding='utf-8'))
    out = set()
    for k, v in arb.items():
        if k.startswith('@') or not isinstance(v, str) or '{' in v:
            continue
        if not re.search(r'[A-Za-zÀ-ÿ]{2}', v):
            continue  # symboles seuls (R, U', ✓…)
        out.add(v)
    composed = os.path.join(ROOT, 'build', 'voice_lines.json')
    if os.path.exists(composed):
        out.update(json.load(open(composed, encoding='utf-8')))
    else:
        print('⚠️  build/voice_lines.json absent : phrases composées ignorées', file=sys.stderr)
    return sorted(out)


def synth(text: str, api_key: str) -> bytes:
    body = json.dumps({
        'input': {'text': text},
        'voice': {'languageCode': 'fr-FR', 'name': VOICE},
        'audioConfig': {'audioEncoding': 'MP3', 'speakingRate': RATE},
    }).encode()
    req = urllib.request.Request(
        'https://texttospeech.googleapis.com/v1/text:synthesize', data=body,
        headers={'Content-Type': 'application/json', 'X-Goog-Api-Key': api_key})
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return base64.b64decode(json.load(r)['audioContent'])
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 503) and attempt < 4:
                time.sleep(2 ** attempt)
                continue
            raise SystemExit(f'Erreur {e.code} pour « {text} » : {e.read()[:300]!r}')


def main():
    api_key = os.environ.get('GOOGLE_TTS_KEY')
    if not api_key:
        raise SystemExit('GOOGLE_TTS_KEY manquante')
    os.makedirs(OUT, exist_ok=True)
    index, chars, made = {}, 0, 0
    for text in phrases():
        k = key_of(text)
        index[normalize(text)] = f'{k}.mp3'
        path = os.path.join(OUT, f'{k}.mp3')
        if os.path.exists(path):
            continue
        say = spoken(text)
        if not say:
            continue
        open(path, 'wb').write(synth(say, api_key))
        chars += len(say)
        made += 1
        if made % 25 == 0:
            print(f'{made} phrases…', flush=True)
    # Ne garder que les fichiers utiles.
    keep = set(index.values())
    for f in os.listdir(OUT):
        if f.endswith('.mp3') and f not in keep:
            os.remove(os.path.join(OUT, f))
    json.dump({'voice': VOICE, 'rate': RATE, 'files': index},
              open(os.path.join(OUT, 'index.json'), 'w', encoding='utf-8'),
              ensure_ascii=False, indent=0, sort_keys=True)
    print(f'{len(index)} phrases au total, {made} nouvelles ({chars} caractères envoyés).')


if __name__ == '__main__':
    main()
