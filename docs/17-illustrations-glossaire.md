# 17 — Ajouter une illustration au glossaire (procédure)

> Pipeline défini par l'[ADR-0017](decisions/0017-glossaire-aide-lexique.md)
> (D4, Lot 5). Cette page est la **procédure pas à pas** pour ajouter une
> image à une page du lexique « Aide & lexique ». Le peuplement est
> **incrémental** : une page sans image n'affiche simplement pas de bloc.

---

## 1. Vue d'ensemble

Une illustration = **3 choses qui doivent rester cohérentes** (le lint et les
tests cassent sinon) :

| Quoi | Où |
|---|---|
| Le **fichier image** | `assets/images/glossaire/<id du terme>.webp` |
| L'**enregistrement** | `lib/presentation/glossaire/illustrations_glossaire.dart` → `idsIllustres` |
| La **provenance** | `assets/images/glossaire/SOURCES.txt` (une entrée par fichier) |

Le rattachement à la page est **automatique** : aucun code d'écran à toucher.
Dès que l'id est enregistré et que le fichier existe, l'image apparaît en haut
de la page du terme (`PageTermeGlossaire`), sous l'en-tête.

## 2. Trouver l'id du terme

Le nom du fichier **est** l'id de la page, préfixe compris :

- **Outils** : `outil.<slug>` — ex. `outil.oya`, `outil.goutte-a-goutte`,
  `outil.composteur` (liste complète : `idOutilEquipement` dans
  `lib/presentation/glossaire/catalogue/outils.dart`) ;
- **Notions** (textures, techniques, mécanismes…) : `notion.<slug>` — ex.
  `notion.sol-argileux`, `notion.paillage`, `notion.meca-fixation-azote`
  (inventaire : `lib/presentation/glossaire/couverture_glossaire.dart`) ;
- **Familles / bioagresseurs** (dérivés des YAML) : `famille.<slug>` /
  `bio.<slug>` — ex. `famille.solanaceae`, `bio.mildiou`. Fonctionne aussi :
  le registre sert l'image dès qu'elle existe.

Astuce : dans l'app, l'id est visible dans la route de la page
(`/plus/aide/terme/<id>`).

## 3. Choisir l'image (règles de licence)

- **Autorisé aujourd'hui : domaine public (PD / Public Domain Mark) et CC0
  uniquement.**
- **CC-BY : pas encore** — l'attribution obligatoire n'est pas affichée dans
  « À propos ». Le jour où ce câblage existe, CC-BY deviendra acceptable
  (l'ADR le permet). CC-BY-**SA** et toute licence NC/ND : **jamais**.
- Sources recommandées : [Wikimedia Commons](https://commons.wikimedia.org)
  (filtre licence sur la page du fichier — vérifier la section « Licensing »
  du fichier lui-même, pas celle de la galerie), collections open access de
  musées (MET, Rijksmuseum), photos d'agences fédérales US (USDA, EPA, LOC —
  domaine public d'office), planches botaniques anciennes (publiées avant
  1930 → domaine public).
- Toujours **noter l'URL exacte de la page du fichier** (pas seulement
  l'image) : elle va dans SOURCES.txt.

## 4. Préparer le fichier

- **Format : WebP** (seule extension acceptée par le lint).
- **Dimensions : 800 px maximum** sur le côté le plus long (plus petit, c'est
  bien aussi — ex. la gravure de cloche fait 250 px). Jamais d'agrandissement.
- **Poids indicatif : < 200 Ko** par image (qualité 78–85). Le jeu embarqué
  complet doit rester léger : ~100 Ko en moyenne est un bon objectif.
- **Recadrer** si le sujet n'occupe pas l'image (fond parasite, planche
  composite, marges de numérisation).

Avec ImageMagick (installé sur la machine de dev) :

```bash
# Cas simple : redimensionner (\> = ne jamais agrandir) + convertir
magick photo.jpg -resize 800x800\> -quality 80 \
  assets/images/glossaire/outil.composteur.webp

# Avec recadrage préalable (largeur x hauteur + décalage x + y)
magick photo.jpg -crop 360x640+240+40 +repage -resize 800x800\> -quality 80 \
  assets/images/glossaire/outil.recuperateur-eau.webp

# Contrôler le résultat (dimensions + poids)
identify -format '%f %wx%h %b\n' assets/images/glossaire/*.webp
```

## 5. Enregistrer l'id

Dans `lib/presentation/glossaire/illustrations_glossaire.dart`, ajouter l'id
au set (ordre libre, garder le regroupement par préfixe pour la lisibilité) :

```dart
const Set<String> idsIllustres = {
  'outil.oya',
  // …
  'outil.composteur',   // ← nouvel id
};
```

## 6. Consigner la provenance

Dans `assets/images/glossaire/SOURCES.txt`, ajouter une entrée au format en
vigueur (voir l'en-tête du fichier et les entrées existantes) :

```
Fichier : outil.composteur.webp
Terme   : Composteur (outil.composteur)
Source  : « Nom exact du fichier d'origine », auteur/institution,
          via Wikimedia Commons — description courte, recadrage éventuel.
          https://commons.wikimedia.org/wiki/File:...
Licence : CC0 (domaine public). Redimensionnée en WebP 800 px.
```

## 7. Vérifier

```bash
# Lint des référentiels — section 4 = illustrations :
#   image orpheline (fichier sans enregistrement), image non sourcée,
#   enregistrement sans fichier → ERREURS ; mention périmée → avertissement.
dart run tool/verifier_referentiels.dart

# Test d'intégrité du glossaire (liens, couverture, illustrations)
flutter test test/unit/presentation/glossaire/

# Contrôle visuel dans l'app : Plus → Aide & lexique → la page du terme
```

C'est tout : pas de pubspec à toucher (`assets/images/glossaire/` est déjà
déclaré), pas de code d'écran à modifier.

---

## 8. Récapitulatif express

1. Choisir une image **PD/CC0** (URL de la page du fichier notée).
2. `magick … -resize 800x800\> -quality 80 assets/images/glossaire/<id>.webp`
3. Ajouter `<id>` dans `idsIllustres` (`illustrations_glossaire.dart`).
4. Ajouter l'entrée dans `SOURCES.txt`.
5. `dart run tool/verifier_referentiels.dart` + `flutter test test/unit/presentation/glossaire/`.
