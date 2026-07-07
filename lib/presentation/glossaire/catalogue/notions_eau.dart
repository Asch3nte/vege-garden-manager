import '../../../domain/enums/besoin_eau.dart';
import '../../../domain/enums/tolerance_secheresse.dart';
import '../../../domain/enums/urgence_arrosage.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/libelles_enums.dart';
import '../chapitre_glossaire.dart';
import '../complement_terme.dart';
import '../terme_glossaire.dart';
import '../type_terme_glossaire.dart';

/// « Eau & arrosage » chapter of the notion catalogue (ADR-0017 Lot 4): the
/// smart-watering vocabulary (ADR-0015) — needs, urgency, drought tolerance,
/// reference evapotranspiration.
List<TermeGlossaire> construireNotionsEau(AppLocalizations l10n) => [
      TermeGlossaire(
        id: TermeGlossaire.idNotion('besoin-eau'),
        chapitre: ChapitreGlossaire.eauEtArrosage,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionBesoinEauTitre,
        definition: l10n.glossaireNotionBesoinEauDef,
        astuce: l10n.glossaireNotionBesoinEauAstuce,
        conseils: [l10n.glossaireNotionBesoinEauConseil1],
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in BesoinEau.values)
              (
                libelle: l10n.besoinEau(v),
                description: switch (v) {
                  BesoinEau.faible => l10n.glossaireValEauFaibleDesc,
                  BesoinEau.modere => l10n.glossaireValEauModereDesc,
                  BesoinEau.eleve => l10n.glossaireValEauEleveDesc,
                },
              ),
          ]),
          ComplementVoirAussi(ids: [
            TermeGlossaire.idNotion('urgence-arrosage'),
            TermeGlossaire.idOutil('oya'),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('urgence-arrosage'),
        chapitre: ChapitreGlossaire.eauEtArrosage,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionUrgenceArrosageTitre,
        definition: l10n.glossaireNotionUrgenceArrosageDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in UrgenceArrosage.values)
              switch (v) {
                UrgenceArrosage.arroserMaintenant => (
                    libelle: l10n.glossaireValUrgenceMaintenant,
                    description: l10n.glossaireValUrgenceMaintenantDesc
                  ),
                UrgenceArrosage.bientot => (
                    libelle: l10n.glossaireValUrgenceBientot,
                    description: l10n.glossaireValUrgenceBientotDesc
                  ),
                UrgenceArrosage.pasNecessaire => (
                    libelle: l10n.glossaireValUrgencePasNecessaire,
                    description: l10n.glossaireValUrgencePasNecessaireDesc
                  ),
              },
          ]),
          ComplementVoirAussi(ids: [
            TermeGlossaire.idNotion('besoin-eau'),
            TermeGlossaire.idNotion('tolerance-secheresse'),
            TermeGlossaire.idNotion('evapotranspiration'),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('tolerance-secheresse'),
        chapitre: ChapitreGlossaire.eauEtArrosage,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionToleranceSecheresseTitre,
        definition: l10n.glossaireNotionToleranceSecheresseDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in ToleranceSecheresse.values)
              switch (v) {
                ToleranceSecheresse.faible => (
                    libelle: l10n.glossaireValToleranceFaible,
                    description: l10n.glossaireValToleranceFaibleDesc
                  ),
                ToleranceSecheresse.moyenne => (
                    libelle: l10n.glossaireValToleranceMoyenne,
                    description: l10n.glossaireValToleranceMoyenneDesc
                  ),
                ToleranceSecheresse.forte => (
                    libelle: l10n.glossaireValToleranceForte,
                    description: l10n.glossaireValToleranceForteDesc
                  ),
              },
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('evapotranspiration'),
        chapitre: ChapitreGlossaire.eauEtArrosage,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionEvapotranspirationTitre,
        definition: l10n.glossaireNotionEvapotranspirationDef,
        astuce: l10n.glossaireNotionEvapotranspirationAstuce,
        complements: [
          ComplementVoirAussi(ids: [TermeGlossaire.idNotion('urgence-arrosage')]),
        ],
      ),
    ];
