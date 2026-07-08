import '../../domain/enums/groupe_cultural.dart';
import '../../l10n/app_localizations.dart';
import 'complement_terme.dart';
import 'catalogue/notions_associations.dart';
import 'catalogue/notions_climat.dart';
import 'catalogue/notions_cultures.dart';
import 'catalogue/notions_eau.dart';
import 'catalogue/notions_gestes.dart';
import 'catalogue/notions_sante.dart';
import 'catalogue/notions_sol.dart';
import 'catalogue/outils.dart';
import 'chapitre_glossaire.dart';
import 'terme_glossaire.dart';
import 'type_terme_glossaire.dart';

/// The static catalogue of **notions & tools** (ADR-0017, D1/D6) — every
/// glossary entry that is *not* derived from a YAML reference. Content lives
/// in the ARB (`glossaire*` keys) and may embed wiki links (D2).
///
/// Lot 4 covers the full annexe A inventory: the transverse seed notions
/// below, then one chapter file per book chapter under `catalogue/` (one page
/// per tool, per soil texture, per soil technique, per association mechanism;
/// one concept page per remaining business enum). Coverage is proved by the
/// glossary integrity test against `couverture_glossaire.dart`.
List<TermeGlossaire> construireNotions(AppLocalizations l10n) =>
    List<TermeGlossaire>.unmodifiable([
      TermeGlossaire(
        id: TermeGlossaire.idNotion('famille-botanique'),
        chapitre: ChapitreGlossaire.famillesBotaniques,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionFamilleBotaniqueTitre,
        definition: l10n.glossaireNotionFamilleBotaniqueDef,
        astuce: l10n.glossaireNotionFamilleBotaniqueAstuce,
        conseils: [l10n.glossaireNotionFamilleBotaniqueConseil1],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('rotation-cultures'),
        chapitre: ChapitreGlossaire.famillesBotaniques,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionRotationTitre,
        definition: l10n.glossaireNotionRotationDef,
        astuce: l10n.glossaireNotionRotationAstuce,
        conseils: [
          l10n.glossaireNotionRotationConseil1,
          l10n.glossaireNotionRotationConseil2,
          l10n.glossaireNotionRotationConseil3,
          l10n.glossaireNotionRotationConseil4,
          l10n.glossaireNotionRotationConseil5,
          l10n.glossaireNotionRotationConseil6,
          l10n.glossaireNotionRotationConseil7,
        ],
        complements: [
          // The two functional crop groups (GroupeCultural) a plant can list as
          // a rotation precedent — this is where those values are explained.
          ComplementValeursEnum(valeurs: [
            for (final g in GroupeCultural.values)
              switch (g) {
                GroupeCultural.legumineuses => (
                    libelle: l10n.glossaireValGroupeCulturalLegumineuses,
                    description:
                        l10n.glossaireValGroupeCulturalLegumineusesDesc
                  ),
                GroupeCultural.engraisVerts => (
                    libelle: l10n.glossaireValGroupeCulturalEngraisVerts,
                    description:
                        l10n.glossaireValGroupeCulturalEngraisVertsDesc
                  ),
              },
          ]),
          ComplementVoirAussi(ids: [
            TermeGlossaire.idNotion('famille-botanique'),
            TermeGlossaire.idNotion('compagnonnage'),
            TermeGlossaire.idNotion('besoin-nutriments'),
          ]),
        ],
      ),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('compagnonnage'),
        chapitre: ChapitreGlossaire.associationsEtCompagnonnage,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionCompagnonnageTitre,
        definition: l10n.glossaireNotionCompagnonnageDef,
        astuce: l10n.glossaireNotionCompagnonnageAstuce,
        conseils: [l10n.glossaireNotionCompagnonnageConseil1],
      ),
      TermeGlossaire(
        id: idNotionCommencer,
        chapitre: ChapitreGlossaire.gestesEtOrganisation,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionCommencerTitre,
        definition: l10n.glossaireNotionCommencerDef,
        astuce: l10n.glossaireNotionCommencerAstuce,
        conseils: [l10n.glossaireNotionCommencerConseil1],
      ),
      ...construireNotionsCultures(l10n),
      ...construireNotionsSante(l10n),
      ...construireNotionsSol(l10n),
      ...construireNotionsEau(l10n),
      ...construireOutils(l10n),
      ...construireNotionsClimat(l10n),
      ...construireNotionsAssociations(l10n),
      ...construireNotionsGestes(l10n),
    ]);

/// Id of the novice landing page the glossary panel highlights
/// (« Par où commencer ? », ADR-0017 D3).
final String idNotionCommencer = TermeGlossaire.idNotion('par-ou-commencer');
