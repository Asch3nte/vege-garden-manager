import '../../../domain/enums/enracinement_plante.dart';
import '../../../domain/enums/niveau_besoin.dart';
import '../../../domain/enums/ph_sol.dart';
import '../../../domain/enums/qualite_sol.dart';
import '../../../domain/enums/source_type_sol.dart';
import '../../../domain/enums/technique_sol.dart';
import '../../../domain/enums/texture_sol.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/libelles_enums.dart';
import '../chapitre_glossaire.dart';
import '../complement_terme.dart';
import '../terme_glossaire.dart';
import '../type_terme_glossaire.dart';

/// « Sol & terre » chapter of the notion catalogue (ADR-0017 Lot 4).
///
/// Per the D1 granularity rule, concrete objects get **one page per value**:
/// each soil texture and each soil technique has its own page; scales (pH,
/// qualities…) get one concept page listing their values.
List<TermeGlossaire> construireNotionsSol(AppLocalizations l10n) => [
      TermeGlossaire(
        id: TermeGlossaire.idNotion('texture-sol'),
        chapitre: ChapitreGlossaire.solEtTerre,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionTextureSolTitre,
        definition: l10n.glossaireNotionTextureSolDef,
        astuce: l10n.glossaireNotionTextureSolAstuce,
        complements: [
          ComplementVoirAussi(ids: [
            for (final v in TextureSol.values) _idTexture(v),
            TermeGlossaire.idNotion('qualite-sol'),
            TermeGlossaire.idNotion('ph-sol'),
          ]),
        ],
      ),
      for (final v in TextureSol.values) _pageTexture(l10n, v),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('ph-sol'),
        chapitre: ChapitreGlossaire.solEtTerre,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionPhSolTitre,
        definition: l10n.glossaireNotionPhSolDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in PhSol.values)
              (
                libelle: l10n.phSol(v),
                description: switch (v) {
                  PhSol.acide => l10n.glossaireValPhAcideDesc,
                  PhSol.neutre => l10n.glossaireValPhNeutreDesc,
                  PhSol.alcalin => l10n.glossaireValPhAlcalinDesc,
                },
              ),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('qualite-sol'),
        chapitre: ChapitreGlossaire.solEtTerre,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionQualiteSolTitre,
        definition: l10n.glossaireNotionQualiteSolDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in QualiteSol.values) _qualite(l10n, v),
          ]),
          ComplementVoirAussi(ids: [TermeGlossaire.idNotion('texture-sol')]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('source-type-sol'),
        chapitre: ChapitreGlossaire.solEtTerre,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionSourceSolTitre,
        definition: l10n.glossaireNotionSourceSolDef,
        astuce: l10n.glossaireNotionSourceSolAstuce,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in SourceTypeSol.values)
              switch (v) {
                SourceTypeSol.manuelle => (
                    libelle: l10n.glossaireValSourceManuelle,
                    description: l10n.glossaireValSourceManuelleDesc
                  ),
                SourceTypeSol.deduitDeLocalisation => (
                    libelle: l10n.glossaireValSourceLocalisation,
                    description: l10n.glossaireValSourceLocalisationDesc
                  ),
                SourceTypeSol.deduitDuClimat => (
                    libelle: l10n.glossaireValSourceClimat,
                    description: l10n.glossaireValSourceClimatDesc
                  ),
              },
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('techniques-sol'),
        chapitre: ChapitreGlossaire.solEtTerre,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionTechniquesSolTitre,
        definition: l10n.glossaireNotionTechniquesSolDef,
        complements: [
          ComplementVoirAussi(ids: [
            for (final v in TechniqueSol.values) idTechnique(v),
          ]),
        ],
      ),
      for (final v in TechniqueSol.values) _pageTechnique(l10n, v),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('enracinement'),
        chapitre: ChapitreGlossaire.solEtTerre,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionEnracinementTitre,
        definition: l10n.glossaireNotionEnracinementDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in EnracinementPlante.values)
              (
                libelle: l10n.enracinement(v),
                description: switch (v) {
                  EnracinementPlante.superficiel =>
                    l10n.glossaireValEnracinementSuperficielDesc,
                  EnracinementPlante.moyen =>
                    l10n.glossaireValEnracinementMoyenDesc,
                  EnracinementPlante.profond =>
                    l10n.glossaireValEnracinementProfondDesc,
                  EnracinementPlante.pivotant =>
                    l10n.glossaireValEnracinementPivotantDesc,
                },
              ),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('besoin-nutriments'),
        chapitre: ChapitreGlossaire.solEtTerre,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionBesoinNutrimentsTitre,
        definition: l10n.glossaireNotionBesoinNutrimentsDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in NiveauBesoin.values)
              switch (v) {
                NiveauBesoin.faible => (
                    libelle: l10n.glossaireValBesoinFaible,
                    description: l10n.glossaireValBesoinFaibleDesc
                  ),
                NiveauBesoin.modere => (
                    libelle: l10n.glossaireValBesoinModere,
                    description: l10n.glossaireValBesoinModereDesc
                  ),
                NiveauBesoin.eleve => (
                    libelle: l10n.glossaireValBesoinEleve,
                    description: l10n.glossaireValBesoinEleveDesc
                  ),
              },
          ]),
        ],
      ),
    ];

/// Glossary id of a texture page (one page per value, D1).
String _idTexture(TextureSol v) => TermeGlossaire.idNotion(switch (v) {
      TextureSol.argileux => 'sol-argileux',
      TextureSol.sableux => 'sol-sableux',
      TextureSol.limoneux => 'sol-limoneux',
      TextureSol.calcaire => 'sol-calcaire',
      TextureSol.humifere => 'sol-humifere',
      TextureSol.tourbeux => 'sol-tourbeux',
      TextureSol.caillouteux => 'sol-caillouteux',
    });

TermeGlossaire _pageTexture(AppLocalizations l10n, TextureSol v) {
  final (titre, definition, conseil) = switch (v) {
    TextureSol.argileux => (
        l10n.glossaireSolArgileuxTitre,
        l10n.glossaireSolArgileuxDef,
        l10n.glossaireSolArgileuxConseil1
      ),
    TextureSol.sableux => (
        l10n.glossaireSolSableuxTitre,
        l10n.glossaireSolSableuxDef,
        l10n.glossaireSolSableuxConseil1
      ),
    TextureSol.limoneux => (
        l10n.glossaireSolLimoneuxTitre,
        l10n.glossaireSolLimoneuxDef,
        l10n.glossaireSolLimoneuxConseil1
      ),
    TextureSol.calcaire => (
        l10n.glossaireSolCalcaireTitre,
        l10n.glossaireSolCalcaireDef,
        l10n.glossaireSolCalcaireConseil1
      ),
    TextureSol.humifere => (
        l10n.glossaireSolHumifereTitre,
        l10n.glossaireSolHumifereDef,
        l10n.glossaireSolHumifereConseil1
      ),
    TextureSol.tourbeux => (
        l10n.glossaireSolTourbeuxTitre,
        l10n.glossaireSolTourbeuxDef,
        l10n.glossaireSolTourbeuxConseil1
      ),
    TextureSol.caillouteux => (
        l10n.glossaireSolCaillouteuxTitre,
        l10n.glossaireSolCaillouteuxDef,
        l10n.glossaireSolCaillouteuxConseil1
      ),
  };
  return TermeGlossaire(
    id: _idTexture(v),
    chapitre: ChapitreGlossaire.solEtTerre,
    type: TypeTermeGlossaire.notion,
    titre: titre,
    definition: definition,
    conseils: [conseil],
    complements: [
      ComplementVoirAussi(ids: [TermeGlossaire.idNotion('texture-sol')]),
    ],
  );
}

/// Glossary id of a technique page (one page per value, D1). Public because
/// other chapters link to techniques (paillage, no-dig…) and the coverage map
/// enumerates them.
String idTechnique(TechniqueSol v) => TermeGlossaire.idNotion(switch (v) {
      TechniqueSol.butteLasagne => 'butte-lasagne',
      TechniqueSol.hugelkultur => 'hugelkultur',
      TechniqueSol.butteRonde => 'butte-ronde',
      TechniqueSol.buttePermanente => 'butte-permanente',
      TechniqueSol.paillage => 'paillage',
      TechniqueSol.brf => 'brf',
      TechniqueSol.mulchVivant => 'mulch-vivant',
      TechniqueSol.engraisVertCouvert => 'engrais-vert-couvert',
      TechniqueSol.paillageMineral => 'paillage-mineral',
      TechniqueSol.carton => 'carton',
      TechniqueSol.noDig => 'no-dig',
      TechniqueSol.grelinette => 'grelinette',
      TechniqueSol.mulchDeFoin => 'mulch-de-foin',
      TechniqueSol.compostageSurface => 'compostage-surface',
      TechniqueSol.compostEnTrou => 'compost-en-trou',
      TechniqueSol.mycorhization => 'mycorhization',
      TechniqueSol.bokashi => 'bokashi',
      TechniqueSol.swales => 'swales',
      TechniqueSol.keylineDesign => 'keyline-design',
    });

TermeGlossaire _pageTechnique(AppLocalizations l10n, TechniqueSol v) {
  final (String definition, String? astuce, String? conseil) = switch (v) {
    TechniqueSol.butteLasagne => (
        l10n.glossaireTechButteLasagneDef,
        null,
        l10n.glossaireTechButteLasagneConseil1
      ),
    TechniqueSol.hugelkultur => (
        l10n.glossaireTechHugelkulturDef,
        l10n.glossaireTechHugelkulturAstuce,
        null
      ),
    TechniqueSol.butteRonde => (l10n.glossaireTechButteRondeDef, null, null),
    TechniqueSol.buttePermanente => (
        l10n.glossaireTechButtePermanenteDef,
        null,
        null
      ),
    TechniqueSol.paillage => (
        l10n.glossaireTechPaillageDef,
        l10n.glossaireTechPaillageAstuce,
        l10n.glossaireTechPaillageConseil1
      ),
    TechniqueSol.brf => (
        l10n.glossaireTechBrfDef,
        null,
        l10n.glossaireTechBrfConseil1
      ),
    TechniqueSol.mulchVivant => (l10n.glossaireTechMulchVivantDef, null, null),
    TechniqueSol.engraisVertCouvert => (
        l10n.glossaireTechEngraisVertCouvertDef,
        null,
        null
      ),
    TechniqueSol.paillageMineral => (
        l10n.glossaireTechPaillageMineralDef,
        null,
        null
      ),
    TechniqueSol.carton => (
        l10n.glossaireTechCartonDef,
        null,
        l10n.glossaireTechCartonConseil1
      ),
    TechniqueSol.noDig => (l10n.glossaireTechNoDigDef, null, null),
    TechniqueSol.grelinette => (
        l10n.glossaireTechGrelinetteDef,
        l10n.glossaireTechGrelinetteAstuce,
        null
      ),
    TechniqueSol.mulchDeFoin => (l10n.glossaireTechMulchDeFoinDef, null, null),
    TechniqueSol.compostageSurface => (
        l10n.glossaireTechCompostageSurfaceDef,
        null,
        null
      ),
    TechniqueSol.compostEnTrou => (
        l10n.glossaireTechCompostEnTrouDef,
        null,
        null
      ),
    TechniqueSol.mycorhization => (
        l10n.glossaireTechMycorhizationDef,
        null,
        null
      ),
    TechniqueSol.bokashi => (l10n.glossaireTechBokashiDef, null, null),
    TechniqueSol.swales => (l10n.glossaireTechSwalesDef, null, null),
    TechniqueSol.keylineDesign => (
        l10n.glossaireTechKeylineDesignDef,
        null,
        null
      ),
  };
  return TermeGlossaire(
    id: idTechnique(v),
    chapitre: ChapitreGlossaire.solEtTerre,
    type: TypeTermeGlossaire.notion,
    titre: l10n.techniqueSol(v),
    definition: definition,
    astuce: astuce,
    conseils: [?conseil],
    complements: [
      ComplementVoirAussi(ids: [TermeGlossaire.idNotion('techniques-sol')]),
    ],
  );
}

ValeurDecrite _qualite(AppLocalizations l10n, QualiteSol v) => switch (v) {
      QualiteSol.riche => (
          libelle: l10n.glossaireValQualiteRiche,
          description: l10n.glossaireValQualiteRicheDesc
        ),
      QualiteSol.pauvre => (
          libelle: l10n.glossaireValQualitePauvre,
          description: l10n.glossaireValQualitePauvreDesc
        ),
      QualiteSol.bienDraine => (
          libelle: l10n.glossaireValQualiteBienDraine,
          description: l10n.glossaireValQualiteBienDraineDesc
        ),
      QualiteSol.malDraine => (
          libelle: l10n.glossaireValQualiteMalDraine,
          description: l10n.glossaireValQualiteMalDraineDesc
        ),
      QualiteSol.frais => (
          libelle: l10n.glossaireValQualiteFrais,
          description: l10n.glossaireValQualiteFraisDesc
        ),
      QualiteSol.sec => (
          libelle: l10n.glossaireValQualiteSec,
          description: l10n.glossaireValQualiteSecDesc
        ),
      QualiteSol.lourd => (
          libelle: l10n.glossaireValQualiteLourd,
          description: l10n.glossaireValQualiteLourdDesc
        ),
      QualiteSol.leger => (
          libelle: l10n.glossaireValQualiteLeger,
          description: l10n.glossaireValQualiteLegerDesc
        ),
    };
