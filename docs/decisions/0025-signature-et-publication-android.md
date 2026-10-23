# ADR-0025 — Signature et publication Android

- **Statut** : **Accepté**
- **Date** : 2026-10-23

## Contexte

Les builds release étaient signés avec la clé de debug, et aucune
publication n'était automatisée. L'identifiant d'application restait un TODO
du gabarit Flutter.

## Décision

- **Identifiant** : `com.potagerer.pot_a_gerer`, définitif.
- **Clé** : une clé de release unique, détenue par le développeur, hors du
  dépôt. En local, `android/key.properties` (ignoré par git) ; sans lui, repli
  sur la clé de debug avec avertissement, pour le développement seulement.
- **Publication** : un tag `v*` sur `main`, égal à la version du
  `pubspec.yaml`, déclenche `release.yml`. Un job construit et signe l'APK et
  l'AAB (clé installée juste avant Gradle, après dépendances et génération de
  code), refuse une signature de debug ; un second job, seul à pouvoir écrire
  dans le dépôt, crée un **brouillon** de Release GitHub. La publication
  reste manuelle.
- **Desktop** : le même tag produit une archive Linux (`.tar.gz`, construite
  sur Ubuntu 22.04) et une archive Windows (`.zip`), non signées.
- Procédure : [docs/18](../18-publication-android.md).

## Conséquences

- Clé perdue : plus de mise à jour possible pour les installations
  existantes ; elle se sauvegarde en deux endroits.
- Le Play Store, s'il est retenu, ajoutera la signature par Google Play
  (clé d'envoi distincte), sans changer ce flux.
- Le numéro de build (`+N`) s'incrémente à la main à chaque version.
