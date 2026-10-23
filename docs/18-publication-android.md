# 18 — Publication (Android, Linux, Windows)

Procédure de signature et de publication d'une version. Android est signé ;
Linux (`.tar.gz`) et Windows (`.zip`) ne le sont pas : Windows affiche un
avertissement SmartScreen au premier lancement.

**Limite desktop** : sous Linux, le plugin de notifications ne sait pas
programmer ; un rappel ne s'affiche que si l'application est ouverte à son
heure.

## Identifiant

`com.potagerer.pot_a_gerer` (`android/app/build.gradle.kts`). Définitif dès
la première publication : le changer crée une autre application, sans mise à
jour possible.

## Clé de release (une seule fois)

1. Générer la clé, hors du dépôt :

   ```sh
   mkdir -p ~/cles && chmod 700 ~/cles
   keytool -genkeypair -keystore ~/cles/pot-a-gerer.jks -alias pot-a-gerer \
     -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=Pot'à Gérer"
   ```

   Le nom (`-dname`) est **public** : il est lisible dans le certificat de
   chaque APK distribué. Rien n'y est vérifié ni obligatoire ; un nom de
   projet ou un pseudonyme suffit, sans nom, ville ni pays.

2. **La sauvegarder** (mot de passe compris) en deux endroits sûrs. Perdue,
   plus aucune mise à jour n'est possible pour les installations existantes.
3. Secrets du dépôt GitHub (Settings › Secrets and variables › Actions) :

   | Secret | Valeur |
   |---|---|
   | `ANDROID_KEYSTORE_BASE64` | `base64 -w0 ~/cles/pot-a-gerer.jks` |
   | `ANDROID_KEYSTORE_PASSWORD` | mot de passe du keystore |
   | `ANDROID_KEY_ALIAS` | `pot-a-gerer` |
   | `ANDROID_KEY_PASSWORD` | mot de passe de la clé |

4. Vérifier les secrets : onglet Actions › Release › « Run workflow » (ou
   `gh workflow run release.yml`). Ce lancement manuel signe l'APK et l'AAB
   sans créer de Release ; le journal de l'étape « Refuse a debug-signed APK
   or AAB » affiche l'empreinte `SHA-256` du certificat, à comparer avec
   `keytool -J-Duser.language=en -list -v -keystore ~/cles/pot-a-gerer.jks | grep -E 'SHA256|error'`
   (mêmes octets ; `-J-Duser.language=en` évite une sortie traduite).
5. Build local signé (facultatif) : `android/key.properties`, ignoré par git :

   ```properties
   storeFile=~/cles/pot-a-gerer.jks
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

3. Le workflow `release.yml` (ADR-0025) :
   - refuse un tag hors de `main` ou différent de la version du
     `pubspec.yaml` ;
   - construit l'APK et l'AAB signés, l'archive Linux (sur Ubuntu 22.04,
     pour les glibc anciennes) et l'archive Windows ;
   - refuse un APK ou un AAB signé avec la clé de debug ;
   - crée un **brouillon** de Release GitHub avec tous ces fichiers et
     `SHA256SUMS` (relancé, il met à jour le brouillon existant).
4. Relire le brouillon, puis le publier depuis GitHub.
