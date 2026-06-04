# 10 — Parcours utilisateur

> Source : CAHIER §4.2.4. Flux pas-à-pas servant de référence d'implémentation
> Flutter. Les composants cités (`AppEmptyState`, `AppDialog`…) sont décrits dans
> [09-ux-et-navigation.md](09-ux-et-navigation.md).

## Parcours 1 — Premier lancement (onboarding) · cible < 60 s

| # | Écran | Action | Notes |
|---|----------------------|-----------------------------------------|--------------------------------------------------------------|
| 1 | Splash (≤ 1.5 s) | — | Init BDD locale, chargement des fiches YAML |
| 2 | Bienvenue | `[Faire le tour rapide]` ou `[Passer]` | « 100% local, sans compte, open source » |
| 3 | Localisation | Saisie ville **ou** `[Utiliser GPS]` | GPS refusé → fallback saisie. Skip possible. |
| 4 | Niveau d'expérience | Sélection segmentée | Débutant / Intermédiaire / Expert (défaut : **Débutant**) |
| 5 | Accueil (état vide) | `[+ Créer mon premier potager]` | `AppEmptyState` avec CTA |

**Décisions** : 3 écrans max ; tous skippables sauf la bienvenue ; **aucune
création de compte** ; géoloc **opt-in explicite** ; niveau modifiable plus tard.

**Cas d'erreur** : GPS refusé → snackbar + bascule saisie manuelle ; ville
introuvable → `AppErrorState` + `[Réessayer]` ; init BDD échoue → `AppDialog`
critique.

**État final** : utilisateur sur l'accueil, préférences enregistrées, **aucune
donnée transmise** (sauf appel Open-Meteo si GPS accepté).

## Parcours 2 — Création potager + première plantation · cible < 2 min

**Création du potager** : Accueil (empty) → formulaire (nom obligatoire, surface
optionnelle, type — défaut pleine terre) → `[Créer]` (insert BDD, snackbar) →
carte du potager.

**Ajout d'une zone** (optionnel) : `[+ Ajouter une zone]` ou `[Passer]` (on peut
planter directement dans le potager) → nom + surface + exposition → `[Créer]`.

**Première plantation** : `[+ Nouvelle plantation]` → catalogue **filtré « à
planter maintenant »** (mois courant + climat) → fiche → `[Planter dans mon
potager]` (pré-remplissage) → date (défaut aujourd'hui) + quantité + zone →
`[Planter]` (insert + **génération auto des tâches calendrier**) → snackbar avec
`[Voir calendrier]`.

**Décisions** : le potager est l'entité minimale (planter sans zone possible) ;
catalogue filtré par défaut ; pré-remplissage maximum ; génération auto des tâches
(arrosage, récolte estimée).

**État final** : 1 potager, 0–1 zone, 1 plantation active, tâches générées.

## Parcours 3 — Consultation calendrier · cible < 10 s

Ouvrir le calendrier (vue jour par défaut) → swipe gauche sur une tâche pour la
marquer **faite** (avec undo snackbar) ou la **reporter**.

## Parcours 4 — Sauvegarde & restauration · cible < 30 s

**Export** : Paramètres → « Sauvegarde & restauration » → `[Exporter (JSON)]` →
share sheet natif → `potagerer_backup_YYYY-MM-DD.json` → snackbar succès.

**Import** : `[Importer / restaurer]` → file picker `.json` → `AppDialog` avec
**résumé** (« 12 plantations, 3 potagers, 47 tâches détectés ») → choix du mode
`[Remplacer] [Fusionner (défaut)] [Annuler]` → progression → récap.

**Suppression totale** (critique, double garde-fou) : bouton rouge → `AppDialog`
étape 1 (case « Je comprends… ») → étape 2 (saisir le mot `SUPPRIMER`) →
`[Supprimer définitivement]` → wipe BDD → retour onboarding.

**Décisions** : export JSON par défaut (CSV en option) ; **aperçu avant import** ;
**jamais de cloud** (destination via share sheet natif) ; rollback complet si
l'écriture échoue en cours d'import.

## Parcours 5 — Opt-out d'une automation · cible < 3 taps

Paramètres → section concernée → **toggle** (auto-save immédiat) → snackbar info.

**Automations concernées** : géolocalisation, notifications, récupération météo
auto, synchronisation WiFi, communauté P2P (V2), feedbacks haptiques.

**Décisions** : toggle = auto-save (pas de bouton Enregistrer) ; conséquences
expliquées sous le toggle ; **aucune fonctionnalité cassée par un opt-out**
(fallback systématique) ; pas de « êtes-vous sûr ? » sur un opt-out.

**Cas particuliers** : désactiver le GPS (source active) → bascule auto sur
saisie manuelle ; désactiver les notifications → annulation des notifs planifiées
côté OS ; désactiver la sync → arrêt du service P2P local.

## Addendum — Système d'aide contextuelle

**Principe** : aide **pull, jamais push**. L'utilisateur peut refuser
l'onboarding mais retrouver à tout moment une aide ciblée sur le panel courant.

**Accès** : icône `?` (Phosphor) dans l'AppBar de chaque panel, après `+` et `⋮`.
Présente si `aide_contextuelle_active = true` (défaut). Désactivable globalement.

**Comportement** : tap `?` → `AppBottomSheet` dédié au panel :
1. Titre « Aide — [Nom du panel] ».
2. Sections repliables (accordion) : *À quoi sert ce panel ?* · *Actions
   principales* · *Astuces* (gestes).
3. Bas de sheet : `[Voir l'aide complète]` → page in-app dédiée (doc longue,
   captures, 100% hors-ligne, Markdown via `flutter_markdown`) ; `[Consulter la
   doc en ligne]` → GitHub (navigateur externe).

**Doc in-app** : une page par panel, bundlée dans les assets (`assets/docs_aide/`),
**aucun chargement réseau**.

**Tour guidé rejouable** : Paramètres → Aide & support → `[Rejouer le tour de
bienvenue]`.

**Paramètres associés** :

| Paramètre | Type | Défaut | Description |
|----------------------------|------|--------|--------------------------------------------------------|
| `aide_contextuelle_active` | bool | `true` | Affiche l'icône `?` dans l'AppBar |
| `aide_doc_complete_active` | bool | `true` | Affiche « Voir l'aide complète » dans le bottom sheet |

**Contenu par panel** : Accueil (vue d'ensemble, météo, tâches) · Mes potagers
(hiérarchie, swipe) · Calendrier (vues, swipe = faire, génération auto) ·
Catalogue (filtres, fiches perso, « à planter maintenant ») · Paramètres
(opt-outs, sauvegarde, suppression).

## Synthèse des cibles de performance

| Parcours | Cible |
|-----------------------------------|-----------|
| 1. Premier lancement | < 60 s |
| 2. Création potager + plantation | < 2 min |
| 3. Consultation calendrier | < 10 s |
| 4. Sauvegarde / restauration | < 30 s |
| 5. Opt-out automation | < 3 taps |
