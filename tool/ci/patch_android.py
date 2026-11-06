#!/usr/bin/env python3
"""
patch_android.py — post-`flutter create` Android customisation for JARVIS AI.

The android/ folder is intentionally NOT committed (zero binaries in git, always
in sync with the installed Flutter/Gradle/SDK versions — same approach as
louis-cfm/coucou keeping signing material out of the repo).

CI/local flow:
    flutter create --platforms=android --org com.jarvisai --project-name jarvis_ai .
    python3 tool/ci/patch_android.py

This script:
  1. injects INTERNET + RECORD_AUDIO permissions (voice assistant);
  2. adds the SpeechRecognizer <queries> block (Android 11+ package visibility);
  3. declares the microphone hardware feature (optional at install time);
  4. renames the app label to "JARVIS AI".
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / 'android' / 'app' / 'src' / 'main' / 'AndroidManifest.xml'

PERMISSIONS = [
    '<uses-permission android:name="android.permission.INTERNET"/>',
    '<uses-permission android:name="android.permission.RECORD_AUDIO"/>',
]

QUERIES = '''    <queries>
        <intent>
            <action android:name="android.speech.RecognitionService"/>
        </intent>
    </queries>
'''

FEATURE = '<uses-feature android:name="android.hardware.microphone" android:required="false"/>'


def patch_manifest() -> None:
    if not MANIFEST.exists():
        sys.exit(f'AndroidManifest.xml introuvable : {MANIFEST}\n'
                 f'Exécutez d’abord : flutter create --platforms=android --org com.jarvisai --project-name jarvis_ai .')

    text = MANIFEST.read_text(encoding='utf-8')

    # 1) permissions, inserted right after the <manifest ...> opening tag
    for perm in PERMISSIONS:
        if perm in text:
            continue
        m = re.search(r'<manifest[^>]*>', text)
        text = text[:m.end()] + '\n    ' + perm + text[m.end():]

    # 2) microphone feature after the permissions
    if FEATURE not in text:
        m = re.search(r'<manifest[^>]*>', text)
        text = text[:m.end()] + '\n    ' + FEATURE + text[m.end():]

    # 3) queries block before </manifest> (outside <application>)
    if 'RecognitionService' not in text:
        text = text.replace('</manifest>', QUERIES + '</manifest>')

    # 4) application label
    text = re.sub(r'android:label="[^"]*"', 'android:label="JARVIS AI"', text, count=1)

    MANIFEST.write_text(text, encoding='utf-8')
    print('✓ AndroidManifest.xml patché (INTERNET, RECORD_AUDIO, queries, label JARVIS AI)')


def report() -> None:
    text = MANIFEST.read_text(encoding='utf-8')
    ok = 'RECORD_AUDIO' in text and 'INTERNET' in text and 'RecognitionService' in text
    print('✓ Manifest valide' if ok else '⚠ Manifest incomplet — vérifiez manuellement')
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    patch_manifest()
    report()
