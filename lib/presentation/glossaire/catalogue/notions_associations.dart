import '../../../application/engine/moteur_derivation_associations.dart';
import '../../../domain/enums/famille_effet_association.dart';
import '../../../domain/enums/famille_effet_conflit.dart';
import '../../../domain/enums/niveau_confiance.dart';
import '../../../domain/enums/poids_association.dart';
import '../../../domain/enums/sens_association.dart';
import '../../../domain/enums/type_benefice_association.dart';
import '../../../domain/enums/type_conflit_association.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/libelles_enums.dart';
import '../chapitre_glossaire.dart';
import '../complement_terme.dart';
import '../terme_glossaire.dart';
import '../type_terme_glossaire.dart';

/// « Associations & compagnonnage » chapter of the catalogue (ADR-0017 Lot 4):
/// the general « how the app computes associations » page, **one page per
/// mechanism** (benefit and conflict) carrying its provenance — derived from
/// the engine's own rule inventory, never marked by hand — plus the scoring
/// vocabulary (effect families, direction, confidence, weighting).
List<TermeGlossaire> construireNotionsAssociations(AppLocalizations l10n) => [
      TermeGlossaire(
        id: TermeGlossaire.idNotion('calcul-associations'),
        chapitre: ChapitreGlossaire.associationsEtCompagnonnage,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionCalculAssociationsTitre,
        definition: l10n.glossaireNotionCalculAssociationsDef,
        astuce: l10n.glossaireNotionCalculAssociationsAstuce,
        conseils: [
          l10n.glossaireNotionCalculAssociationsConseil1,
          l10n.glossaireNotionCalculAssociationsConseil2,
          l10n.glossaireNotionCalculAssociationsConseil3,
        ],
        complements: [
          ComplementVoirAussi(ids: [
            TermeGlossaire.idNotion('compagnonnage'),
            TermeGlossaire.idNotion('familles-effets'),
            TermeGlossaire.idNotion('sens-association'),
            TermeGlossaire.idNotion('niveau-confiance'),
            TermeGlossaire.idNotion('ponderation-associations'),
          ]),
        ],
      ),
      for (final m in TypeBeneficeAssociation.values) _pageBenefice(l10n, m),
      for (final m in TypeConflitAssociation.values) _pageConflit(l10n, m),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('familles-effets'),
        chapitre: ChapitreGlossaire.associationsEtCompagnonnage,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionFamillesEffetsTitre,
        definition: l10n.glossaireNotionFamillesEffetsDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final f in FamilleEffetAssociation.values)
              (
                libelle: l10n.familleEffet(f),
                description: switch (f) {
                  FamilleEffetAssociation.gainDePlace =>
                    l10n.glossaireValFamGainDePlaceDesc,
                  FamilleEffetAssociation.protectionRavageurs =>
                    l10n.glossaireValFamProtectionDesc,
                  FamilleEffetAssociation.fertilite =>
                    l10n.glossaireValFamFertiliteDesc,
                  FamilleEffetAssociation.pollinisation =>
                    l10n.glossaireValFamPollinisationDesc,
                  FamilleEffetAssociation.couvertureAbri =>
                    l10n.glossaireValFamCouvertureDesc,
                },
              ),
            for (final f in FamilleEffetConflit.values)
              (
                libelle: l10n.familleEffetConflit(f),
                description: switch (f) {
                  FamilleEffetConflit.concurrenceRessources =>
                    l10n.glossaireValFamConcurrenceDesc,
                  FamilleEffetConflit.risqueSanitaire =>
                    l10n.glossaireValFamSanitaireDesc,
                  FamilleEffetConflit.allelopathie =>
                    l10n.glossaireValFamAllelopathieDesc,
                },
              ),
          ]),
          ComplementVoirAussi(ids: [
            TermeGlossaire.idNotion('ponderation-associations'),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('sens-association'),
        chapitre: ChapitreGlossaire.associationsEtCompagnonnage,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionSensAssociationTitre,
        definition: l10n.glossaireNotionSensAssociationDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in SensAssociation.values)
              switch (v) {
                SensAssociation.donne => (
                    libelle: l10n.sensDonne,
                    description: l10n.glossaireValSensDonneDesc
                  ),
                SensAssociation.recoit => (
                    libelle: l10n.sensRecoit,
                    description: l10n.glossaireValSensRecoitDesc
                  ),
                SensAssociation.mutuel => (
                    libelle: l10n.sensMutuel,
                    description: l10n.glossaireValSensMutuelDesc
                  ),
              },
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('niveau-confiance'),
        chapitre: ChapitreGlossaire.associationsEtCompagnonnage,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionNiveauConfianceTitre,
        definition: l10n.glossaireNotionNiveauConfianceDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in NiveauConfiance.values)
              switch (v) {
                NiveauConfiance.faible => (
                    libelle: l10n.assocFiltreFaible,
                    description: l10n.glossaireValConfianceFaibleDesc
                  ),
                NiveauConfiance.moyen => (
                    libelle: l10n.assocFiltreMoyen,
                    description: l10n.glossaireValConfianceMoyenDesc
                  ),
                NiveauConfiance.eleve => (
                    libelle: l10n.assocFiltreEleve,
                    description: l10n.glossaireValConfianceEleveDesc
                  ),
              },
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('ponderation-associations'),
        chapitre: ChapitreGlossaire.associationsEtCompagnonnage,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionPonderationTitre,
        definition: l10n.glossaireNotionPonderationDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in PoidsAssociation.values)
              (
                libelle: l10n.poids(v),
                description: switch (v) {
                  PoidsAssociation.ignore => l10n.glossaireValPoidsIgnoreDesc,
                  PoidsAssociation.faible => l10n.glossaireValPoidsFaibleDesc,
                  PoidsAssociation.normal => l10n.glossaireValPoidsNormalDesc,
                  PoidsAssociation.fort => l10n.glossaireValPoidsFortDesc,
                },
              ),
          ]),
          ComplementVoirAussi(ids: [TermeGlossaire.idNotion('familles-effets')]),
        ],
      ),
    ];

/// Glossary id of a benefit-mechanism page. Public for the coverage map.
String idMecanismeBenefice(TypeBeneficeAssociation m) =>
    TermeGlossaire.idNotion(switch (m) {
      TypeBeneficeAssociation.tuteurStructurel => 'meca-tuteur-structurel',
      TypeBeneficeAssociation.etagementLumiere => 'meca-etagement-lumiere',
      TypeBeneficeAssociation.repulsionRavageur => 'meca-repulsion-ravageur',
      TypeBeneficeAssociation.brouillageOlfactif => 'meca-brouillage-olfactif',
      TypeBeneficeAssociation.attractionPollinisateurs =>
        'meca-attraction-pollinisateurs',
      TypeBeneficeAssociation.attractionAuxiliaires =>
        'meca-attraction-auxiliaires',
      TypeBeneficeAssociation.plantePiege => 'meca-plante-piege',
      TypeBeneficeAssociation.fixationAzote => 'meca-fixation-azote',
      TypeBeneficeAssociation.ameublissementSol => 'meca-ameublissement-sol',
      TypeBeneficeAssociation.couvreSol => 'meca-couvre-sol',
      TypeBeneficeAssociation.briseVent => 'meca-brise-vent',
      TypeBeneficeAssociation.successionTemporelle =>
        'meca-succession-temporelle',
    });

/// Glossary id of a conflict-mechanism page. Public for the coverage map.
String idMecanismeConflit(TypeConflitAssociation m) =>
    TermeGlossaire.idNotion(switch (m) {
      TypeConflitAssociation.memeFamilleRavageurs =>
        'meca-meme-famille-ravageurs',
      TypeConflitAssociation.competitionLumiere => 'meca-competition-lumiere',
      TypeConflitAssociation.competitionAzote => 'meca-competition-azote',
      TypeConflitAssociation.competitionEau => 'meca-competition-eau',
      TypeConflitAssociation.competitionEspace => 'meca-competition-espace',
      TypeConflitAssociation.partageMaladies => 'meca-partage-maladies',
      TypeConflitAssociation.allelopathie => 'meca-allelopathie',
    });

TermeGlossaire _pageBenefice(AppLocalizations l10n, TypeBeneficeAssociation m) =>
    TermeGlossaire(
      id: idMecanismeBenefice(m),
      chapitre: ChapitreGlossaire.associationsEtCompagnonnage,
      type: TypeTermeGlossaire.notion,
      // Same title as everywhere in the associations UI (LibellesEnums).
      titre: l10n.mecanismeBenefice(m),
      definition: switch (m) {
        TypeBeneficeAssociation.tuteurStructurel =>
          l10n.glossaireMecaTuteurStructurelDef,
        TypeBeneficeAssociation.etagementLumiere =>
          l10n.glossaireMecaEtagementLumiereDef,
        TypeBeneficeAssociation.repulsionRavageur =>
          l10n.glossaireMecaRepulsionRavageurDef,
        TypeBeneficeAssociation.brouillageOlfactif =>
          l10n.glossaireMecaBrouillageOlfactifDef,
        TypeBeneficeAssociation.attractionPollinisateurs =>
          l10n.glossaireMecaAttractionPollinisateursDef,
        TypeBeneficeAssociation.attractionAuxiliaires =>
          l10n.glossaireMecaAttractionAuxiliairesDef,
        TypeBeneficeAssociation.plantePiege => l10n.glossaireMecaPlantePiegeDef,
        TypeBeneficeAssociation.fixationAzote =>
          l10n.glossaireMecaFixationAzoteDef,
        TypeBeneficeAssociation.ameublissementSol =>
          l10n.glossaireMecaAmeublissementSolDef,
        TypeBeneficeAssociation.couvreSol => l10n.glossaireMecaCouvreSolDef,
        TypeBeneficeAssociation.briseVent => l10n.glossaireMecaBriseVentDef,
        TypeBeneficeAssociation.successionTemporelle =>
          l10n.glossaireMecaSuccessionTemporelleDef,
      },
      complements: [
        // Provenance derived from the engine's rule inventory (never by hand);
        // the coherence test on the engine keeps that inventory honest.
        ComplementProvenanceMecanisme(
          calculeParMoteur:
              MoteurDerivationAssociations.beneficesDerivables.contains(m),
        ),
        ComplementVoirAussi(ids: [
          TermeGlossaire.idNotion('calcul-associations'),
          TermeGlossaire.idNotion('familles-effets'),
        ]),
      ],
    );

TermeGlossaire _pageConflit(AppLocalizations l10n, TypeConflitAssociation m) =>
    TermeGlossaire(
      id: idMecanismeConflit(m),
      chapitre: ChapitreGlossaire.associationsEtCompagnonnage,
      type: TypeTermeGlossaire.notion,
      titre: l10n.mecanismeConflit(m),
      definition: switch (m) {
        TypeConflitAssociation.memeFamilleRavageurs =>
          l10n.glossaireMecaMemeFamilleRavageursDef,
        TypeConflitAssociation.competitionLumiere =>
          l10n.glossaireMecaCompetitionLumiereDef,
        TypeConflitAssociation.competitionAzote =>
          l10n.glossaireMecaCompetitionAzoteDef,
        TypeConflitAssociation.competitionEau =>
          l10n.glossaireMecaCompetitionEauDef,
        TypeConflitAssociation.competitionEspace =>
          l10n.glossaireMecaCompetitionEspaceDef,
        TypeConflitAssociation.partageMaladies =>
          l10n.glossaireMecaPartageMaladiesDef,
        TypeConflitAssociation.allelopathie =>
          l10n.glossaireMecaAllelopathieDef,
      },
      complements: [
        ComplementProvenanceMecanisme(
          calculeParMoteur:
              MoteurDerivationAssociations.conflitsDerivables.contains(m),
        ),
        ComplementVoirAussi(ids: [
          TermeGlossaire.idNotion('calcul-associations'),
          TermeGlossaire.idNotion('familles-effets'),
        ]),
      ],
    );
