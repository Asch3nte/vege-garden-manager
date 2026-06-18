# ADR-0015 — Arrosage intelligent & facteur thermique (moteur + UI par plantation)

- **Statut** : Accepté — lots 1–5 livrés
- **Date** : 2026-06-18
- **Contexte** : en conditions de canicule (34–37 °C sur plusieurs jours), le
  moteur d'arrosage existant (`BilanArrosage`) sous-estime le besoin hydrique
  des plantes. Trois lacunes :

  1. **Aucun facteur thermique.** `BilanArrosage.calculer()` n'a pas de
     paramètre de température. L'évapotranspiration réelle double environ entre
     20 °C et 35 °C ; sans ce facteur, une plante `besoinEau.modere` reçoit le
     verdict `bientot` même à 36 °C, alors qu'elle est en stress hydrique.
  2. **Conseil invisible par plantation.** `CalculerBesoinArrosage` (use case
     complet) n'est pas surfacé dans l'UI : l'utilisateur ne peut pas voir
     quelle plante a besoin d'eau maintenant versus laquelle peut attendre la
     pluie du lendemain.
  3. **Probabilité de pluie binaire.** Le seuil `probabilitePluie ≥ 60 %`
     est un tout-ou-rien : une probabilité de 65 % sur 4 mm ne justifie pas
     le même report qu'une probabilité de 90 % sur 15 mm.

  **Philosophie du projet** : favoriser l'autonomie des plantes (doc 02 §6).
  L'application doit aider l'utilisateur à atteindre l'équilibre entre
  arroser suffisamment (santé des plantes) et économiser l'eau (encourager
  l'enracinement profond, respecter les ressources).

---

## Décision 1 — Facteur thermique dans `BilanArrosage` (Lot 1)

### Modèle retenu

L'indice de besoin en eau devient :

```
indice = base(BesoinEau) × factTexture × factTechniques × factEquipement × factTemperature
```

Le `facteurTemperature(tempMax)` est une fonction **statique pure** à paliers,
calée sur le triplet `(25 °C, 30 °C, 35 °C)` :

| tempMax        | facteur | Justification agronomique                          |
|----------------|---------|-----------------------------------------------------|
| < 25 °C        | × 1,0   | Conditions fraîches, ET₀ normale                   |
| 25–29 °C       | × 1,2   | Chaleur estivale modérée                           |
| 30–34 °C       | × 1,4   | Chaleur importante, évapotranspiration sensiblement |
|                |         | supérieure à la normale                            |
| ≥ 35 °C        | × 1,7   | Canicule, ET₀ ≈ double du niveau de référence      |

Le seuil 35 °C réutilise `SeuilsMeteo.caniculeC` (source unique).

**Règle d'absence** : si `tempMax` est `null` (position inconnue ou météo
hors ligne), le facteur vaut 1,0 — le moteur reste conservatif, pas
silencieusement erroné.

**Effet sur les scenarios existants :**
- 36 °C, `besoinEau.modere` (base 0,65) → 0,65 × 1,7 = 1,105, clampé à 1,0
  → `arroserMaintenant` (avant : `bientot`).
- 36 °C, `besoinEau.faible` (base 0,35), paillage (× 0,7), oya (× 0,4)
  → 0,35 × 0,7 × 0,4 × 1,7 ≈ 0,167 → `pasNecessaire`
  (plante robuste bien équipée).
- 26 °C, `besoinEau.eleve` (base 1,0) → 1,0 × 1,2 = 1,2 → clampé → `arroserMaintenant`
  (inchangé : déjà au maximum sans le facteur).

### Source de tempMax

`CalculerBesoinArrosage` extrait `tempMax` du **premier jour prévu**
(`TypeReleveMeteo.prevu`) dans la fenêtre déjà récupérée (aucun appel réseau
supplémentaire). Quand la fenêtre ne contient aucune prévision future
(ex. hors ligne), `tempMax` reste `null`.

---

## Décision 2 — Conseil d'arrosage par plantation en UI (Lot 2)

### Provider

`conseilArrosagePlantationProvider(plantationId)` — `AutoDisposeFutureProvider.family` :

1. Récupère la `Plantation` via `plantationRepositoryProvider.obtenirParId()`.
2. Récupère la localisation via `potagerRepositoryProvider.obtenirPotagerActif()`.
3. Appelle `CalculerBesoinArrosage.executer()`.
4. Retourne `null` si plantation introuvable, potager inactif ou catalogue absent.

Le provider est auto-dispose : chaque ligne de culture l'instancie
indépendamment, il est libéré quand la ligne quitte l'arbre.

### Rendu dans `_LigneCulture`

Une ligne compacte (icône `sm` + `bodySmall`) s'ajoute **sous la barre de
progression** du stade, suivant le même pattern que la ligne `prochaineTache`.
Elle n'apparaît que pour les états actionnables :

| Urgence / flag        | Icône                     | Couleur          | Libellé |
|-----------------------|---------------------------|------------------|---------|
| `arroserMaintenant`   | `Icons.water_drop`        | `error`          | « Arroser » |
| `bientot`             | `Icons.water_drop_outlined`| `tertiary`       | « Arroser dans N j » |
| `pasNecessaire` + `pluiePrevue` | `Icons.water` | `primary`        | « Pluie à venir » |
| `pasNecessaire` seul  | —                         | —                | (rien — pas de bruit visuel) |

L'état de chargement et les erreurs sont silencieux (`.value` = `null`) : la
ligne de culture reste affichée normalement, sans spinners.

---

## Décision 3 — Pondération continue de la probabilité de pluie (Lot 3 — à venir)

Remplacement du seuil binaire `probabilitePluie ≥ 0,60` par un **score pondéré
pluie** dans `BilanArrosage` :

```
scorePluie = pluiePrevueMm × probabilitePluie
```

Seuil de report : `scorePluie ≥ 6,0` (≈ 10 mm × 60 % ou 8 mm × 75 %).
Les valeurs actuelles (seuil binaire 60 %, seuil mm 10) deviennent alors des
cas particuliers de cette formule.

---

## Décision 4 — Sensibilité thermique & tolérance sécheresse par plante (Lot 4 — V1.1)

Requiert des champs YAML supplémentaires (doc 13 §2.1) :

- `temperature_max_tolerance` (°C) : alerte canicule ciblée par plante.
- `tolerance_secheresse` (`faible|moyenne|forte`) : affine `BilanArrosage`
  (plantes résistantes = facteur base réduit).
- `temperature_min_survie` (déjà dans le schéma, **non mappé**) :
  à mapper sur `BesoinsCulture` pour les alertes gel ciblées.

Impliqué : `fiche_plante_schema.yaml`, parser, validator, mapper,
`BesoinsCulture`, `EvaluateurAlertesMeteo` (filtre par plante).

---

## Décision 5 — Évapotranspiration Open-Meteo (Lot 5 — V1.1)

Remplace le facteur heuristique (Décision 1) par la valeur réelle
`et0_fao_evapotranspiration` fournie gratuitement par Open-Meteo.

Impliqué : `DonneesMeteo`, `PrevisionMeteo`, `OpenMeteoClient`
(`_dailyVariables`), `MeteoServiceImpl`, `BilanArrosage`
(paramètre `et0` prioritaire sur `tempMax`).

---

## Plan de lots

| Lot | Périmètre | État |
|-----|-----------|------|
| **1** | Facteur thermique dans `BilanArrosage` + extraction `tempMax` dans `CalculerBesoinArrosage` | ✅ livré |
| **2** | Provider `conseilArrosagePlantationProvider` + badge arrosage dans `_LigneCulture` | ✅ livré |
| **3** | Pondération continue probabilité×mm pluie | ✅ livré |
| **4** | Sensibilité thermique/sécheresse par plante (YAML V1.1) | ✅ livré |
| **5** | ET₀ Open-Meteo en remplacement du heuristique | ✅ livré |

---

## Conséquences

### Positives
- Un potager avec 34 °C prévu est automatiquement traité différemment d'un
  potager à 22 °C — aucune action de l'utilisateur requise.
- L'utilisateur voit plante par plante ce qui a besoin d'eau vs. ce qui peut
  attendre la pluie — équilibre santé/économie d'eau visible directement.
- Les futurs lots (ET₀, sensibilité par plante) enrichissent le même calcul
  sans casser l'existant (paramètres optionnels, backward-compatible).

### Négatives / vigilances
- Les facteurs de température (1,0 / 1,2 / 1,4 / 1,7) sont des **heuristiques
  calibrables** : à ajuster si les retours terrain montrent des sur/sous-
  estimations. Ils sont centralisés dans `BilanArrosage` (constantes nommées).
- Le `facteurTemperature` peut porter l'indice au-delà de 1,0 ; le `clamp(0,1)`
  existant absorbe silencieusement ce dépassement — correct car l'urgence
  maximum reste `arroserMaintenant`.
- Lot 2 ajoute N appels à `CalculerBesoinArrosage` par zone (un par culture) ;
  chacun fait un appel météo (caché par `MeteoServiceImpl`). Le cache 3 h
  existant absorbe les requêtes répétées sans coût réseau.
