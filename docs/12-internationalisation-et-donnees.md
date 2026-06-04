# 12 — Internationalisation, données & contraintes non fonctionnelles

> Source : CAHIER §1.8, §1.9, §1.10.

## 1. Internationalisation (i18n)

L'UI est **en français uniquement en V1**, mais l'architecture est prête pour le
multilingue dès le départ :

- **Tous les textes UI** centralisés dans des fichiers de ressources dédiés
  (ARB via `intl` / `flutter_localizations`).
- **Aucun texte en dur** dans le code applicatif.
- Clés de traduction explicites et hiérarchisées.
- Pour ajouter une langue en V2 : ajouter un fichier `en.arb`, `es.arb`, etc.

La **base de connaissances** suit le même principe : données structurées séparées
du contenu textuel, traduisible indépendamment via la section `i18n` des fiches
(cf. [07-base-de-connaissances-yaml.md](07-base-de-connaissances-yaml.md)).
`fr` est obligatoire dans chaque fiche.

> **Séparation des deux mondes** : les **ARB** (`l10n/`) ne portent que le
> **texte d'interface** (chrome de l'UI). Les **textes des fiches plantes** (descriptions,
> conseils, conservation) sont **traduits inline dans le YAML** — jamais dans les ARB.
> En V1 l'UI est FR-only ; la langue `en` est masquée dans les réglages (pas de `en.arb`
> livré), tandis que les fiches peuvent déjà contenir leur bloc `en`.

## 2. Données & stockage

- **100% local** sur l'appareil.
- Base de données locale : **SQLite via drift**.
- Base de connaissances : **fichiers YAML embarqués**, séparés du code.
- Synchronisation entre appareils : **réseau local WiFi uniquement** (Sockets /
  mDNS), aucun cloud, opt-out, désactivée par défaut.
- Fonctionne **hors ligne** (sauf la météo).
- **Aucune création de compte, aucune télémétrie.**

### Souveraineté des données
- Export JSON (intégral) / CSV (par table), import/restauration (modes
  remplacer / fusionner), suppression totale (double confirmation).
- Destination des exports via **share sheet natif** (jamais de cloud automatique).
- Soft delete partout : aucune donnée détruite physiquement sans action explicite.

## 3. Contraintes non fonctionnelles

- Démarrage rapide, **léger en ressources**.
- **Aucune dépendance externe non validée** (contrainte absolue n°6).
- **Sécurité by design**, pas en patch.
- Open source, hébergé sur GitHub, **licence MIT**.
- Code documenté (dartdoc), **POO stricte**, tests unitaires en parallèle du code.
- Accessibilité : WCAG AA minimum (cf. [08-design-system.md](08-design-system.md)).

## 4. Vie privée — synthèse des garanties

| Garantie | Mise en œuvre |
|-----------------------------------|-----------------------------------------------------------------------------------------|
| Aucune donnée sur serveur externe | Stockage 100% local, sync LAN uniquement |
| Aucune identité requise | Pas de compte, pseudo communautaire anonyme (V2) |
| Géolocalisation arrondie | Coordonnées à ~1 km (2 décimales), aucune adresse précise |
| Tout opt-out possible | Géoloc, météo, notifications, sync, communauté (cf. [11](11-parametres-et-opt-outs.md)) |
| Transparence | Visualisation des données stockées + journal des accès sensibles |
| Pas de télémétrie | Aucune collecte analytique |
