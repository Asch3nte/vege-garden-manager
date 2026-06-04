# 01 — Vision & périmètre

> Source : CAHIER §1.1–1.5. Document de référence — fait foi.

## 1. Vision

**Pot'à Gérer** est un assistant personnel de gestion de potager, conçu pour
être accessible à tout le monde, y compris des personnes **sans aucune
connaissance en jardinage ou en informatique**. L'application est à la fois :

- **Un assistant pratique** → quoi planter, quand, où, comment.
- **Un outil éducatif** → expliquer le *pourquoi* derrière chaque recommandation.
- **Une base de connaissances riche et explorable** → fiches détaillées,
  recherche, filtres, calendrier visuel.
- **Respectueuse de la nature** → approche permaculturelle, zéro chimique.
- **Respectueuse de l'utilisateur** → 100% local, aucune donnée sur serveur,
  tout opt-out possible.

## 2. Philosophie (non négociable)

- Zéro compromis sur la vie privée.
- Aucune donnée personnelle ou identitaire sur serveur centralisé.
- Tout opt-out possible (géolocalisation, notifications, automations, sync, communauté).
- Simplicité d'utilisation maximale (utilisable sans compétences informatiques).
- Approche naturelle et permaculturelle du jardinage.
- Open source, publié sur GitHub, documenté. **Licence : MIT.**

## 3. Contraintes absolues

1. Aucune donnée utilisateur sur serveur externe.
2. Aucune identité requise de l'utilisateur.
3. Tout opt-out doit être possible et fonctionnel.
4. POO stricte, sans exception.
5. Aucune dépendance externe non validée introduite silencieusement.
6. Fonctionne **hors ligne** (sauf la météo).
7. Aucune création de compte, aucune télémétrie.

## 4. Périmètre fonctionnel (vue d'ensemble)

| Dans le périmètre V1                                             |                                                    |
|------------------------------------------------------------------|----------------------------------------------------|
| Gestion du potager (pleine terre, surfaces, bacs, balcon, serre) | Suggestions post-récolte (conservation, recettes)  |
| Suivi des cultures en place                                      | Export des données (JSON/CSV)                      |
| Base de connaissances riche et explorable (~200 fiches)          | Mode sombre                                        |
| Recommandations intelligentes                                    | Multilingue (architecture prête dès V1)            |
| Associations bénéfiques & compagnonnage                          | Rotation des cultures avec historique              |
| Intégration météo (Open-Meteo)                                   | Arrosage intelligent basé météo                    |
| Calendrier personnalisé + rappels                                | Contenu éducatif contextuel                        |
| Interface responsive mobile-first                                | Format contributif pour la base de connaissances   |

> Le détail des comportements est dans [02-fonctionnalites-v1.md](02-fonctionnalites-v1.md).
> La répartition V1 / V1.1 / V2 est dans [13-roadmap-et-versioning.md](13-roadmap-et-versioning.md).

**Reporté en V2** (opt-in, désactivé par défaut) : communauté P2P locale,
calendrier lunaire, vue graphique des relations entre plantes.

## 5. Utilisateur cible

- **Profil principal** : novice complet, n'a jamais cultivé.
- **Profils secondaires** : jardinier amateur, jardinier intermédiaire.
- Pas de compétences informatiques supposées.
- Première utilisation = onboarding guidé pas à pas (et **skippable**).
- Le **niveau d'expérience** (débutant / intermédiaire / expert) ajuste la
  verbosité des explications et la visibilité des options avancées.

## 6. Plateforme

Application unique, responsive, **mobile-first**, utilisable sur PC. **Un seul
codebase** (Flutter). Cibles : Linux, Windows, macOS, Android, iOS.

## 7. Direction artistique (résumé)

Concept **« Carnet vivant »** : tons naturels (verts sourds, terre, crème,
brun doux), style épuré et organique, **aucun emoji ni icône cartoon dans
l'UI**, icônes fines (outline), typographie lisible et chaleureuse, espaces
aérés. **Mode sombre inclus dès la V1.**

> Spécification complète : [08-design-system.md](08-design-system.md).
