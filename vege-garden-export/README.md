# Mon Potager — Export design (5 panneaux verrouillés)

> ## 📦 Archive de référence — ne pas développer ici
>
> Ce dossier est **archivé dans `main` le 2026-08-16** depuis la branche
> `feat/catalogue-reseau`, pour ne pas perdre les maquettes d'origine lors du
> nettoyage des branches. Il est **gelé** : aucune évolution de l'application ne
> passe par lui.
>
> - **Aucun fichier n'est transférable tel quel** dans l'app : chaque écran est
>   **réimplémenté en Flutter** d'après la maquette (CLAUDE.md § Prochaine action).
> - Les **tokens couleur** en ont déjà été remontés dans
>   [`docs/08-design-system.md`](../docs/08-design-system.md) §2, qui reste la
>   **source de vérité** du design system. En cas d'écart entre ces maquettes et
>   `docs/08`, c'est `docs/08` qui fait foi.
> - Rien dans le build ne dépend de ce dossier : il n'est déclaré ni dans
>   `pubspec.yaml` ni comme asset. Il peut être consulté ou supprimé sans effet
>   sur l'application.
> - Les maquettes utilisent **Phosphor Icons** via CDN ; côté Flutter le package
>   est cassé sur Flutter 3.44.1 et Material sert de substitut (`docs/08` §7).

5 maquettes haute-fidélité React, autonomes. Chaque panneau est un fichier HTML
qui charge React + Babel via CDN, puis ses propres modules CSS/JSX en local.
Aucune image locale — tout est dessiné en CSS ou via icônes Phosphor (CDN).

## Lancer en local
Les fichiers chargent du JSX compilé par Babel dans le navigateur : il faut un
serveur HTTP (l'ouverture en `file://` bloque le chargement des `.jsx`).

```bash
# depuis ce dossier
npx serve .
# ou
python3 -m http.server 8000
```
Puis ouvrir http://localhost:8000/Accueil.html (extension VS Code « Live Server » marche aussi).

## Carte des dépendances

| Panneau           | CSS                                                     | JSX                                                      |
|-------------------|---------------------------------------------------------|----------------------------------------------------------|
| Accueil.html      | bg-directions, parcelles-plantes, accueil-hifi          | aromates-grimpantes, tweaks-panel, accueil-final         |
| Potager.html      | bg-directions, potager                                  | design-canvas, tweaks-panel, potager                     |
| Calendrier.html   | bg-directions, calendrier                               | tweaks-panel, calendrier                                 |
| Catalogue.html    | bg-directions, catalogue                                | tweaks-panel, catalogue-data, catalogue                  |
| Paramètres.html   | bg-directions, parcelles-plantes, parametres            | aromates-grimpantes, tweaks-panel, parametres            |

## Partagés
- **bg-directions.css** — fond / variables de couleur communs aux 5 panneaux
- **tweaks-panel.jsx** — panneau de réglages (tweaks) commun
- **Polices** : Manrope + Inter (Google Fonts), icônes Phosphor — chargées via CDN

## 📐 Spec pour le portage Flutter/Dart → dossier `spec/`
Les maquettes HTML/React **ne se convertissent pas** en Flutter : c'est une réécriture.
Le dossier `spec/` est le cahier des charges à donner à Claude Code pour qu'il code l'app
Flutter fidèlement, sans avoir à rétro-analyser le HTML :

- `spec/00-design-system.md` — tokens (couleurs, type, espacement, ombres) → `ThemeData` + `tokens.dart`, coquille commune, modèles partagés
- `spec/01-accueil.md` · `02-potager.md` · `03-calendrier.md` · `04-catalogue.md` · `05-parametres.md` — un écran par fichier : rôle, état, arborescence de widgets, **données seed**, interactions à câbler, mapping Flutter

> Les données (zones, plantes, calendrier, prefs) sont **codées en dur** dans les `.jsx` —
> reprends-les telles quelles comme seed, puis branche une vraie persistance locale.

## Notes pour le câblage des fonctions
- Chaque JSX expose ses composants sur `window` (scope Babel séparé par `<script>`).
- L'état est local à chaque panneau (pas encore de backend / persistance partagée).
- Les `catalogue-data.jsx` contient les données du catalogue (point d'entrée à brancher sur une vraie source de données).
