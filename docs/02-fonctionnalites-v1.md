# 02 — Fonctionnalités détaillées (V1)

> Source : CAHIER §1.7. Décrit le *comportement attendu* des fonctionnalités.

## 1. Gestion du potager

- Créer, modifier, supprimer des **zones** (parcelle, bac, jardinière, serre…).
- Chaque zone : nom, dimensions, type de sol (optionnel), exposition, type de contenant.
- Ajouter des cultures dans une zone avec leurs dates.
- **Historique des cultures par zone** (alimente la rotation).
- Support **multi-potagers** dès le MVP (ex. jardin maison + balcon + parcelle familiale).

## 2. Recommandations intelligentes

Basées sur le croisement de :

- Climat local (déduit de la localisation).
- Météo actuelle et prévisions (Open-Meteo).
- Période de l'année (et calendrier lunaire en V2, opt-out).
- Place disponible par zone.
- Historique des cultures (rotation).
- Associations et compagnonnage.
- Niveau de l'utilisateur.

Chaque recommandation répond à **3 questions** :

- **Quoi** → quelle plante.
- **Pourquoi** → explication pédagogique.
- **Comment** → lien vers la fiche de culture.

## 3. Météo

- Source : **Open-Meteo uniquement** (sans clé API, sans compte).
- Données : température, précipitations, gel, vent.
- Alertes contextuelles : gel imminent, canicule, forte pluie → impact sur les
  cultures en place.
- **Opt-out complet possible** (mode dégradé sans météo automatique).

## 4. Contenu éducatif

- Intégré dans le flux de l'app, **pas dans un wiki séparé**.
- Tips permaculture contextuels (paillage, compost, purins…).
- Explications pédagogiques dans chaque recommandation et chaque fiche.

## 5. Calendrier

- Calendrier personnalisé généré selon les cultures en place.
- Visualisation du **cycle de vie** de chaque culture sur une frise (semis → récolte).

## 6. Arrosage intelligent

**Philosophie** : favoriser l'autonomie des plantes. Arroser seulement quand
c'est nécessaire — une plante qui cherche l'eau s'enracine mieux.

L'alerte d'arrosage croise :

| Entrée                           | Source                                |
|----------------------------------|---------------------------------------|
| Besoins en eau de la plante      | Base de connaissances (fiche YAML)    |
| Stade de croissance              | Date de plantation + cycle de vie     |
| Précipitations récentes (3–5 j)  | Open-Meteo                            |
| Précipitations prévues (3 j)     | Open-Meteo                            |
| Température / évapotranspiration | Open-Meteo                            |
| Type de sol (rétention d'eau)    | Données de la zone                    |
| Paillage en place                | Déclaré par l'utilisateur (équipement)|

**Résultat** : messages contextuels du type *« Vos tomates auront besoin d'eau
dans 2 jours, aucune pluie prévue »* ou *« Pluie annoncée demain, pas besoin
d'arroser »*.

## 7. Alertes et rappels

| Alerte              | Déclencheur                                   |
|---------------------|-----------------------------------------------|
| Semis intérieur     | Calendrier plante + zone climatique           |
| Repiquage           | Date de semis + croissance + dernier gel      |
| Plantation directe  | Période + météo favorable                     |
| Gel imminent        | Open-Meteo → protéger les cultures sensibles  |
| Récolte             | Date estimée + conditions                     |
| Visite du potager   | Rappel configurable                           |
| Rotation            | Fin de culture → suggestion pour la suite     |

> Toutes les notifications sont **locales** et **désactivables individuellement**.
> Modèle de données associé : tables `rappels` et `taches`
> (voir [06-modele-de-donnees-sqlite.md](06-modele-de-donnees-sqlite.md)).
> Distinction clé : un **Rappel** est une *règle de planification* (récurrente),
> une **Tâche** est une *occurrence unitaire*.

## 8. Post-récolte

- Suggestions de **conservation** (frais, conserves, lactofermentation, séchage…).
- Suggestions d'**utilisations culinaires** / recettes.
- Données portées par les fiches plantes YAML (section `conservation` et
  `utilisations_culinaires_i18n`).

## 9. Export / sauvegarde

- Export **JSON** (intégral, format pivot) ou **CSV** (par table).
- Import / restauration depuis un export antérieur (modes : remplacer / fusionner).
- Réinitialisation complète avec double confirmation.

> Parcours détaillés (onboarding, création potager, sauvegarde, opt-out) :
> [10-parcours-utilisateur.md](10-parcours-utilisateur.md).
