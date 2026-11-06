# Générer l'APK Android

Deux méthodes : **A) via GitHub Actions** (recommandé, zéro installation locale) ou **B) localement**.

Le dossier `android/` n'est **pas versionné** : il est régénéré par `flutter create`
à partir de votre SDK Flutter, puis personnalisé par `tool/ci/patch_android.py`
(permissions INTERNET / RECORD_AUDIO, label « JARVIS AI »). Zéro binaire dans git,
toujours synchronisé avec vos versions d'outils — même philosophie que
[louis-cfm/coucou](https://github.com/louis-cfm/coucou) qui garde son keystore hors du dépôt.

---

## Méthode A — APK via GitHub Actions (aucune installation requise)

1. Poussez votre branche (ou ouvrez une Pull Request vers `main`).
2. Le workflow **`android-apk`** (`.github/workflows/android-apk.yml`) se déclenche :
   - job `analyze-and-test` : `flutter pub get` → `flutter analyze` → `flutter test` ;
   - job `build-apk` : `flutter create` → patch manifest → `flutter build apk --release`.
3. À la fin, ouvrez **Actions → android-apk → Build release APK → Artifacts**
   et téléchargez **`jarvis-ai-release-apk`** (`app-release.apk`, ~40–60 Mo).
4. Copiez l'APK sur votre téléphone → appuyez → autorisez l'installation depuis des sources inconnues → installez.

Déclenchement manuel : onglet **Actions → android-apk → Run workflow**.

> Le badge en haut du README reflète l'état du workflow.

---

## Méthode B — Build local

### Prérequis

- **Flutter SDK ≥ 3.22** (stable) : <https://docs.flutter.dev/get-started/install>
- **Android Studio** (SDK Android) **ou** Android SDK cmdline-tools + licenses acceptées
- **JDK 17** (fourni avec Android Studio)

Vérifiez :

```bash
flutter doctor -v
```

### Étapes

```bash
git clone https://github.com/leoblanchart92-hub/Fuctus.git
cd Fuctus
python3 tool/ci/patch_android.py 2>/dev/null || true   # après create, voir ci-dessous

# 1) Générer le scaffolding Android (une seule fois)
flutter create --platforms=android --org com.jarvisai --project-name jarvis_ai .

# 2) Permissions + label
python3 tool/ci/patch_android.py

# 3) Dépendances
flutter pub get

# 4) Lancer sur téléphone branché (mode développeur + débogage USB)
flutter run --release

# 5) …ou produire l'APK
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

Installer sans IDE :

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### APK par architecture (plus légers)

```bash
flutter build apk --release --split-per-abi
# → app-armeabi-v7a-release.apk / app-arm64-v8a-release.apk / app-x86_64-release.apk
```

### APK debug (test rapide, clé debug automatique)

```bash
flutter build apk --debug
```

---

## Signer avec votre propre clé (optionnel, pour distribution sérieuse)

Par défaut, la CI signe l'APK release avec la **clé debug** — parfaitement installable
sur votre appareil. Pour une clé personnelle (jamais commitée) :

```bash
keytool -genkey -v -keystore ~/jarvis-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias jarvis
```

Puis créez `android/key.properties` (ignoré par git) :

```properties
storePassword=…
keyPassword=…
keyAlias=jarvis
storeFile=C:/chemin/absolu/jarvis-release-key.jks   # ou ~/jarvis-release-key.jks
```

Et dans `android/app/build.gradle`, ajoutez au-dessus de `android {` :

```groovy
def keystoreProperties = new Properties()
def keystoreFile = rootProject.file('key.properties')
if (keystoreFile.exists()) { keystoreProperties.load(new FileInputStream(keystoreFile)) }
```

…et remplacez `signingConfig signingConfigs.debug` par un `signingConfig` release dédié
(voir la doc Flutter « Signing the app »). Pour la CI : stockez le keystore en **base64**
dans les secrets GitHub (`ANDROID_KEYSTORE_B64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`),
décodez-le dans le workflow, écrivez `key.properties` à la volée. *Ne committez jamais `~/jarvis-release-key.jks`.*

---

## Dépannage

| Symptôme | Correctif |
|---|---|
| `flutter : command not found` | Ajoutez `<flutter>/bin` à votre PATH |
| `SDK location not found` | `flutter config --android-sdk /chemin/vers/Android/sdk` |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Désinstallez l'ancienne version : `adb uninstall com.jarvisai.jarvis_ai` |
| Micro inactif | Vérifiez la permission RECORD_AUDIO (Paramètres → Applications → JARVIS AI → Autorisations) |
| « clavier caché » sur petits écrans | Mode portrait forcé (voir `lib/main.dart`) |
| Build CI rouge sur `flutter create` | Relancez le workflow — le runner stable est éphémère |
