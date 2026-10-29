# Documentation — Pot'à Gérer

Cette documentation est la **source de vérité** du projet. Elle résulte du
découpage et du nettoyage du cahier des charges et du document d'architecture
initiaux (sources historiques `CAHIER_DES_CHARGES.md` et `ARCHITECTURE.md`,
conservées hors du repo).

> En cas de contradiction avec une source historique, **`docs/` fait foi**. Les
> arbitrages sont consignés dans
> [decisions/0001-arbitrages-de-coherence.md](decisions/archive/PRE_DEV/0001-arbitrages-de-coherence.md).

## Plan de lecture

### 🧭 Cadrage
| Doc | Sujet |
|---|---|
| [01 — Vision & périmètre](01-vision-et-perimetre.md) | Philosophie, contraintes absolues, périmètre, utilisateur cible |
| [02 — Fonctionnalités V1](02-fonctionnalites-v1.md) | Recommandations, météo, arrosage intelligent, alertes, post-récolte |
| [03 — Stack technique](03-stack-technique.md) | Flutter, drift, Riverpod, dépendances validées |

### 🏛️ Conception technique
| Doc | Sujet |
|---|---|
| [04 — Architecture en couches](04-architecture-en-couches.md) | Clean Architecture 4 couches, DI Riverpod, flux |
| [05 — Modèle de domaine](05-modele-de-domaine.md) | Entités, Value Objects, enums, exceptions, interfaces |
| [06 — Modèle de données SQLite](06-modele-de-donnees-sqlite.md) | Schéma drift (12 tables), conventions, contraintes |
| [07 — Base de connaissances YAML](07-base-de-connaissances-yaml.md) | Fiches plantes, chargement, contribution |

### 🎨 Expérience utilisateur
| Doc | Sujet |
|---|---|
| [08 — Design system](08-design-system.md) | « Carnet vivant » : couleurs, typo, espacement, icônes |
| [09 — UX & navigation](09-ux-et-navigation.md) | Principes UX, navigation, mapping des actions, composants |
| [10 — Parcours utilisateur](10-parcours-utilisateur.md) | Onboarding, parcours clés, aide contextuelle |

### ⚙️ Transverse
| Doc | Sujet |
|---|---|
| [11 — Paramètres & opt-outs](11-parametres-et-opt-outs.md) | Préférences, opt-outs, registre des paramètres |
| [12 — i18n & données](12-internationalisation-et-donnees.md) | Multilingue, stockage, vie privée, contraintes NF |
| [14 — Couverture UI](14-couverture-ui.md) | Matrice fonction → écran : checklist de couverture du moteur par l'UI |
| [16 — Enrichissement fiches plantes](16-enrichissement-fiches-plantes.md) | Champs manquants dans les fiches YAML pour le moteur de recommandation (rusticité, gel, difficulté, contenants, ravageurs…) |
| [17 — Illustrations du glossaire](17-illustrations-glossaire.md) | Procédure pas à pas : ajouter une image à une page du lexique (dossier, format WebP ≤ 800 px, licences PD/CC0, registre, SOURCES.txt, lint) |
| [18 — Publication](18-publication-android.md) | Clé de release, secrets CI, tag `v*` → brouillon de Release (Android signé, Linux, Windows) |
| [Audit 2026-10](audit-2026-10.md) | Audit du code : 44 constats classés gravité/effort, lints stricts, purge des commentaires |
| [Audit 2026-11](audit-2026-11.md) | Audit pré-V1 : preuves de non-perte, promesses, éducatif, sécurité ; lots de correction |
| [decisions/](decisions/) | ADR — décisions d'architecture |

## Pour le développement

- Conventions de code & contribution : [../CONTRIBUTING.md](../CONTRIBUTING.md)
- Contexte agent & règles strictes : [../CLAUDE.md](../CLAUDE.md)
- Reste à faire (lots, V1.1, V2) : [../RESTE_A_FAIRE.md](../RESTE_A_FAIRE.md)
