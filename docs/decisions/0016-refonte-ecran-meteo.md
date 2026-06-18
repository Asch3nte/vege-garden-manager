# ADR-0016 — Refonte de l'écran météo : Nominatim, enrichissement modèle, vue détaillée

- **Statut** : Accepté — Lots 1–4 ✅ (complet)
- **Date** : 2026-06-18

---

## Contexte

L'`EcranMeteoDetail` actuel est fonctionnel mais très pauvre : sélecteur de
jours en chips + liste verticale d'heures avec température et probabilité de
pluie. Trois lacunes principales :

1. **Absence d'identité de source.** L'utilisateur ne sait pas d'où viennent
   les données (station, localité). Open-Meteo ne fournit pas de
   reverse-geocoding ; la seule info disponible dans sa réponse est le fuseau
   horaire (`"Europe/Brussels"`), trop imprécis pour les villes anglophones ou
   composées.

2. **Modèle météo partiel.** Open-Meteo peut fournir les codes météo WMO
   (nuageux, pluie, orage…) et la vitesse du vent par heure, mais ces variables
   ne sont pas encore demandées. Sans elles, l'écran ne peut pas afficher
   d'icônes ni de graphiques cohérents.

3. **Pas de lien avec les tâches.** L'écran ne montre pas pourquoi le moteur a
   généré les tâches du jour (arroser maintenant ? différer à cause de la pluie
   prévue ?). Or c'est le but déclaré de la rubrique météo : justifier les
   recommandations.

Le développeur a validé une refonte complète, avec les priorités suivantes :
sélecteur de jours visuel horizontal, détail horaire en colonnes compactes
scrollables horizontalement, résumé textuel journalier, et un paragraphe
d'explication du lien météo→tâches.

---

## Décision 1 — Nominatim (OSM) comme 2ᵉ API externe autorisée (Lot 1)

### Problème

Open-Meteo ne propose pas de reverse-geocoding. L'alternative purement locale
(extraire la ville du champ `timezone` de la réponse) est insuffisante pour
une app francophone : `"Europe/Brussels"` donne `"Brussels"` — anglais, pas
`"Bruxelles"`.

### Option retenue

**Nominatim / OpenStreetMap** : API publique gratuite, sans compte, sans clé
API. Retourne le nom de la localité la plus proche pour des coordonnées données.

Conformité avec la politique d'utilisation OSM :
- En-tête `User-Agent` identifiant l'application (`PotAGerer/1.0`).
- Au plus 1 requête par session d'ouverture de l'écran météo (aucune boucle,
  aucune agrégation de masse).
- Résultat mis en cache par le provider Riverpod (durée de vie de la session).
- Les données ne sont pas redistribuées ni stockées en base.
- `Accept-Language: fr` pour obtenir les noms de villes en français quand
  disponibles.

### Architecture

```
Domain     AbstractGeocodageService  (lib/domain/repositories/)
Infra      NominatimClient           (lib/infrastructure/api/)
           GeocodageServiceImpl      (lib/infrastructure/services/)
App        geocodageServiceProvider  (application/providers/service_providers.dart)
           nominatimClientProvider
```

La hiérarchie d'adresse utilisée : `city` > `town` > `village` >
`municipality` > `county` ; `null` si aucun champ présent (le caller affiche
un fallback).

---

## Décision 2 — Enrichissement du modèle météo (Lot 2)

### PrevisionHoraire

Ajouter :
- `weathercode` (`int`) — code WMO (0–99) de l'heure.
- `ventKmh` (`double`) — vitesse du vent à 10 m (km/h).

Variable Open-Meteo : `weather_code`, `wind_speed_10m`.

### PrevisionMeteo

Ajouter :
- `weathercode` (`int`) — code WMO dominant de la journée.

Variable Open-Meteo : `weather_code` (daily).

### InfosStation

Nouveau Value Object (`lib/domain/value_objects/infos_station.dart`) :

```
InfosStation {
  nomVille : String?   // de Nominatim (null si indisponible)
  elevation : double?  // mètres, de la réponse Open-Meteo
}
```

L'`OpenMeteoClient` capture déjà `elevation` dans le JSON de réponse (clé
`"elevation"` au niveau racine) — il suffit de ne plus l'ignorer.

### AbstractMeteoService

Ajouter :
```dart
Future<double?> obtenirElevation(Localisation loc);
```
Implémenté par `MeteoServiceImpl` comme un appel de prévision minimal (1 jour)
dont on extrait uniquement `elevation`. Pas de cache dédié (la valeur est
stable, le call est rare).

---

## Décision 3 — View model & générateur de texte (Lot 3)

### JourMeteoVue

```
JourMeteoVue {
  date            : DateTime
  tempMin/Max     : double
  precipitationsMm: double
  probabilitePluie: double   // 0..1
  weathercode     : int
  risqueGel       : bool
  risqueCanicule  : bool
  ventMaxKmh      : double
  heures          : List<PrevisionHoraire>
}
```

### MeteoDetailVue

```
MeteoDetailVue {
  disponible      : bool
  nomPotager      : String
  nomStation      : String?   // de Nominatim
  elevation       : double?   // mètres
  derniereMaj     : DateTime
  jours           : List<JourMeteoVue>
  verdictArrosage : VerdictMeteo
  resumeAujourdhui: String    // généré
  resumeDemain    : String?   // généré, null si pas de données J+1
  explicationTaches: String   // verdict → phrase explicative
}
```

### GenerateurResumeMeteo

Moteur pur (pas de Flutter, pas de Riverpod), placé dans
`lib/application/engine/generateur_resume_meteo.dart`.

Fonctions :
- `wmoVersEtatCiel(int code) → EtatCielJour` — enum :
  `ensoleille / nuageux / couvert / brouillard / pluie / neige / orage`
- `resumeJour(JourMeteoVue) → String` — phrase courte en français :
  état du ciel + temp min/max + pluie si proba ≥ 30 % ou précip > 0 +
  vent si > 20 km/h + mention gel/canicule si flag actif.
- `resumeDemain(JourMeteoVue?) → String?`
- `explicationTaches(VerdictMeteo, {double? pluieRecenteMm}) → String`

### MeteoDetailNotifier

`FutureProvider<MeteoDetailVue>` dans
`lib/application/state/meteo_detail_notifier.dart` (remplace l'actuel
`meteoHoraireProvider`) :

1. Résout le potager actif → nom + localisation.
2. Appelle `geocodageServiceProvider.obtenirNomLocalite(loc)`.
3. Appelle `meteoServiceProvider.obtenirElevation(loc)`.
4. Appelle `meteoServiceProvider.obtenirPrevisions(loc, 3)` (journalières).
5. Appelle `meteoServiceProvider.obtenirPrevisionsHoraires(loc, nbJours: 3)`.
6. Appelle `meteoServiceProvider.obtenirMeteoActuelle(loc)` → verdict.
7. Construit `MeteoDetailVue` via `GenerateurResumeMeteo`.

---

## Décision 4 — Refonte UI EcranMeteoDetail (Lot 4)

### Structure de la page

```
AppBar  ← titre dynamique (nom du potager)
┌──────────────────────────────────────────┐
│ 📍 Nom Potager                           │
│    Station : Bruxelles · 65 m            │
│    MAJ : 15:45                           │
├──────────────────────────────────────────┤
│  ← scroll horizontal →                   │
│  Carte par jour (sélectionnable) :       │
│  icône WMO · jour/date · min°/max°       │
│  💧 x % · 💨 x km/h                     │
├──────────────────────────────────────────┤
│  ← scroll horizontal →                   │
│  Colonnes ~64 px par heure :             │
│  heure · icône WMO · temp · proba pluie  │
├──────────────────────────────────────────┤
│  Résumé du [jour sélectionné]            │
│  [texte généré par GenerateurResumeMeteo]│
├──────────────────────────────────────────┤
│  Prévisions [lendemain]                  │
│  [texte generé, si J+1 disponible]       │
├──────────────────────────────────────────┤
│  🌿 Pourquoi ces tâches ?               │
│  [icône verdict + explication]           │
└──────────────────────────────────────────┘
```

### Widgets

- `_EnTeteStation` : nom potager + station + élévation + MAJ.
- `_SelecteurJours` : `ListView` horizontal, `_CarteJour` sélectionnable.
- `_DefileurHoraire` : `ListView` horizontal, `_ColonneHeure` (~64 px).
- `_ResumeJour` : bloc texte résumé aujourd'hui + lendemain.
- `_ExplicationTaches` : card avec icône verdict.

### Mapping WMO → Material Icon (substitut Phosphor)

| Codes WMO | État | Icône Material |
|---|---|---|
| 0 | Ciel dégagé | `Icons.wb_sunny` |
| 1–2 | Peu nuageux | `Icons.wb_cloudy` |
| 3 | Couvert | `Icons.cloud` |
| 45, 48 | Brouillard | `Icons.foggy` |
| 51–57 | Bruine | `Icons.grain` |
| 61–65, 80–82 | Pluie/averses | `Icons.water_drop` |
| 71–77, 85–86 | Neige | `Icons.ac_unit` |
| 95, 96, 99 | Orage | `Icons.thunderstorm` |

---

## Plan de lots

| Lot | Contenu | État |
|---|---|---|
| **1** | `AbstractGeocodageService` + `NominatimClient` + `GeocodageServiceImpl` + providers + tests unitaires | ✅ |
| **2** | `PrevisionHoraire` weathercode+vent, `PrevisionMeteo` weathercode, `InfosStation`, `obtenirElevation`, tests | ✅ |
| **3** | `JourMeteoVue`, `MeteoDetailVue`, `GenerateurResumeMeteo`, `MeteoDetailNotifier`, tests | ✅ |
| **4** | Refonte `EcranMeteoDetail` (UI), tests widget | ✅ |

---

## Conséquences

**Positif :**
- Écran météo lisible et informatif (source identifiée, icônes, résumé textuel).
- Lien explicite entre météo et tâches générées → confiance de l'utilisateur.
- Nominatim isolé derrière une abstraction domain → remplaçable sans toucher
  à l'UI ou aux use cases.
- Conformité totale avec la philosophie vie privée (coordonnées déjà arrondies
  au km dans `Localisation`, aucune donnée personnelle transmise).

**Négatif / risques :**
- Nominatim est un service public avec un quota implicite (politique d'usage).
  Si le service est surchargé, la requête peut échouer → le caller affiche
  un fallback (`null`), jamais une erreur bloquante.
- Un utilisateur en zone très rurale peut ne pas obtenir de nom de ville ;
  la hiérarchie d'adresse OSM se replie sur `county`, voire `null`.
- Ajout d'un appel réseau supplémentaire à l'ouverture de l'écran météo (mais
  il est parallélisable avec les autres appels).
