import '../../domain/entities/bioagresseur.dart';
import '../../domain/entities/famille_botanique.dart';
import '../../domain/enums/type_bioagresseur.dart';
import '../../l10n/app_localizations.dart';
import 'catalogue_notions.dart';
import 'chapitre_glossaire.dart';
import 'complement_terme.dart';
import 'illustrations_glossaire.dart';
import 'recherche_glossaire.dart';
import 'terme_glossaire.dart';
import 'type_terme_glossaire.dart';

/// Builds the complete glossary (ADR-0017, D1): one term per botanical family
/// and per bioaggressor — **derived** from the YAML references, never copied —
/// plus the static notion catalogue (`construireNotions`).
///
/// Pure: no provider, no I/O — callers (the glossary providers / panel) fetch
/// the reference lists and hand them over. The locale comes from
/// [AppLocalizations.localeName], so a term's title follows the app language.
///
/// Guarantees (verified by the integrity test, D6):
///  - ids are unique and prefixed (`famille.` / `bio.` / `outil.` / `notion.`);
///  - families and bioaggressors are sorted alphabetically by localized title
///    (stable rendering), notions keep their catalogue order;
///  - a reference entry without description gets the explicit ARB fallback
///    ([AppLocalizations.glossaireDefinitionAVenir]) — nothing invented.
List<TermeGlossaire> construireGlossaire({
  required AppLocalizations l10n,
  required List<FamilleBotanique> familles,
  required List<Bioagresseur> bioagresseurs,
}) {
  final locale = l10n.localeName;

  final termesFamilles = [
    for (final famille in familles)
      TermeGlossaire(
        id: TermeGlossaire.idFamille(famille.id),
        chapitre: ChapitreGlossaire.famillesBotaniques,
        type: TypeTermeGlossaire.famille,
        titre: famille.nomLocalise(locale),
        definition: famille.descriptionLocalisee(locale) ??
            l10n.glossaireDefinitionAVenir,
        complements: [
          ComplementFamille(
            famille: famille,
            // Referential integrity (ADR-0006 Lot 4) guarantees every slug
            // resolves to a bioaggressor, hence to a glossary term.
            idsMaladies: [
              for (final slug in famille.maladiesCommunes)
                TermeGlossaire.idBioagresseur(slug),
            ],
            idsRavageurs: [
              for (final slug in famille.ravageursCommuns)
                TermeGlossaire.idBioagresseur(slug),
            ],
          ),
        ],
      ),
  ]..sort((a, b) =>
      normaliserRecherche(a.titre).compareTo(normaliserRecherche(b.titre)));

  final termesBioagresseurs = [
    for (final bio in bioagresseurs)
      TermeGlossaire(
        id: TermeGlossaire.idBioagresseur(bio.id),
        chapitre: ChapitreGlossaire.santeDuJardin,
        type: bio.type == TypeBioagresseur.maladie
            ? TypeTermeGlossaire.maladie
            : TypeTermeGlossaire.ravageur,
        titre: bio.nomLocalise(locale),
        definition:
            bio.descriptionLocalisee(locale) ?? l10n.glossaireDefinitionAVenir,
        complements: [
          ComplementBioagresseur(
            bioagresseur: bio,
            // Inverse derivation: every family whose shared diseases/pests
            // reference this bioaggressor.
            idsFamilles: [
              for (final famille in familles)
                if (famille.maladiesCommunes.contains(bio.id) ||
                    famille.ravageursCommuns.contains(bio.id))
                  TermeGlossaire.idFamille(famille.id),
            ],
          ),
        ],
      ),
  ]..sort((a, b) =>
      normaliserRecherche(a.titre).compareTo(normaliserRecherche(b.titre)));

  return List<TermeGlossaire>.unmodifiable([
    for (final terme in [
      ...termesFamilles,
      ...termesBioagresseurs,
      ...construireNotions(l10n),
    ])
      // D4/Lot 5: attach the registered illustration, whatever the source —
      // YAML-derived pages get theirs the day their image lands.
      switch (illustrationDe(terme.id)) {
        null => terme,
        final chemin => terme.avecIllustration(chemin),
      },
  ]);
}

/// Index of [termes] by id, for O(1) resolution (term pages, wiki links,
/// integrity test). Throws [ArgumentError] on a duplicated id — ids must be
/// unique by construction.
Map<String, TermeGlossaire> indexerParId(List<TermeGlossaire> termes) {
  final index = <String, TermeGlossaire>{};
  for (final terme in termes) {
    if (index.containsKey(terme.id)) {
      throw ArgumentError.value(terme.id, 'termes', 'duplicated glossary id');
    }
    index[terme.id] = terme;
  }
  return Map<String, TermeGlossaire>.unmodifiable(index);
}
