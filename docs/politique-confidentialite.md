# Politique de confidentialité — Pot'à Gérer

> ⚠️ **BROUILLON** à relire et retravailler par le développeur (contenu
> éditorial). Rédigé le 2026-07-17. Destiné à être consultable **hors-ligne**
> dans l'app (docs/11 §6). Ton visé : clair, sans jargon, honnête sur le peu qui
> sort de l'appareil.

## En bref

Pot'à Gérer est une application de jardinage **conçue pour respecter votre vie
privée par défaut**. Vos données de potager restent **sur votre appareil**.
Aucune inscription, aucun compte, aucune publicité, aucun traceur.

## 1. Aucun compte, aucune identité

L'application ne vous demande **jamais** de créer un compte, de fournir une
adresse e-mail, un numéro de téléphone ou une quelconque identité. Vous pouvez
l'utiliser entièrement de façon anonyme.

## 2. Vos données restent sur votre appareil

Tout ce que vous saisissez — potagers, parcelles, plantations, tâches, récoltes,
observations, préférences — est enregistré **localement**, dans une base de
données privée à l'application, sur votre appareil uniquement. **Rien de tout
cela n'est envoyé vers un serveur**, ni le nôtre, ni celui d'un tiers.

Vous pouvez à tout moment consulter ce qui est stocké (Paramètres › Données ›
« Données stockées ») et **tout effacer** (Paramètres › Données ›
Réinitialisation).

## 3. Ce qui peut quitter votre appareil (et uniquement cela)

Pour vous rendre des services de météo, l'application peut contacter des
services extérieurs **gratuits, sans compte et sans clé**. C'est le **seul**
cas où une information quitte votre appareil, et toujours de façon minimale :

- **Open-Meteo** (prévisions météo & évapotranspiration) : l'application envoie
  les **coordonnées géographiques** de votre potager pour récupérer la météo
  locale. Aucune donnée de jardin, aucun identifiant n'est transmis. Open-Meteo
  n'exige ni compte ni clé.
- **Nominatim / OpenStreetMap** (nom de ville) : si vous saisissez une position,
  l'application peut envoyer des **coordonnées** pour retrouver le nom de la
  commune correspondante, afin de l'afficher.

Ces échanges se limitent à des coordonnées et aux données météo renvoyées.
**Ils sont facultatifs** : voir les options ci-dessous.

## 4. Données sensibles et permissions

- **Localisation.** Elle sert uniquement à dériver votre climat / zone de
  rusticité et à obtenir la météo locale. Vous pouvez la saisir **à la main sur
  une carte** (aucun capteur GPS utilisé) plutôt que par géolocalisation. La
  localisation n'est jamais partagée en dehors des appels météo décrits au
  point 3.
- **Notifications.** Les rappels (arrosage, semis, récolte, alertes météo) sont
  des **notifications locales**, générées et affichées par votre appareil. Elles
  ne transitent par aucun serveur.

## 5. Vous gardez le contrôle (opt-outs)

Tout est désactivable, à tout moment, dans les Paramètres :

- couper la **récupération météo automatique** (plus aucun appel réseau
  automatique) ;
- couper la **géolocalisation** / saisir la position manuellement ;
- couper les **notifications** (globalement ou par catégorie), définir une plage
  « Ne pas déranger » ;
- **exporter** vos données dans un fichier que vous seul manipulez, et
  **réinitialiser** l'application.

## 6. Sauvegardes

Les sauvegardes sont des **fichiers créés sur votre appareil**, à votre
initiative. Vous choisissez si, quand et avec qui vous les partagez. L'app ne
les envoie nulle part automatiquement.

## 7. Pas de traceurs, pas de publicité, pas d'analytics

L'application n'intègre **aucun** outil de mesure d'audience, de suivi
comportemental ou de publicité. Nous ne collectons aucune statistique d'usage.

## 8. Enfants

L'application ne collecte aucune donnée personnelle et convient donc à tous les
publics.

## 9. Logiciel libre

Pot'à Gérer est **open source** (licence MIT). Son code est public et
vérifiable : vous (ou n'importe qui) pouvez contrôler que ces engagements sont
tenus.

## 10. Modifications

Cette politique pourra évoluer avec l'application. La version applicable est
toujours celle **embarquée dans la version que vous utilisez**, consultable
hors-ligne.

## 11. Contact

Questions, remarques ou signalement : voir la page « À propos » (lien du dépôt
GitHub du projet).
