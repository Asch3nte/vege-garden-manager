# Sécurité

## Signaler une faille

Par le **signalement privé** de GitHub : onglet *Security* › *Report a
vulnerability*. Pas d'issue publique pour une faille. Projet bénévole :
réponse dès que possible.

## Versions suivies

Seule la dernière version publiée reçoit des correctifs.

## Vérifier un APK

Les versions officielles (Android, Linux, Windows) sont publiées dans les
[Releases](https://github.com/Asch3nte/vege-garden-manager/releases), avec
leurs sommes `SHA256SUMS`. Certificat de signature :

- Nom : `CN=Pot'à Gérer`
- SHA-256 : `17f2f38541624c38f1d84d8c35f346a9b267beea10a1ae8d3f657be7542a1e3e`

```sh
apksigner verify --print-certs pot-a-gerer-vX.Y.Z-android.apk
```

Un APK signé par un autre certificat ne vient pas de ce projet.

## Périmètre

Application 100 % locale : les seuls échanges réseau sont décrits dans la
[politique de confidentialité](docs/politique-confidentialite.md).
