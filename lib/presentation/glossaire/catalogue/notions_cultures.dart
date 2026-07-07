import '../../../domain/enums/categorie_plante.dart';
import '../../../domain/enums/methode_mise_en_place.dart';
import '../../../domain/enums/raison_reco.dart';
import '../../../domain/enums/sous_type_legume.dart';
import '../../../domain/enums/stade_croissance.dart';
import '../../../domain/enums/statut_plantation.dart';
import '../../../domain/enums/usage_plante.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/libelles_enums.dart';
import '../chapitre_glossaire.dart';
import '../complement_terme.dart';
import '../terme_glossaire.dart';
import '../type_terme_glossaire.dart';

/// « Cultures & plantes » chapter of the notion catalogue (ADR-0017 Lot 4):
/// the enum-backed notions of the plant/plantation lifecycle. Value labels
/// reuse `LibellesEnums` when the app already displays them; glossary-only
/// labels live under the `glossaireVal*` ARB keys.
List<TermeGlossaire> construireNotionsCultures(AppLocalizations l10n) => [
      TermeGlossaire(
        id: TermeGlossaire.idNotion('categorie-plante'),
        chapitre: ChapitreGlossaire.culturesEtPlantes,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionCategoriePlanteTitre,
        definition: l10n.glossaireNotionCategoriePlanteDef,
        astuce: l10n.glossaireNotionCategoriePlanteAstuce,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in CategoriePlante.values)
              (libelle: l10n.categorie(v), description: null),
          ]),
          ComplementVoirAussi(ids: [
            TermeGlossaire.idNotion('sous-type-legume'),
            TermeGlossaire.idNotion('usage-plante'),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('sous-type-legume'),
        chapitre: ChapitreGlossaire.culturesEtPlantes,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionSousTypeLegumeTitre,
        definition: l10n.glossaireNotionSousTypeLegumeDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in SousTypeLegume.values) _sousType(l10n, v),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('usage-plante'),
        chapitre: ChapitreGlossaire.culturesEtPlantes,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionUsagePlanteTitre,
        definition: l10n.glossaireNotionUsagePlanteDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in UsagePlante.values) _usage(l10n, v),
          ]),
          ComplementVoirAussi(ids: [
            TermeGlossaire.idNotion('calcul-associations'),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('stade-croissance'),
        chapitre: ChapitreGlossaire.culturesEtPlantes,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionStadeCroissanceTitre,
        definition: l10n.glossaireNotionStadeCroissanceDef,
        astuce: l10n.glossaireNotionStadeCroissanceAstuce,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in StadeCroissance.values)
              (
                libelle: l10n.libelleStade(v),
                description: switch (v) {
                  StadeCroissance.levee => l10n.glossaireValStadeLeveeDesc,
                  StadeCroissance.croissance =>
                    l10n.glossaireValStadeCroissanceDesc,
                  StadeCroissance.maturation =>
                    l10n.glossaireValStadeMaturationDesc,
                  StadeCroissance.recolte => l10n.glossaireValStadeRecolteDesc,
                },
              ),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('methode-mise-en-place'),
        chapitre: ChapitreGlossaire.culturesEtPlantes,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionMethodeTitre,
        definition: l10n.glossaireNotionMethodeDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in MethodeMiseEnPlace.values)
              (libelle: l10n.methode(v), description: l10n.methodeDescription(v)),
          ]),
          ComplementVoirAussi(ids: [
            TermeGlossaire.idNotion('semis-direct-vs-godet'),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('semis-direct-vs-godet'),
        chapitre: ChapitreGlossaire.culturesEtPlantes,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionSemisGodetTitre,
        definition: l10n.glossaireNotionSemisGodetDef,
        astuce: l10n.glossaireNotionSemisGodetAstuce,
        conseils: [l10n.glossaireNotionSemisGodetConseil1],
        complements: [
          ComplementVoirAussi(ids: [
            TermeGlossaire.idNotion('methode-mise-en-place'),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('statut-plantation'),
        chapitre: ChapitreGlossaire.culturesEtPlantes,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionStatutPlantationTitre,
        definition: l10n.glossaireNotionStatutPlantationDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in StatutPlantation.values) _statut(l10n, v),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('pourquoi-recommandation'),
        chapitre: ChapitreGlossaire.culturesEtPlantes,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionPourquoiRecoTitre,
        definition: l10n.glossaireNotionPourquoiRecoDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in RaisonReco.values) _raison(l10n, v),
          ]),
          ComplementVoirAussi(ids: [
            TermeGlossaire.idNotion('calcul-associations'),
            TermeGlossaire.idNotion('rotation-cultures'),
          ]),
        ],
      ),
    ];

ValeurDecrite _sousType(AppLocalizations l10n, SousTypeLegume v) => switch (v) {
      SousTypeLegume.legumeFruit => (
          libelle: l10n.glossaireValLegumeFruit,
          description: l10n.glossaireValLegumeFruitDesc
        ),
      SousTypeLegume.legumeFeuille => (
          libelle: l10n.glossaireValLegumeFeuille,
          description: l10n.glossaireValLegumeFeuilleDesc
        ),
      SousTypeLegume.legumeRacine => (
          libelle: l10n.glossaireValLegumeRacine,
          description: l10n.glossaireValLegumeRacineDesc
        ),
      SousTypeLegume.legumeBulbe => (
          libelle: l10n.glossaireValLegumeBulbe,
          description: l10n.glossaireValLegumeBulbeDesc
        ),
      SousTypeLegume.legumeTige => (
          libelle: l10n.glossaireValLegumeTige,
          description: l10n.glossaireValLegumeTigeDesc
        ),
      SousTypeLegume.legumeFleur => (
          libelle: l10n.glossaireValLegumeFleur,
          description: l10n.glossaireValLegumeFleurDesc
        ),
      SousTypeLegume.legumeTubercule => (
          libelle: l10n.glossaireValLegumeTubercule,
          description: l10n.glossaireValLegumeTuberculeDesc
        ),
    };

ValeurDecrite _usage(AppLocalizations l10n, UsagePlante v) => switch (v) {
      UsagePlante.alimentaire => (
          libelle: l10n.glossaireValUsageAlimentaire,
          description: l10n.glossaireValUsageAlimentaireDesc
        ),
      UsagePlante.condimentaire => (
          libelle: l10n.glossaireValUsageCondimentaire,
          description: l10n.glossaireValUsageCondimentaireDesc
        ),
      UsagePlante.medicinale => (
          libelle: l10n.glossaireValUsageMedicinale,
          description: l10n.glossaireValUsageMedicinaleDesc
        ),
      UsagePlante.compagnonnage => (
          libelle: l10n.glossaireValUsageCompagnonnage,
          description: l10n.glossaireValUsageCompagnonnageDesc
        ),
      UsagePlante.repulsif => (
          libelle: l10n.glossaireValUsageRepulsif,
          description: l10n.glossaireValUsageRepulsifDesc
        ),
      UsagePlante.mellifere => (
          libelle: l10n.glossaireValUsageMellifere,
          description: l10n.glossaireValUsageMellifereDesc
        ),
      UsagePlante.pollinisateur => (
          libelle: l10n.glossaireValUsagePollinisateur,
          description: l10n.glossaireValUsagePollinisateurDesc
        ),
      UsagePlante.attireAuxiliaires => (
          libelle: l10n.glossaireValUsageAttireAuxiliaires,
          description: l10n.glossaireValUsageAttireAuxiliairesDesc
        ),
      UsagePlante.engraisVert => (
          libelle: l10n.glossaireValUsageEngraisVert,
          description: l10n.glossaireValUsageEngraisVertDesc
        ),
      UsagePlante.couvreSol => (
          libelle: l10n.glossaireValUsageCouvreSol,
          description: l10n.glossaireValUsageCouvreSolDesc
        ),
      UsagePlante.briseVent => (
          libelle: l10n.glossaireValUsageBriseVent,
          description: l10n.glossaireValUsageBriseVentDesc
        ),
      UsagePlante.tuteurVivant => (
          libelle: l10n.glossaireValUsageTuteurVivant,
          description: l10n.glossaireValUsageTuteurVivantDesc
        ),
      UsagePlante.ornementale => (
          libelle: l10n.glossaireValUsageOrnementale,
          description: l10n.glossaireValUsageOrnementaleDesc
        ),
      UsagePlante.fourrage => (
          libelle: l10n.glossaireValUsageFourrage,
          description: l10n.glossaireValUsageFourrageDesc
        ),
    };

ValeurDecrite _statut(AppLocalizations l10n, StatutPlantation v) => switch (v) {
      StatutPlantation.enCours => (
          libelle: l10n.glossaireValStatutEnCours,
          description: l10n.glossaireValStatutEnCoursDesc
        ),
      StatutPlantation.recoltee => (
          libelle: l10n.glossaireValStatutRecoltee,
          description: l10n.glossaireValStatutRecolteeDesc
        ),
      StatutPlantation.echouee => (
          libelle: l10n.glossaireValStatutEchouee,
          description: l10n.glossaireValStatutEchoueeDesc
        ),
      StatutPlantation.arrachee => (
          libelle: l10n.glossaireValStatutArrachee,
          description: l10n.glossaireValStatutArracheeDesc
        ),
    };

ValeurDecrite _raison(AppLocalizations l10n, RaisonReco v) => switch (v) {
      RaisonReco.plantableMaintenant => (
          libelle: l10n.glossaireValRecoPlantable,
          description: l10n.glossaireValRecoPlantableDesc
        ),
      RaisonReco.expositionAdaptee => (
          libelle: l10n.glossaireValRecoExposition,
          description: l10n.glossaireValRecoExpositionDesc
        ),
      RaisonReco.solAdapte => (
          libelle: l10n.glossaireValRecoSol,
          description: l10n.glossaireValRecoSolDesc
        ),
      RaisonReco.bonneAssociation => (
          libelle: l10n.glossaireValRecoAssociation,
          description: l10n.glossaireValRecoAssociationDesc
        ),
      RaisonReco.associationDeriveeFavorable => (
          libelle: l10n.glossaireValRecoAssociationDerivee,
          description: l10n.glossaireValRecoAssociationDeriveeDesc
        ),
      RaisonReco.rotationFavorable => (
          libelle: l10n.glossaireValRecoRotation,
          description: l10n.glossaireValRecoRotationDesc
        ),
      RaisonReco.niveauAdapte => (
          libelle: l10n.glossaireValRecoNiveau,
          description: l10n.glossaireValRecoNiveauDesc
        ),
      RaisonReco.cultureVerticaleCompatible => (
          libelle: l10n.glossaireValRecoVertical,
          description: l10n.glossaireValRecoVerticalDesc
        ),
    };
