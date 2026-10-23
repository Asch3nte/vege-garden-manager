# 18 — Publication Android

Procédure de signature et de publication d'une version Android.

## Identifiant

`com.potagerer.pot_a_gerer` (`android/app/build.gradle.kts`). Définitif dès
la première publication : le changer crée une autre application, sans mise à
jour possible.

## Clé de release (une seule fois)

1. Générer la clé, hors du dépôt :

   ```sh
   keytool -genkeypair -keystore ~/cles/pot-a-gerer.jks -alias pot-a-gerer \
     -keyalg RSA -keysize 4096 -validity 10000
   ```

2. **La sauvegarder** (mot de passe compris) en deux endroits sûrs. Perdue,
   plus aucune mise à jour n'est possible pour les installations existantes.
3. Secrets du dépôt GitHub (Settings › Secrets and variables › Actions) :

   | Secret | Valeur |
   |---|---|
   | `ANDROID_KEYSTORE_BASE64` | `base64 -w0 ~/cles/pot-a-gerer.jks` |
   | `ANDROID_KEYSTORE_PASSWORD` | mot de passe du keystore |
   | `ANDROID_KEY_ALIAS` | `pot-a-gerer` |
   | `ANDROID_KEY_PASSWORD` | mot de passe de la clé |

4. Build local signé (facultatif) : `android/key.properties`, ignoré par git :

   ```properties
   storeFile=/home/<vous>/cles/pot-a-gerer.jks
   storePassword=…
   keyAlias=pot-a-gerer
   keyPassword=…
   ```

   Sans ce fichier, `flutter build apk --release` signe avec la clé de debug
   (avertissement Gradle) : utile en local, jamais à distribuer.

## Publier une version

1. Mettre `version:` à jour dans `pubspec.yaml` (`1.0.0+1` : nom + numéro de
   build, à incrémenter à chaque version).
2. Fusionner sur `main`, puis pousser le tag correspondant :

   ```sh
   git tag v1.0.0 && git push origin v1.0.0
   ```

3. Le workflow `release.yml` :
   - refuse un tag différent de la version du `pubspec.yaml` ;
   - construit l'APK et l'AAB signés ;
   - refuse un APK signé avec la clé de debug ;
   - crée un **brouillon** de Release GitHub avec l'APK, l'AAB et
     `SHA256SUMS`.
4. Relire le brouillon, puis le publier depuis GitHub.
