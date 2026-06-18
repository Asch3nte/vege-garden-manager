// Reusable research/scrape tool — drafts a botanical **family** sheet
// (ADR-0006, Lot 4), sibling of `tool/scrap_fiche.dart`.
//
// It reliably auto-fills the family **identity** (id/scientific name, cross-
// checked GBIF × Wikidata) and a **description** (Wikipedia fr/en, CC-BY-SA →
// research input, to be rewritten). The **editorial notes** (`pourquoi_rotation`,
// `ennemis_communs_note`, `associations_note`) and the **bioaggressor slugs**
// (`maladies_communes` / `ravageurs_communs`) have no clean open API, so they
// are emitted as TODO placeholders for human completion — the slugs must point
// to `_referentiels/bioagresseurs.yaml` (checked by tool/verifier_referentiels.dart).
//
// Usage:
//   dart run tool/scrap_famille.dart "Solanaceae" \
//       --cat "legume,fleur" --nom "Solanacées" --wiki-fr Solanaceae --wiki-en Solanaceae
//
// Pure parsing/merge logic is covered by test/tool/scrap_famille_test.dart via a
// fake [ClientHttp]; only the CLI `main` performs real network calls.

import 'dart:io';

import 'package:pot_a_gerer/domain/entities/famille_botanique.dart';

import 'sources_botaniques.dart';

/// A draft family sheet built from the merged sources, plus any cross-check
/// warnings (e.g. family name divergence between the input and GBIF/Wikidata).
class FamilleBrouillon {
  final String id;
  final String nomScientifique;
  final String nomCommunFr;
  final List<String> categories;
  final Map<String, String> descriptions;
  final List<String> sources;
  final List<String> avertissements;

  const FamilleBrouillon({
    required this.id,
    required this.nomScientifique,
    required this.nomCommunFr,
    required this.categories,
    this.descriptions = const {},
    this.sources = const [],
    this.avertissements = const [],
  });

  /// Renders the draft as `famille_schema`-compliant YAML. Identity and
  /// description are filled; editorial notes and bioaggressor slugs are TODO.
  String versYaml() {
    final descFr = descriptions['fr'];
    final descEn = descriptions['en'];
    final b = StringBuffer()
      ..writeln('# Fiche famille générée par tool/scrap_famille.dart — '
          'À COMPLÉTER (ADR-0006 Lot 4).')
      ..writeln('# Description = recherche (Wikipédia, CC-BY-SA) → À RÉÉCRIRE '
          'dans la voix du projet (repo MIT).');
    for (final a in avertissements) {
      b.writeln('# ⚠️ $a');
    }
    b
      ..writeln('id: $id')
      ..writeln('nom_scientifique: $nomScientifique')
      ..writeln('schema_version: 1')
      ..writeln('categories: [${categories.join(', ')}]')
      ..writeln('i18n:')
      ..writeln('  fr:')
      ..writeln('    nom_commun: $nomCommunFr')
      ..writeln('    description: >')
      ..writeln('      ${descFr ?? 'TODO'}')
      ..writeln('    pourquoi_rotation: >')
      ..writeln('      TODO')
      ..writeln('    ennemis_communs_note: >')
      ..writeln('      TODO')
      ..writeln('    associations_note: >')
      ..writeln('      TODO');
    if (descEn != null) {
      b
        ..writeln('  en:')
        ..writeln('    description: >')
        ..writeln('      $descEn');
    }
    b
      ..writeln('# TODO slugs ∈ assets/fiches_plantes/_referentiels/bioagresseurs.yaml')
      ..writeln('maladies_communes: []')
      ..writeln('ravageurs_communs: []')
      ..writeln('delai_retour_annees: # TODO entier')
      ..writeln('sources:');
    for (final s in sources) {
      b.writeln('  - $s');
    }
    return b.toString();
  }
}

/// Orchestrates the sources for a family: queries each with the scientific
/// family name, merges descriptions, and warns on a family-name divergence.
class AgregateurFamille {
  final SourceGbif gbif;
  final List<SourceBotanique> autres;

  const AgregateurFamille({required this.gbif, this.autres = const []});

  Future<FamilleBrouillon> agreger({
    required String nomScientifique,
    required String nomCommunFr,
    required List<String> categories,
    String? titreFr,
    String? titreEn,
  }) async {
    final resultats = <ResultatSource>[];
    final sourcesUrls = <String>[];
    final avertissements = <String>[];

    final r0 = await gbif.interroger(
        terme: nomScientifique,
        nomScientifique: nomScientifique,
        titreFr: titreFr,
        titreEn: titreEn);
    resultats.add(r0);
    sourcesUrls.add(gbif.url);

    for (final s in autres) {
      try {
        resultats.add(await s.interroger(
            terme: nomScientifique,
            nomScientifique: nomScientifique,
            titreFr: titreFr,
            titreEn: titreEn));
        sourcesUrls.add(s.url);
      } on Exception catch (e) {
        avertissements.add('source ${s.nom} indisponible: $e');
      }
    }

    // Cross-check: any reported family should normalize to the requested id.
    final attendu = FamilleBotanique.normaliserCle(nomScientifique);
    for (final r in resultats) {
      final f = r.familleBotanique;
      if (f != null && FamilleBotanique.normaliserCle(f) != attendu) {
        avertissements.add('${r.source} rapporte une famille divergente: "$f"');
      }
    }

    final descriptions = <String, String>{};
    for (final r in resultats) {
      descriptions.addAll(r.descriptions);
    }

    return FamilleBrouillon(
      id: attendu,
      nomScientifique: nomScientifique,
      nomCommunFr: nomCommunFr,
      categories: categories,
      descriptions: descriptions,
      sources: sourcesUrls,
      avertissements: avertissements,
    );
  }
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/scrap_famille.dart "<Nom latin>" '
        '--cat "legume,fleur" --nom "Solanacées" --wiki-fr Solanaceae --wiki-en Solanaceae');
    exitCode = 64;
    return;
  }
  final nomScientifique = args.first;
  String? opt(String cle) {
    final i = args.indexOf('--$cle');
    return (i >= 0 && i + 1 < args.length) ? args[i + 1] : null;
  }

  final categories = (opt('cat') ?? 'legume')
      .split(',')
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty)
      .toList();

  final client = ClientHttpReseau();
  final agregateur = AgregateurFamille(
    gbif: SourceGbif(client),
    autres: [SourceWikidata(client), SourceWikipedia(client)],
  );
  final brouillon = await agregateur.agreger(
    nomScientifique: nomScientifique,
    nomCommunFr: opt('nom') ?? nomScientifique,
    categories: categories,
    titreFr: opt('wiki-fr'),
    titreEn: opt('wiki-en'),
  );
  stdout.write(brouillon.versYaml());
}
