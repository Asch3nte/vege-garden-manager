import '../../../domain/enums/type_bioagresseur.dart';
import '../../../l10n/app_localizations.dart';
import '../chapitre_glossaire.dart';
import '../complement_terme.dart';
import '../terme_glossaire.dart';
import '../type_terme_glossaire.dart';

/// « Santé du jardin » chapter of the notion catalogue (ADR-0017 Lot 4): the
/// transverse health notions — the per-bioaggressor pages themselves are
/// derived from the YAML reference by the registry.
List<TermeGlossaire> construireNotionsSante(AppLocalizations l10n) => [
      TermeGlossaire(
        id: TermeGlossaire.idNotion('bioagresseur'),
        chapitre: ChapitreGlossaire.santeDuJardin,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionBioagresseurTitre,
        definition: l10n.glossaireNotionBioagresseurDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in TypeBioagresseur.values)
              switch (v) {
                TypeBioagresseur.maladie => (
                    libelle: l10n.glossaireTypeMaladie,
                    description: l10n.glossaireValBioMaladieDesc
                  ),
                TypeBioagresseur.ravageur => (
                    libelle: l10n.glossaireTypeRavageur,
                    description: l10n.glossaireValBioRavageurDesc
                  ),
              },
          ]),
          ComplementVoirAussi(ids: [
            TermeGlossaire.idNotion('prevention'),
            TermeGlossaire.idNotion('rotation-cultures'),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('prevention'),
        chapitre: ChapitreGlossaire.santeDuJardin,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionPreventionTitre,
        definition: l10n.glossaireNotionPreventionDef,
        astuce: l10n.glossaireNotionPreventionAstuce,
        conseils: [
          l10n.glossaireNotionPreventionConseil1,
          l10n.glossaireNotionPreventionConseil2,
        ],
        complements: [
          ComplementVoirAussi(ids: [
            TermeGlossaire.idNotion('bioagresseur'),
            TermeGlossaire.idNotion('compagnonnage'),
          ]),
        ],
      ),
    ];
