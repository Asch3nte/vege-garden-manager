# Contribuer à Pot'à Gérer

Merci de votre intérêt ! Ce projet est open source (MIT) et accueille deux
types de contributions : **du code** et surtout **des fiches plantes**.

---

## 🌿 Contribuer une fiche plante (le plus utile !)

La base de connaissances est un ensemble de fichiers **YAML**, un fichier par
plante, rangés par catégorie. Aucun savoir-faire en programmation n'est requis.

### Procédure

1. Repérez le bon dossier dans `assets/fiches_plantes/` :
   `legumes/`, `aromatiques/`, `fruits/` ou `fleurs_compagnonnage/`.
2. Dupliquez une fiche existante comme modèle (ex. `legumes/tomate.yaml`).
3. Renseignez les champs (voir le schéma de référence
   [`assets/fiches_plantes/_schema/fiche_plante_schema.yaml`](assets/fiches_plantes/_schema/)
   et la spec [docs/07-base-de-connaissances-yaml.md](docs/07-base-de-connaissances-yaml.md)).
4. Ouvrez une **Pull Request**. Un validateur vérifiera la structure.

> 💡 Depuis l'app, l'éditeur de fiches permet de créer une fiche via formulaire
> puis de l'**exporter en YAML** prêt à soumettre — sans écrire de YAML à la main.

### Conventions strictes pour les fiches

| Règle | Valeur |
|---|---|
| Nom de fichier | `[id_plante].yaml` en `snake_case`, sans accents |
| `id` | unique, immuable, `snake_case`, minuscules |
| Catégorie | une seule parmi `legume`, `aromatique`, `fruit`, `fleur_compagnonnage` |
| Champs `i18n` | `fr` **obligatoire**, autres langues optionnelles |
| Périodes | mois en entiers `1`–`12` |
| Références croisées (associations, rotation) | par `id` de fiche, jamais par nom commun |
| Encodage | UTF-8 |
| Indentation | 2 espaces (pas de tabulation) |

Une contribution complète = **1 fichier YAML valide + 1 PR**. Le contenu
multilingue est imbriqué dans la fiche (`i18n: { fr: …, en: … }`).

---

## 💻 Contribuer du code

### Avant de commencer
- Lisez [`CLAUDE.md`](CLAUDE.md) et [`docs/`](docs/) (architecture, modèle de
  domaine, conventions).
- Travaillez sur une branche dédiée depuis `develop`.

### Règles de développement (non négociables)
- **POO stricte** : encapsulation (`_field`), abstraction (interfaces), héritage
  justifié, polymorphisme.
- **Code et commentaires en anglais** ; textes d'**UI en français** via i18n
  (aucun texte en dur dans le code).
- **Documentation dartdoc** (`///`) sur toute classe / méthode publique.
- **Exceptions métier typées** (jamais `throw Exception('...')`), aucun `catch`
  silencieux.
- **Tests écrits en parallèle du code** (`flutter_test` + `mocktail`), jamais
  après. Cible : 80% de couverture sur `domain/`.
- Respect strict des **couches** : le `domain/` ne dépend de rien.
- **Aucune dépendance externe non validée** ajoutée silencieusement.

### Style & commits
- Formatage : `dart format .` · Analyse : `flutter analyze` (zéro warning).
- Messages de commit : [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`…).

### Workflow de PR
1. `dart format .` + `flutter analyze` + `flutter test` passent au vert.
2. PR vers `develop` avec description claire (quoi / pourquoi).
3. Une revue est nécessaire avant merge.

---

## 📜 Décisions d'architecture

Les choix structurants sont consignés sous forme d'**ADR** dans
[`docs/decisions/`](docs/decisions/). Proposez un nouvel ADR pour toute décision
ayant un impact durable sur l'architecture.

---

Merci, et bon jardinage logiciel ! 🌱
