import '../../../domain/enums/destination_recolte.dart';
import '../../../domain/enums/gravite_observation.dart';
import '../../../domain/enums/niveau_experience.dart';
import '../../../domain/enums/priorite_tache.dart';
import '../../../domain/enums/qualite_recolte.dart';
import '../../../domain/enums/type_emplacement.dart';
import '../../../domain/enums/type_observation.dart';
import '../../../domain/enums/type_parcelle.dart';
import '../../../domain/enums/type_recurrence.dart';
import '../../../domain/enums/type_tache.dart';
import '../../../domain/enums/unite_quantite.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/libelles_enums.dart';
import '../chapitre_glossaire.dart';
import '../complement_terme.dart';
import '../terme_glossaire.dart';
import '../type_terme_glossaire.dart';

/// « Gestes & organisation » chapter of the notion catalogue (ADR-0017 Lot 4):
/// tasks, harvests, observations, zones and experience tiers — plus the
/// transverse permaculture notion.
List<TermeGlossaire> construireNotionsGestes(AppLocalizations l10n) => [
      TermeGlossaire(
        id: TermeGlossaire.idNotion('types-taches'),
        chapitre: ChapitreGlossaire.gestesEtOrganisation,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionTypesTachesTitre,
        definition: l10n.glossaireNotionTypesTachesDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in TypeTache.values)
              (libelle: l10n.typeTache(v), description: null),
          ]),
          ComplementVoirAussi(ids: [
            TermeGlossaire.idNotion('priorite-tache'),
            TermeGlossaire.idNotion('recurrence'),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('priorite-tache'),
        chapitre: ChapitreGlossaire.gestesEtOrganisation,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionPrioriteTacheTitre,
        definition: l10n.glossaireNotionPrioriteTacheDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in PrioriteTache.values)
              (
                libelle: switch (v) {
                  PrioriteTache.basse => l10n.glossaireValPrioriteBasse,
                  PrioriteTache.normale => l10n.glossaireValPrioriteNormale,
                  PrioriteTache.haute => l10n.glossaireValPrioriteHaute,
                  PrioriteTache.urgente => l10n.glossaireValPrioriteUrgente,
                },
                description: null,
              ),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('recurrence'),
        chapitre: ChapitreGlossaire.gestesEtOrganisation,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionRecurrenceTitre,
        definition: l10n.glossaireNotionRecurrenceDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in TypeRecurrence.values)
              switch (v) {
                TypeRecurrence.ponctuel => (
                    libelle: l10n.glossaireValRecurrencePonctuel,
                    description: l10n.glossaireValRecurrencePonctuelDesc
                  ),
                TypeRecurrence.quotidien => (
                    libelle: l10n.glossaireValRecurrenceQuotidien,
                    description: null
                  ),
                TypeRecurrence.hebdomadaire => (
                    libelle: l10n.glossaireValRecurrenceHebdomadaire,
                    description: null
                  ),
                TypeRecurrence.mensuel => (
                    libelle: l10n.glossaireValRecurrenceMensuel,
                    description: null
                  ),
                TypeRecurrence.personnalise => (
                    libelle: l10n.glossaireValRecurrencePersonnalise,
                    description: l10n.glossaireValRecurrencePersonnaliseDesc
                  ),
              },
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('destination-recolte'),
        chapitre: ChapitreGlossaire.gestesEtOrganisation,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionDestinationRecolteTitre,
        definition: l10n.glossaireNotionDestinationRecolteDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in DestinationRecolte.values)
              (libelle: l10n.destinationRecolte(v), description: null),
          ]),
          ComplementVoirAussi(ids: [
            TermeGlossaire.idNotion('qualite-recolte'),
            TermeGlossaire.idNotion('unites-quantite'),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('qualite-recolte'),
        chapitre: ChapitreGlossaire.gestesEtOrganisation,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionQualiteRecolteTitre,
        definition: l10n.glossaireNotionQualiteRecolteDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in QualiteRecolte.values)
              (
                libelle: switch (v) {
                  QualiteRecolte.excellente =>
                    l10n.glossaireValQualiteRecolteExcellente,
                  QualiteRecolte.bonne => l10n.glossaireValQualiteRecolteBonne,
                  QualiteRecolte.moyenne =>
                    l10n.glossaireValQualiteRecolteMoyenne,
                  QualiteRecolte.mediocre =>
                    l10n.glossaireValQualiteRecolteMediocre,
                },
                description: null,
              ),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('unites-quantite'),
        chapitre: ChapitreGlossaire.gestesEtOrganisation,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionUnitesTitre,
        definition: l10n.glossaireNotionUnitesDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in UniteQuantite.values)
              (
                libelle: l10n.unite(v),
                description: switch (v) {
                  UniteQuantite.g => l10n.glossaireValUniteGDesc,
                  UniteQuantite.kg => l10n.glossaireValUniteKgDesc,
                  UniteQuantite.piece => l10n.glossaireValUnitePieceDesc,
                  UniteQuantite.botte => l10n.glossaireValUniteBotteDesc,
                  UniteQuantite.litre => l10n.glossaireValUniteLitreDesc,
                  UniteQuantite.ml => l10n.glossaireValUniteMlDesc,
                },
              ),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('types-observations'),
        chapitre: ChapitreGlossaire.gestesEtOrganisation,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionTypesObservationsTitre,
        definition: l10n.glossaireNotionTypesObservationsDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in TypeObservation.values)
              (libelle: l10n.typeObservation(v), description: null),
          ]),
          ComplementVoirAussi(ids: [
            TermeGlossaire.idNotion('gravite-observation'),
            TermeGlossaire.idNotion('prevention'),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('gravite-observation'),
        chapitre: ChapitreGlossaire.gestesEtOrganisation,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionGraviteObservationTitre,
        definition: l10n.glossaireNotionGraviteObservationDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in GraviteObservation.values)
              (
                libelle: switch (v) {
                  GraviteObservation.info => l10n.glossaireValGraviteInfo,
                  GraviteObservation.faible => l10n.glossaireValGraviteFaible,
                  GraviteObservation.modere => l10n.glossaireValGraviteModere,
                  GraviteObservation.eleve => l10n.glossaireValGraviteEleve,
                  GraviteObservation.critique =>
                    l10n.glossaireValGraviteCritique,
                },
                description: null,
              ),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('types-parcelles'),
        chapitre: ChapitreGlossaire.gestesEtOrganisation,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionTypesParcellesTitre,
        definition: l10n.glossaireNotionTypesParcellesDef,
        conseils: [l10n.glossaireNotionTypesParcellesConseil1],
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in TypeParcelle.values)
              (libelle: l10n.typeParcelle(v), description: null),
          ]),
          ComplementVoirAussi(ids: [
            TermeGlossaire.idNotion('types-emplacements'),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('types-emplacements'),
        chapitre: ChapitreGlossaire.gestesEtOrganisation,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionTypesEmplacementsTitre,
        definition: l10n.glossaireNotionTypesEmplacementsDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in TypeEmplacement.values)
              (libelle: l10n.emplacement(v), description: null),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('niveaux-experience'),
        chapitre: ChapitreGlossaire.gestesEtOrganisation,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionNiveauxExperienceTitre,
        definition: l10n.glossaireNotionNiveauxExperienceDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in NiveauExperience.values)
              (
                libelle: l10n.niveauExperience(v),
                description: l10n.niveauDescription(v)
              ),
          ]),
          ComplementVoirAussi(ids: [TermeGlossaire.idNotion('par-ou-commencer')]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('permaculture'),
        chapitre: ChapitreGlossaire.gestesEtOrganisation,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionPermacultureTitre,
        definition: l10n.glossaireNotionPermacultureDef,
        conseils: [l10n.glossaireNotionPermacultureConseil1],
        complements: [
          ComplementVoirAussi(ids: [
            TermeGlossaire.idNotion('compagnonnage'),
            TermeGlossaire.idNotion('paillage'),
          ]),
        ],
      ),
    ];
