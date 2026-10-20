---
name: contexte
description: Résumé complet et rechargeable de l'état du projet.
disable-model-invocation: true
---

Produire un résumé autonome, rechargeable dans une session neuve :
- étape du projet et dernier chantier livré (`git log --oneline -15`) ;
- branches et PR ouvertes (`gh pr list`) ;
- prochains lots (RESTE_A_FAIRE.md, FICHES A CREER.md) ;
- décisions en attente du dev.

Concis, impersonnel, en puces.
