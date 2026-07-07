import '../../../domain/enums/etat_ciel_jour.dart';
import '../../../domain/enums/hemisphere.dart';
import '../../../domain/enums/niveau_soleil.dart';
import '../../../domain/enums/type_alerte_meteo.dart';
import '../../../domain/enums/type_climat.dart';
import '../../../domain/enums/zone_rusticite.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/libelles_enums.dart';
import '../chapitre_glossaire.dart';
import '../complement_terme.dart';
import '../terme_glossaire.dart';
import '../type_terme_glossaire.dart';

/// « Climat & saisons » chapter of the notion catalogue (ADR-0017 Lot 4):
/// climates, hardiness, hemispheres, weather alerts and sky conditions.
List<TermeGlossaire> construireNotionsClimat(AppLocalizations l10n) => [
      TermeGlossaire(
        id: TermeGlossaire.idNotion('type-climat'),
        chapitre: ChapitreGlossaire.climatEtSaisons,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionTypeClimatTitre,
        definition: l10n.glossaireNotionTypeClimatDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in TypeClimat.values)
              (libelle: l10n.climat(v), description: l10n.climatDescription(v)),
          ]),
          ComplementVoirAussi(ids: [
            TermeGlossaire.idNotion('hemisphere-saisons'),
            TermeGlossaire.idNotion('zone-rusticite'),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('zone-rusticite'),
        chapitre: ChapitreGlossaire.climatEtSaisons,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionZoneRusticiteTitre,
        definition: l10n.glossaireNotionZoneRusticiteDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in ZoneRusticite.values)
              (
                libelle: l10n.rusticite(v),
                description: l10n.rusticiteDescription(v)
              ),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('hemisphere-saisons'),
        chapitre: ChapitreGlossaire.climatEtSaisons,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionHemisphereTitre,
        definition: l10n.glossaireNotionHemisphereDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in Hemisphere.values)
              switch (v) {
                Hemisphere.nord => (
                    libelle: l10n.glossaireValHemisphereNord,
                    description: l10n.glossaireValHemisphereNordDesc
                  ),
                Hemisphere.sud => (
                    libelle: l10n.glossaireValHemisphereSud,
                    description: l10n.glossaireValHemisphereSudDesc
                  ),
              },
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('alertes-meteo'),
        chapitre: ChapitreGlossaire.climatEtSaisons,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionAlertesMeteoTitre,
        definition: l10n.glossaireNotionAlertesMeteoDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in TypeAlerteMeteo.values)
              switch (v) {
                TypeAlerteMeteo.gel => (
                    libelle: l10n.glossaireValAlerteGel,
                    description: l10n.glossaireValAlerteGelDesc
                  ),
                TypeAlerteMeteo.canicule => (
                    libelle: l10n.glossaireValAlerteCanicule,
                    description: l10n.glossaireValAlerteCaniculeDesc
                  ),
                TypeAlerteMeteo.fortePluie => (
                    libelle: l10n.glossaireValAlerteFortePluie,
                    description: l10n.glossaireValAlerteFortePluieDesc
                  ),
              },
          ]),
          ComplementVoirAussi(ids: [
            TermeGlossaire.idOutil('voile-hivernage'),
            TermeGlossaire.idNotion('zone-rusticite'),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('etat-ciel'),
        chapitre: ChapitreGlossaire.climatEtSaisons,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionEtatCielTitre,
        definition: l10n.glossaireNotionEtatCielDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in EtatCielJour.values)
              (
                libelle: switch (v) {
                  EtatCielJour.ensoleille => l10n.glossaireValCielEnsoleille,
                  EtatCielJour.nuageux => l10n.glossaireValCielNuageux,
                  EtatCielJour.couvert => l10n.glossaireValCielCouvert,
                  EtatCielJour.brouillard => l10n.glossaireValCielBrouillard,
                  EtatCielJour.pluie => l10n.glossaireValCielPluie,
                  EtatCielJour.neige => l10n.glossaireValCielNeige,
                  EtatCielJour.orage => l10n.glossaireValCielOrage,
                },
                description: null,
              ),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('exposition'),
        chapitre: ChapitreGlossaire.climatEtSaisons,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionExpositionTitre,
        definition: l10n.glossaireNotionExpositionDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in NiveauSoleil.values)
              (
                libelle: l10n.exposition(v),
                description: switch (v) {
                  NiveauSoleil.pleinSoleil =>
                    l10n.glossaireValExpositionPleinSoleilDesc,
                  NiveauSoleil.miOmbre =>
                    l10n.glossaireValExpositionMiOmbreDesc,
                  NiveauSoleil.ombre => l10n.glossaireValExpositionOmbreDesc,
                },
              ),
          ]),
        ],
      ),
    ];
