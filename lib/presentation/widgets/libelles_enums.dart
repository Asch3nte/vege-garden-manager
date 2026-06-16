import 'package:flutter/material.dart';

import '../../app/theme/couleurs_app.dart';
import '../../application/state/meteo_accueil_vue.dart';
import '../../domain/enums/besoin_eau.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../domain/enums/destination_recolte.dart';
import '../../domain/enums/famille_effet_association.dart';
import '../../domain/enums/ph_sol.dart';
import '../../domain/enums/poids_association.dart';
import '../../domain/enums/technique_sol.dart';
import '../../domain/enums/texture_sol.dart';
import '../../domain/enums/unite_quantite.dart';
import '../../domain/enums/langue.dart';
import '../../domain/enums/methode_mise_en_place.dart';
import '../../domain/enums/mode_geolocalisation.dart';
import '../../domain/enums/niveau_confiance.dart';
import '../../domain/enums/niveau_experience.dart';
import '../../domain/enums/niveau_soleil.dart';
import '../../domain/enums/sens_swipe.dart';
import '../../domain/enums/stade_croissance.dart';
import '../../domain/enums/systeme_unites.dart';
import '../../domain/enums/theme_app.dart' as prefs_theme;
import '../../domain/enums/type_benefice_association.dart';
import '../../domain/enums/type_climat.dart';
import '../../domain/enums/type_conflit_association.dart';
import '../../domain/enums/type_emplacement.dart';
import '../../domain/enums/type_observation.dart';
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

  /// One-line description of what an experience level unlocks (ADR-0009).
  String niveauDescription(NiveauExperience n) => switch (n) {
        NiveauExperience.debutant => niveauDebutantDesc,
        NiveauExperience.intermediaire => niveauIntermediaireDesc,
        NiveauExperience.expert => niveauExpertDesc,
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

  /// Short helper describing a climate type (shown under each dropdown option).
  String climatDescription(TypeClimat c) => switch (c) {
        TypeClimat.tropical => climatTropicalDesc,
        TypeClimat.subtropical => climatSubtropicalDesc,
        TypeClimat.aride => climatArideDesc,
        TypeClimat.semiAride => climatSemiArideDesc,
        TypeClimat.mediterraneen => climatMediterraneenDesc,
        TypeClimat.oceanique => climatOceaniqueDesc,
        TypeClimat.continental => climatContinentalDesc,
        TypeClimat.montagnard => climatMontagnardDesc,
        TypeClimat.polaire => climatPolaireDesc,
      };

  /// Label for a hardiness zone (USDA), e.g. "Zone 8".
  String rusticite(ZoneRusticite z) =>
      rusticiteZone(int.parse(z.name.replaceAll('zone', '')));

  /// Short helper for a hardiness zone: its USDA average annual minimum
  /// temperature range, in °C (shown under each dropdown option).
  String rusticiteDescription(ZoneRusticite z) {
    final n = int.parse(z.name.replaceAll('zone', ''));
    final (int min, int max) = switch (n) {
      1 => (-51, -45),
      2 => (-45, -40),
      3 => (-40, -34),
      4 => (-34, -29),
      5 => (-29, -23),
      6 => (-23, -18),
      7 => (-18, -12),
      8 => (-12, -7),
      9 => (-7, -1),
      10 => (-1, 4),
      11 => (4, 10),
      12 => (10, 16),
      _ => (16, 21), // zone 13
    };
    return rusticiteZoneDesc(min, max);
  }

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

  /// Label for a soil texture (ADR-0009 — expert).
  String textureSol(TextureSol t) => switch (t) {
        TextureSol.argileux => textureArgileux,
        TextureSol.sableux => textureSableux,
        TextureSol.limoneux => textureLimoneux,
        TextureSol.calcaire => textureCalcaire,
        TextureSol.humifere => textureHumifere,
        TextureSol.tourbeux => textureTourbeux,
        TextureSol.caillouteux => textureCaillouteux,
      };

  /// Label for a soil pH (ADR-0009 — expert).
  String phSol(PhSol p) => switch (p) {
        PhSol.acide => phAcide,
        PhSol.neutre => phNeutre,
        PhSol.alcalin => phAlcalin,
      };

  /// Label for a soil technique (ADR-0009 — intermédiaire+).
  String techniqueSol(TechniqueSol t) => switch (t) {
        TechniqueSol.butteLasagne => techButteLasagne,
        TechniqueSol.hugelkultur => techHugelkultur,
        TechniqueSol.butteRonde => techButteRonde,
        TechniqueSol.buttePermanente => techButtePermanente,
        TechniqueSol.paillage => techPaillage,
        TechniqueSol.brf => techBrf,
        TechniqueSol.mulchVivant => techMulchVivant,
        TechniqueSol.engraisVertCouvert => techEngraisVertCouvert,
        TechniqueSol.paillageMineral => techPaillageMineral,
        TechniqueSol.carton => techCarton,
        TechniqueSol.noDig => techNoDig,
        TechniqueSol.grelinette => techGrelinette,
        TechniqueSol.mulchDeFoin => techMulchDeFoin,
        TechniqueSol.compostageSurface => techCompostageSurface,
        TechniqueSol.compostEnTrou => techCompostEnTrou,
        TechniqueSol.mycorhization => techMycorhization,
        TechniqueSol.bokashi => techBokashi,
        TechniqueSol.swales => techSwales,
        TechniqueSol.keylineDesign => techKeylineDesign,
      };

  /// Label for the home weather watering verdict.
  String verdictMeteo(VerdictMeteo v) => switch (v) {
        VerdictMeteo.pluieAVenir => meteoVerdictPluie,
        VerdictMeteo.solHumide => meteoVerdictSolHumide,
        VerdictMeteo.arroserConseille => meteoVerdictArroser,
        VerdictMeteo.clement => meteoVerdictClement,
      };

  /// Symbol for a quantity unit.
  String unite(UniteQuantite u) => switch (u) {
        UniteQuantite.g => uniteG,
        UniteQuantite.kg => uniteKg,
        UniteQuantite.piece => unitePiece,
        UniteQuantite.botte => uniteBotte,
        UniteQuantite.litre => uniteLitre,
        UniteQuantite.ml => uniteMl,
      };

  /// Label for an observation type.
  String typeObservation(TypeObservation t) => switch (t) {
        TypeObservation.maladie => obsMaladie,
        TypeObservation.ravageur => obsRavageur,
        TypeObservation.carence => obsCarence,
        TypeObservation.meteo => obsMeteo,
        TypeObservation.croissance => obsCroissance,
        TypeObservation.floraison => obsFloraison,
        TypeObservation.fructification => obsFructification,
        TypeObservation.general => obsGeneral,
        TypeObservation.autre => obsAutre,
      };

  /// Label for a harvest destination.
  String destinationRecolte(DestinationRecolte d) => switch (d) {
        DestinationRecolte.consommationFraiche => destinationFraiche,
        DestinationRecolte.conservation => destinationConservation,
        DestinationRecolte.don => destinationDon,
        DestinationRecolte.semences => destinationSemences,
        DestinationRecolte.compost => destinationCompost,
        DestinationRecolte.autre => destinationAutre,
      };

  /// Label for a growth stage.
  String libelleStade(StadeCroissance s) => switch (s) {
        StadeCroissance.levee => stadeLevee,
        StadeCroissance.croissance => stadeCroissance,
        StadeCroissance.maturation => stadeMaturation,
        StadeCroissance.recolte => stadeRecolte,
      };

  /// Label for a beneficial-association mechanism (ADR-0010).
  String mecanismeBenefice(TypeBeneficeAssociation m) => switch (m) {
        TypeBeneficeAssociation.tuteurStructurel => assocMecaTuteurStructurel,
        TypeBeneficeAssociation.etagementLumiere => assocMecaEtagementLumiere,
        TypeBeneficeAssociation.repulsionRavageur => assocMecaRepulsionRavageur,
        TypeBeneficeAssociation.brouillageOlfactif =>
          assocMecaBrouillageOlfactif,
        TypeBeneficeAssociation.attractionPollinisateurs =>
          assocMecaAttractionPollinisateurs,
        TypeBeneficeAssociation.plantePiege => assocMecaPlantePiege,
        TypeBeneficeAssociation.fixationAzote => assocMecaFixationAzote,
        TypeBeneficeAssociation.couvreSol => assocMecaCouvreSol,
        TypeBeneficeAssociation.briseVent => assocMecaBriseVent,
        TypeBeneficeAssociation.successionTemporelle =>
          assocMecaSuccessionTemporelle,
      };

  /// Label for a conflicting-association mechanism (ADR-0010).
  String mecanismeConflit(TypeConflitAssociation m) => switch (m) {
        TypeConflitAssociation.memeFamilleRavageurs =>
          assocMecaMemeFamilleRavageurs,
        TypeConflitAssociation.competitionLumiere => assocMecaCompetitionLumiere,
        TypeConflitAssociation.competitionAzote => assocMecaCompetitionAzote,
        TypeConflitAssociation.allelopathie => assocMecaAllelopathie,
      };

  /// Label for a derived-suggestion confidence level (ADR-0010).
  String confiance(NiveauConfiance c) => switch (c) {
        NiveauConfiance.faible => confianceFaible,
        NiveauConfiance.moyen => confianceMoyen,
        NiveauConfiance.eleve => confianceEleve,
      };

  /// Label for an association effect family (ADR-0011).
  String familleEffet(FamilleEffetAssociation f) => switch (f) {
        FamilleEffetAssociation.gainDePlace => familleEffetGainDePlace,
        FamilleEffetAssociation.protectionRavageurs =>
          familleEffetProtectionRavageurs,
        FamilleEffetAssociation.fertilite => familleEffetFertilite,
        FamilleEffetAssociation.pollinisation => familleEffetPollinisation,
        FamilleEffetAssociation.couvertureAbri => familleEffetCouvertureAbri,
      };

  /// Label for an association weight level (ADR-0011).
  String poids(PoidsAssociation p) => switch (p) {
        PoidsAssociation.ignore => poidsIgnore,
        PoidsAssociation.faible => poidsFaible,
        PoidsAssociation.normal => poidsNormal,
        PoidsAssociation.fort => poidsFort,
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

  /// Short helper describing a planting method (shown under each dropdown
  /// option) — the planting "type" the user picks when adding a plantation.
  String methodeDescription(MethodeMiseEnPlace m) => switch (m) {
        MethodeMiseEnPlace.semisDirect => methodeSemisDirectDesc,
        MethodeMiseEnPlace.semisInterieur => methodeSemisInterieurDesc,
        MethodeMiseEnPlace.repiquage => methodeRepiquageDesc,
        MethodeMiseEnPlace.plantAchete => methodePlantAcheteDesc,
        MethodeMiseEnPlace.bouture => methodeBoutureDesc,
        MethodeMiseEnPlace.division => methodeDivisionDesc,
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
