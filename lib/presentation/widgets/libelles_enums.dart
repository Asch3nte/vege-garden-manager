import 'package:flutter/material.dart';

import '../../app/theme/couleurs_app.dart';
import '../../application/state/meteo_accueil_vue.dart';
import '../../domain/enums/besoin_eau.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../domain/enums/langue.dart';
import '../../domain/enums/methode_mise_en_place.dart';
import '../../domain/enums/mode_geolocalisation.dart';
import '../../domain/enums/niveau_experience.dart';
import '../../domain/enums/niveau_soleil.dart';
import '../../domain/enums/sens_swipe.dart';
import '../../domain/enums/systeme_unites.dart';
import '../../domain/enums/theme_app.dart' as prefs_theme;
import '../../domain/enums/type_climat.dart';
import '../../domain/enums/type_emplacement.dart';
import '../../domain/enums/type_parcelle.dart';
import '../../domain/enums/type_tache.dart';
import '../../domain/enums/zone_rusticite.dart';
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

  /// Label for the interface language.
  String langue(Langue l) => switch (l) {
        Langue.auto => langueAuto,
        Langue.fr => langueFr,
        Langue.en => langueEn,
      };

  /// Label for a theme choice.
  String theme(prefs_theme.ThemeApp t) => switch (t) {
        prefs_theme.ThemeApp.auto => themeAuto,
        prefs_theme.ThemeApp.clair => themeClair,
        prefs_theme.ThemeApp.sombre => themeSombre,
      };

  /// Label for the unit system.
  String unites(SystemeUnites u) => switch (u) {
        SystemeUnites.metrique => unitesMetrique,
        SystemeUnites.imperial => unitesImperial,
      };

  /// Label for the list-swipe direction.
  String sensSwipe(SensSwipe s) => switch (s) {
        SensSwipe.standard => swipeStandard,
        SensSwipe.inverse => swipeInverse,
      };

  /// Label for the experience level.
  String niveauExperience(NiveauExperience n) => switch (n) {
        NiveauExperience.debutant => niveauDebutant,
        NiveauExperience.intermediaire => niveauIntermediaire,
        NiveauExperience.expert => niveauExpert,
      };

  /// Short label for a geolocation mode (the chip value).
  String geolocLabel(ModeGeolocalisation m) => switch (m) {
        ModeGeolocalisation.desactivee => geolocLabelOff,
        ModeGeolocalisation.manuelle => geolocLabelManuelle,
        ModeGeolocalisation.gps => geolocLabelGps,
      };

  /// Long description for a geolocation mode (the row subtitle).
  String geolocDescription(ModeGeolocalisation m) => switch (m) {
        ModeGeolocalisation.desactivee => geolocOff,
        ModeGeolocalisation.manuelle => geolocManuelle,
        ModeGeolocalisation.gps => geolocGps,
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

  /// Label for a garden location type.
  String emplacement(TypeEmplacement e) => switch (e) {
        TypeEmplacement.jardin => emplacementJardin,
        TypeEmplacement.balcon => emplacementBalcon,
        TypeEmplacement.terrasse => emplacementTerrasse,
        TypeEmplacement.toit => emplacementToit,
        TypeEmplacement.cour => emplacementCour,
        TypeEmplacement.interieur => emplacementInterieur,
        TypeEmplacement.autre => emplacementAutre,
      };

  /// Label for a climate type.
  String climat(TypeClimat c) => switch (c) {
        TypeClimat.tropical => climatTropical,
        TypeClimat.subtropical => climatSubtropical,
        TypeClimat.aride => climatAride,
        TypeClimat.semiAride => climatSemiAride,
        TypeClimat.mediterraneen => climatMediterraneen,
        TypeClimat.oceanique => climatOceanique,
        TypeClimat.continental => climatContinental,
        TypeClimat.montagnard => climatMontagnard,
        TypeClimat.polaire => climatPolaire,
      };

  /// Label for a hardiness zone (USDA), e.g. "Zone 8".
  String rusticite(ZoneRusticite z) =>
      rusticiteZone(int.parse(z.name.replaceAll('zone', '')));

  /// Label for a parcelle (zone) type.
  String typeParcelle(TypeParcelle t) => switch (t) {
        TypeParcelle.pleineTerre => typeParcellePleineTerre,
        TypeParcelle.bacSureleve => typeParcelleBacSureleve,
        TypeParcelle.jardiniere => typeParcelleJardiniere,
        TypeParcelle.pot => typeParcellePot,
        TypeParcelle.serre => typeParcelleServe,
        TypeParcelle.butte => typeParcelleButte,
        TypeParcelle.autre => typeParcelleAutre,
      };

  /// Label for the home weather watering verdict.
  String verdictMeteo(VerdictMeteo v) => switch (v) {
        VerdictMeteo.pluieAVenir => meteoVerdictPluie,
        VerdictMeteo.solHumide => meteoVerdictSolHumide,
        VerdictMeteo.arroserConseille => meteoVerdictArroser,
        VerdictMeteo.clement => meteoVerdictClement,
      };

  /// Label for a planting method.
  String methode(MethodeMiseEnPlace m) => switch (m) {
        MethodeMiseEnPlace.semisDirect => methodeSemisDirect,
        MethodeMiseEnPlace.semisInterieur => methodeSemisInterieur,
        MethodeMiseEnPlace.repiquage => methodeRepiquage,
        MethodeMiseEnPlace.plantAchete => methodePlantAchete,
        MethodeMiseEnPlace.bouture => methodeBouture,
        MethodeMiseEnPlace.division => methodeDivision,
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

/// Decorative dot colour for a task type (calendar month grid), echoing the
/// per-gesture colours of the `calendrier.jsx` mock-up. Uses the static
/// decorative palette so it is theme-independent.
Color couleurTypeTache(TypeTache t) => switch (t) {
      TypeTache.arrosage => CouleursApp.accentInfoClair,
      TypeTache.semis => CouleursApp.decoVertMoyen,
      TypeTache.repiquage => CouleursApp.accentPrimaireClair,
      TypeTache.taille => CouleursApp.decoOcre,
      TypeTache.tuteurage => CouleursApp.decoTerre,
      TypeTache.observation => CouleursApp.attentionClair,
      TypeTache.recolte => CouleursApp.decoAubergine,
      TypeTache.desherbage => CouleursApp.decoVertProfond,
      TypeTache.paillage => CouleursApp.decoTerre,
      TypeTache.fertilisation => CouleursApp.decoVertMoyen,
      TypeTache.traitementBio => CouleursApp.succesClair,
      TypeTache.preparationSol => CouleursApp.decoTerre,
      TypeTache.installationEquipement => CouleursApp.texteSecondaireClair,
      TypeTache.entretienEquipement => CouleursApp.texteSecondaireClair,
      TypeTache.nettoyage => CouleursApp.accentInfoClair,
      TypeTache.autre => CouleursApp.texteSecondaireClair,
    };

/// Material icon for a weather watering verdict (home card).
IconData iconeVerdictMeteo(VerdictMeteo v) => switch (v) {
      VerdictMeteo.pluieAVenir => Icons.umbrella_outlined,
      VerdictMeteo.solHumide => Icons.water_drop_outlined,
      VerdictMeteo.arroserConseille => Icons.wb_sunny_outlined,
      VerdictMeteo.clement => Icons.cloud_outlined,
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
