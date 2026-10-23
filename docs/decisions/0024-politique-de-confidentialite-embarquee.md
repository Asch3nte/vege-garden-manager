# ADR-0024 — Politique de confidentialité embarquée

- **Statut** : **Accepté**
- **Date** : 2026-10-23

## Contexte

La politique de confidentialité doit être consultable hors ligne dans l'app
(docs/11 §6) et publiée en ligne pour les stores. Elle n'existait que dans
`docs/`.

## Décision

- **Source unique** : `docs/politique-confidentialite.md` (fr) et
  `docs/politique-confidentialite.en.md` (en), déclarés tels quels comme
  assets dans `pubspec.yaml`. Le fichier lu sur GitHub est celui de l'app.
- **Rendu maison**, sans dépendance : `LecteurDocument` lit un sous-ensemble
  de Markdown (titres `#` à `###`, paragraphes, puces `- `, `**gras**`,
  `[texte](https://…)`) ; `VueDocument` l'affiche avec le thème. Seuls les
  liens `https` sont actifs, ouverts par `AbstractOuvertureLienService`.
- **Lecture** : `AbstractPolitiqueConfidentialiteSource` (domaine), lue par
  `rootBundle` en infrastructure ; anglais si l'app est en anglais, français
  sinon.
- **Accès** : Paramètres › Confidentialité & opt-outs, et À propos.

## Conséquences

- Les deux fichiers doivent rester dans le sous-ensemble lu ; un test les
  analyse, vérifie sections et liens, et échoue si une syntaxe non lue
  apparaîtrait brute.
- Une modification de la politique passe par une nouvelle version de l'app,
  ce que la politique annonce (point 10).
- Écartés : clés ARB (deux copies à synchroniser), `flutter_markdown_plus`
  (dépendance pour un seul écran).
