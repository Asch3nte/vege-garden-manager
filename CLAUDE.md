# Pot'à Gérer

Application open source (MIT) de gestion de potager, multiplateforme (Linux,
Windows, macOS, Android, iOS), **100 % locale**, approche permaculturelle.
Projet personnel : aucune règle, aucun outil Selgea ne s'applique ici.

Rôle de l'agent : exécutant rigoureux. Une alternative nettement meilleure se
signale après la réponse, séparée, justifiée en une phrase. Aucune décision
structurante sans validation du dev.

## Contraintes absolues
1. Aucune donnée utilisateur sur un serveur externe.
2. Aucune identité requise.
3. Tout opt-out possible et effectif (géoloc, notifs, sync, communauté).
4. POO stricte.
5. Aucune étape sautée sans validation explicite.
6. Aucune dépendance (app ou outillage) ajoutée sans validation.
7. Tests écrits en même temps que le code.

APIs externes autorisées : Open-Meteo, Nominatim (ADR-0016). Toute autre : validation.

## Stack
Flutter 3.47.7 · drift · Riverpod · go_router · `http` · `flutter_local_notifications`
· `geolocator` · YAML embarqué · `intl` + ARB · `flutter_test` + `mocktail` ·
`share_plus` + `file_picker`. Détail : [docs/03](docs/03-stack-technique.md).
Architecture 4 couches (Presentation → Application → Domain ← Infrastructure) :
[docs/04](docs/04-architecture-en-couches.md).

## Concision (s'applique à tout)
- Réponses, commentaires, docs, messages de commit : strict minimum, langage impersonnel.
- Chaque réponse commence par une ligne : `Étape N — fait : … · suite : …`.
- Code et commentaires en anglais ; UI en français via ARB.
- Commentaires de l'app (dartdoc `///` sur l'API publique, commentaires internes) :
  concis, droit au but, une phrase si possible. Ils ne parlent que du code :
  aucune personne nommée, aucune référence externe (ADR, docs, lot, ticket, date,
  session). Aucun commentaire qui paraphrase le code ; un commentaire interne
  n'explique qu'un « pourquoi » non évident.

## Règles de code
- Encapsulation (`_field`, getters), abstractions pour tout composant générique.
- Exceptions métier typées ; jamais `throw Exception(...)`, jamais de `catch` silencieux.
- IDs `String` UUID v4. Listes retournées via `List.unmodifiable()`.
- `domain/` ne dépend de rien. Couverture visée ≥ 80 % sur `domain/`.
- Aucun texte UI en dur.
- Sécurité dès la conception.

## Workflow
1. Branche courte depuis `main` : `feat/`, `fix/`, `content/`, `chore/`, `docs/`.
   Jamais de commit direct sur `main`. Une branche = un chantier.
2. Conventional Commits.
3. Avant PR, vert en local : `flutter analyze` + `flutter test` (via le MCP Dart quand dispo).
4. Relecture : `/code-review` sur le diff ; `/security-review` en plus dès que le
   diff touche réseau, fichiers, import/export, permissions ou notifications.
5. PR GitHub (`gh pr create`) vers `main` ; merge une fois la CI verte
   (analyze, tests, osv-scanner, gitleaks).
6. Décision structurante → ADR dans [docs/decisions/](docs/decisions/).

Code généré non versionné : `flutter gen-l10n` puis
`dart run build_runner build --delete-conflicting-outputs`.

## Sources de vérité
- Documentation : [docs/README.md](docs/README.md) ; `docs/` fait foi.
- Reste à faire : [RESTE_A_FAIRE.md](RESTE_A_FAIRE.md) (source unique).
- Contenu du catalogue : [FICHES A CREER.md](FICHES%20A%20CREER.md) + `assets/fiches_plantes/_schema/id_registry.yaml`.
- [vege-garden-export/](vege-garden-export/README.md) : maquettes React gelées,
  lecture seule, réimplémentées en Flutter ; `docs/08` fait foi sur les tokens.

## Commandes du dev
`/contexte` · `/recap` · `/stack` (skills du projet).
