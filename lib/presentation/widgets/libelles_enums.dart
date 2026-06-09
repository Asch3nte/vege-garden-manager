import '../../domain/enums/besoin_eau.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../domain/enums/niveau_soleil.dart';
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
}

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
