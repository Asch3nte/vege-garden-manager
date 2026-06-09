import 'package:flutter/material.dart';

import '../../domain/enums/besoin_eau.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../domain/enums/niveau_soleil.dart';
import '../../domain/enums/type_tache.dart';
import '../../l10n/app_localizations.dart';

/// French labels for the domain enums shown across the UI.
///
/// Centralised so every screen renders the same wording and the i18n keys live
/// in one place. The label mappings are exhaustive `switch`es — adding an enum
/// value is a compile error here until its label is provided.
extension LibellesEnums on AppLocalizations {
  /// Label for a plant category.
  String categorie(CategoriePlante c) => switch (c) {
        CategoriePlante.legume => categorieLegume,
        CategoriePlante.aromatique => categorieAromatique,
        CategoriePlante.fruit => categorieFruit,
        CategoriePlante.petitFruit => categoriePetitFruit,
        CategoriePlante.fleur => categorieFleur,
        CategoriePlante.cereale => categorieCereale,
        CategoriePlante.engraisVert => categorieEngraisVert,
      };

  /// Label for a watering need.
  String besoinEau(BesoinEau e) => switch (e) {
        BesoinEau.faible => eauFaible,
        BesoinEau.modere => eauModere,
        BesoinEau.eleve => eauEleve,
      };

  /// Label for a sun exposure.
  String exposition(NiveauSoleil s) => switch (s) {
        NiveauSoleil.pleinSoleil => expositionPleinSoleil,
        NiveauSoleil.miOmbre => expositionMiOmbre,
        NiveauSoleil.ombre => expositionOmbre,
      };

  /// Label for a task type (the gesture).
  String typeTache(TypeTache t) => switch (t) {
        TypeTache.arrosage => tacheArrosage,
        TypeTache.desherbage => tacheDesherbage,
        TypeTache.paillage => tachePaillage,
        TypeTache.taille => tacheTaille,
        TypeTache.tuteurage => tacheTuteurage,
        TypeTache.fertilisation => tacheFertilisation,
        TypeTache.traitementBio => tacheTraitementBio,
        TypeTache.observation => tacheObservation,
        TypeTache.semis => tacheSemis,
        TypeTache.repiquage => tacheRepiquage,
        TypeTache.recolte => tacheRecolte,
        TypeTache.preparationSol => tachePreparationSol,
        TypeTache.installationEquipement => tacheInstallationEquipement,
        TypeTache.entretienEquipement => tacheEntretienEquipement,
        TypeTache.nettoyage => tacheNettoyage,
        TypeTache.autre => tacheAutre,
      };
}

/// Material icon standing in for the eventual Phosphor icon of a task type
/// (cf. docs/15 — Phosphor pending). Kept beside the labels so the gesture's
/// visual identity lives in one place.
IconData iconeTypeTache(TypeTache t) => switch (t) {
      TypeTache.arrosage => Icons.water_drop_outlined,
      TypeTache.desherbage => Icons.grass_outlined,
      TypeTache.paillage => Icons.layers_outlined,
      TypeTache.taille => Icons.content_cut,
      TypeTache.tuteurage => Icons.straighten,
      TypeTache.fertilisation => Icons.science_outlined,
      TypeTache.traitementBio => Icons.healing_outlined,
      TypeTache.observation => Icons.visibility_outlined,
      TypeTache.semis => Icons.grain,
      TypeTache.repiquage => Icons.spa_outlined,
      TypeTache.recolte => Icons.shopping_basket_outlined,
      TypeTache.preparationSol => Icons.agriculture_outlined,
      TypeTache.installationEquipement => Icons.build_outlined,
      TypeTache.entretienEquipement => Icons.handyman_outlined,
      TypeTache.nettoyage => Icons.cleaning_services_outlined,
      TypeTache.autre => Icons.task_alt_outlined,
    };

/// Display order of categories in the catalogue filter chips and grouped list,
/// matching the mock-up's `CAT_ORDER`.
const List<CategoriePlante> ordreCategories = [
  CategoriePlante.legume,
  CategoriePlante.aromatique,
  CategoriePlante.fruit,
  CategoriePlante.petitFruit,
  CategoriePlante.fleur,
  CategoriePlante.cereale,
  CategoriePlante.engraisVert,
];
