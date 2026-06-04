# 11 — Paramètres & opt-outs

> Source : CAHIER §1.11 + §3.3.11/3.3.13. Le **panel « Plus » (5ᵉ onglet)** donne
> accès à 6 catégories de réglages. L'opt-out est une **exigence absolue** du projet.

## 1. Stockage : deux mécanismes, deux responsabilités

> La spec décrivait deux tables se recouvrant. On
> sépare clairement :

| Table | Contenu | Forme |
|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------|
| `preferences` | **Réglages utilisateur** : langue, thème, unités, sens swipe, niveau d'expérience, opt-outs (géoloc, notifications, sync, communauté, lunaire), notifications granulaires, plage NPD | Singleton structuré (`id='singleton'`), CHECK par champ |
| `parametres` | **État applicatif technique** : `app.first_launch`, `app.db_version`, `sync.port`, `sync.device_name`, `meteo.refresh_hours`… | Clé-valeur (`namespace.cle`) |

Voir [06-modele-de-donnees-sqlite.md](06-modele-de-donnees-sqlite.md). Les deux
tables sont **locales** (non synchronisées) : chaque appareil a ses propres
préférences et son propre état.

## 2. Catégorie 1 — Préférences générales

| Réglage | Valeurs | Défaut |
|-----------------------|-------------------------------------------------|-----------|
| Langue | auto (système) / français / anglais | auto |
| Thème | auto / clair / sombre | auto |
| Système d'unités | métrique / impérial | métrique |
| Sens des gestes swipe | standard / inversé (aperçu interactif, global) | standard |
| Niveau d'expérience | débutant / intermédiaire / expert | débutant |

Le niveau d'expérience influence le détail des recommandations et la visibilité
des options avancées.

## 3. Catégorie 2 — Confidentialité & opt-outs

| Opt-out | Valeurs | Défaut | Mode dégradé |
|-----------------------------|---------------------------------------------------|-----------------|-------------------------------------------------------|
| Géolocalisation | désactivée / manuelle (ville) / gps | **désactivée** | pas de météo auto ni de déduction de zone climatique |
| Synchronisation WiFi locale | activée / désactivée | **désactivée** | pas de sync entre appareils |
| Communauté P2P (V2) | opt-in strict | **désactivée** | — |
| Calendrier lunaire | opt-in | **désactivée** | — |
| Récupération météo auto | activée / désactivée | activée | carte météo masquée, actualisation manuelle |
| Notifications | cf. catégorie 3 | activées | rappels visibles uniquement dans l'app |

> **Règle d'or** : aucune fonctionnalité n'est *cassée* par un opt-out — un
> fallback est toujours prévu (cf. parcours 5 dans [10](10-parcours-utilisateur.md)).

## 4. Catégorie 3 — Notifications

- **Interrupteur maître** : coupe toutes les notifications en un geste.
- **Granularité par catégorie** : semis, arrosage, récolte, météo critique,
  entretien, rotation — chacune activable indépendamment.
- **Plage « ne pas déranger »** (optionnelle) : créneau sans notification (ex.
  22h00 → 07h00). Les deux bornes ensemble, ou aucune.

Stocké dans `preferences.notifications_par_categorie` (JSON) +
`ne_pas_deranger_debut/fin`.

## 5. Catégorie 4 — Synchronisation & sauvegarde

- Synchronisation locale : statut, appareils appairés, dernière sync.
- Export : JSON (intégral) ou CSV (par table).
- Import : restauration depuis un export antérieur.
- Réinitialisation : suppression complète des données locales (double confirmation).

## 6. Catégorie 5 — Transparence des données (principe UX n°6)

- Visualisation des données stockées : liste des tables, nombre d'enregistrements,
  taille sur disque.
- Journal des accès aux données sensibles (géolocalisation, notifications).
- Politique de confidentialité : texte clair, **hors-ligne**, consultable à tout moment.

## 7. Catégorie 6 — À propos

Version + numéro de build · licence (MIT) · lien GitHub · crédits (contributeurs,
données, librairies) · liens utiles (doc, signaler un bug, contribuer).

## 8. Registre des clés `parametres.*` (état technique)

| Namespace | Exemples |
|-----------|-----------------------------------------------------------------------------------------------------------|
| `app.*` | `app.first_launch` (bool, true), `app.db_version` (int, 1), `app.installation_date` (texte ISO) |
| `sync.*` | `sync.device_name` (hostname), `sync.port` (int, 8765), `sync.last_sync_at` — *l'interrupteur on/off est dans `preferences.sync_locale_active`, pas ici* |
| `meteo.*` | `meteo.latitude`, `meteo.longitude`, `meteo.city_name`, `meteo.refresh_hours` (int, 6) |

> Les anciennes clés `ui.*`, `optout.*`, `notif.*`, `community.*` de la spec
> sont **migrées vers la table `preferences`** (réglages utilisateur). À ne pas
> dupliquer dans `parametres`.

## 9. Aide contextuelle (paramètres associés)

| Paramètre | Type | Défaut |
|----------------------------|------|--------|
| `aide_contextuelle_active` | bool | `true` |
| `aide_doc_complete_active` | bool | `true` |

Détail du système d'aide : [10-parcours-utilisateur.md](10-parcours-utilisateur.md).
