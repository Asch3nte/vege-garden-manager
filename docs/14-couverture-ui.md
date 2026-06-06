# 14 — Couverture UI (matrice fonction → écran)

> **But.** Garantir que **toute fonction implémentée dans le code** (use cases,
> CRUD, services, opt-outs) est **atteignable depuis l'UI**, et qu'aucun écran ne
> promette une fonction inexistante. C'est la **checklist partagée** entre le
> développement (couches Domain→Application, déjà faites) et la conception des
> écrans (Presentation, design system).
>
> **Mode d'emploi.** À chaque écran conçu (Claude Design / Penpot) ou codé,
> cocher la (les) ligne(s) couverte(s) et renseigner l'écran réel. Une ligne qui
> reste `☐ orpheline` à la fin = une fonction codée mais inaccessible → bug de
> couverture. Un écran sans ligne en face = fonction promise sans moteur → à
> implémenter ou retirer de la maquette.
>
> **Source de vérité du code** : inventaire extrait de `lib/application/`
> (use cases + notifiers), `lib/domain/repositories/` (services) et
> `docs/11-parametres-et-opt-outs.md` (opt-outs). **Source de vérité des écrans** :
> les 5 sections de [`docs/09`](09-ux-et-navigation.md) §3 et les parcours de
> [`docs/10`](10-parcours-utilisateur.md).
>
> Légende état : `☐` à faire · `🟡` en cours / maquette · `✅` codé & atteignable.

---

## Sections UI de référence (doc 09 §3)

| # | Section | Icône | Rôle |
|---|---|---|---|
| 1 | 🏠 **Accueil** | `House` | Tâches du jour, alertes, conseils |
| 2 | 🌱 **Potager** | `Plant` | Potagers → parcelles → plantations, plan, historique (FAB) |
| 3 | 📖 **Catalogue** | `BookOpen` | Fiches plantes (lecture) |
| 4 | 📅 **Calendrier** | `Calendar` | Tâches/rappels datés |
| 5 | ⋯ **Plus** | `DotsThree` | Paramètres, opt-outs, sauvegarde, à propos |
|   | (transverse) | — | **Onboarding** (premier lancement, doc 10 P1) |

---

## A. Fonctions métier (moteur — `lib/application/`)

Le cœur calculatoire. Chacune doit avoir un **point d'entrée UI** (écran ou
action) ET un **rendu** (où le résultat s'affiche).

| Fonction (use case) | Ce qu'elle produit | Écran déclencheur | Rendu UI | État |
|---|---|---|---|---|
| `RecommanderPlantes` | Plantes classées pour une parcelle | 🌱 Potager › vue parcelle | Liste reco (score + raisons) + flag « saison non vérifiée » | ☐ |
| `EstimerRecolte` | Fenêtre de récolte d'une plantation | 🌱 Potager › vue plantation | Dates min/max sur la fiche plantation | ☐ |
| `CalculerBesoinArrosage` | Conseil d'arrosage (urgence + indice) | 🏠 Accueil + 🌱 vue plantation | Badge urgence + « pluie récente/prévue », rétention | ☐ |
| `DetecterAlertesMeteo` | Alertes gel/canicule/pluie (génériques) | 🏠 Accueil | Bandeau d'alerte (icône `Bell`) | ☐ |
| `GenererTaches` | Tâches dérivées des rappels récurrents | 📅 Calendrier / 🏠 Accueil | Tâches du jour (déclenché en arrière-plan) | ☐ |

> ⚠️ **Point à trancher (écart) :** `CalculerBesoinArrosage`, `EstimerRecolte` et
> `GenererTaches` ne sont pas nommément mappés dans doc 09 §5 — confirmer leur
> écran de rendu lors de la conception.

---

## B. CRUD — entités (notifiers `lib/application/state/`)

Chaque entité expose **créer / modifier / supprimer** (vérifié). L'UI doit
offrir les 3 (sauf justification). `R` (lecture) = l'écran liste/détail.

| Entité | Notifier | Créer | Modifier | Supprimer | Écran(s) | État |
|---|---|---|---|---|---|---|
| Potager | `potagers_notifier` | `+` liste potagers | swipe/⋮ | swipe (soft) | 🌱 niv. 1 | ☐ |
| Parcelle | `parcelles_notifier` | `+` dans un potager | swipe/⋮ | swipe (soft) | 🌱 niv. 2 | ☐ |
| Plantation | `plantations_notifier` | FAB / `+` parcelle | édition | fin/arrachage | 🌱 niv. 3 | ☐ |
| Récolte | `recoltes_notifier` | action sur plantation | édition | swipe | 🌱 vue plantation | ☐ |
| Observation | `observations_notifier` | action sur plantation | édition | swipe | 🌱 vue plantation | ☐ |
| Équipement | `equipements_notifier` | `+` potager/parcelle | swipe/⋮ | swipe | 🌱 ou ⋯ | ☐ |
| Tâche | `taches_notifier` | `+` calendrier | éditer / reporter | swipe (faite) | 📅 Calendrier | ☐ |
| Rappel | `rappels_actifs_notifier` | `+` calendrier | éditer | swipe | 📅 Calendrier | ☐ |
| Fiche plante | (catalogue, lecture seule) | — | — | — | 📖 Catalogue | ☐ |

> Note : `fiche_plante` est en **lecture seule** côté app (contribution = YAML,
> doc 07). `preferences_utilisateur` est traité en §D.

---

## C. Services (capacités `lib/domain/repositories/abstract_*_service`)

| Service | Capacité | Où dans l'UI | État |
|---|---|---|---|
| `meteo_service` | Prévisions/observations (Open-Meteo + cache) | Implicite (arrosage, alertes) ; statut/refresh dans ⋯ | ☐ |
| `notification_service` | Notifs locales programmées | Déclenché par rappels ; réglages dans ⋯ §Notifications | ☐ |
| `geolocalisation_service` | Position GPS (opt-out) | Onboarding + ⋯ §Confidentialité | ☐ |
| `sauvegarde_service` | Export/import local | ⋯ §Sauvegarde (doc 10 P4) | ☐ |
| `sync_service` | Sync WiFi locale | **V2** — désactivé par défaut (ne pas exposer en V1) | ⏭️ |

---

## D. Paramètres & opt-outs (doc 11 — 6 catégories)

**Exigence absolue** : tout opt-out doit être présent ET fonctionnel. Section ⋯.

| Catégorie (doc 11) | Réglages clés | Opt-out ? | État |
|---|---|---|---|
| 1 — Préférences générales | langue, thème, unités, sens swipe, niveau d'expérience | — | ☐ |
| 2 — Confidentialité | géoloc, **sync**, communauté, lunaire | ✅ tous | ☐ |
| 3 — Notifications | interrupteur maître, par catégorie, plage « ne pas déranger » | ✅ maître | ☐ |
| 4 — Sync & sauvegarde | sauvegarde/restauration ; sync (statut, appairage) | ✅ sync | ☐ |
| 5 — Transparence données | liste tables + nb enregistrements ; journal d'accès sensibles | — | ☐ |
| 6 — À propos | version, licence MIT, liens projet | — | ☐ |

---

## E. Parcours utilisateur (doc 10) — bout en bout

Vérifie que les fonctions **s'enchaînent** (pas juste qu'elles existent).

| Parcours (doc 10) | Fonctions traversées | État |
|---|---|---|
| P1 — Onboarding (< 60 s) | position→dérivations, `CreerPotager`, opt-outs | ☐ |
| P2 — Potager + 1ʳᵉ plantation (< 2 min) | `CreerParcelle`, `RecommanderPlantes`, `CreerPlantation`, `EstimerRecolte` | ☐ |
| P3 — Consultation calendrier (< 10 s) | `GenererTaches`, tâches/rappels | ☐ |
| P4 — Sauvegarde/restauration (< 30 s) | `sauvegarde_service` | ☐ |
| P5 — Opt-out d'une automation (< 3 taps) | préférences, opt-outs | ☐ |

---

## F. Écarts connus à arbitrer (à garder en tête en concevant l'UI)

1. **Rendu de l'arrosage / récolte / tâches** : non mappés explicitement dans
   doc 09 §5 (voir §A) — décider l'écran porteur.
2. **Onboarding → dérivations** (hémisphère/climat/rusticité/sol depuis la
   position) : prérequis V1 noté en mémoire projet, écran à concevoir.
3. **Précision météo par plante** et **conformité plantes/territoire** :
   reportés V1.1/V2 (doc 13 §2.1 / §2.2) — **ne pas** les promettre dans l'UI V1.
4. **`sync_service`** : présent dans le code (interface) mais **V2** — l'écran
   doit afficher « désactivé » sans prétendre synchroniser.

---

> Maintenir ce document **en regard du code** : toute nouvelle fonction
> (use case / notifier / service / opt-out) ajoute une ligne ici, et toute
> maquette d'écran coche les lignes qu'elle réalise.
