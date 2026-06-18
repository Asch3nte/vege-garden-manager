// CI-able lint for the catalogue reference data (ADR-0006, Lot 4).
//
// Pure Dart (`dart run`, no Flutter): it reads the YAML directly with dart:io +
// package:yaml, then **reuses the pure validators/mappers/verifiers** from the
// app (no logic duplicated). It checks:
//   • each family sheet parses, validates and maps cleanly;
//   • the bioaggressor reference parses/validates/maps cleanly;
//   • every family `maladies_communes`/`ravageurs_communs` slug resolves to a
//     coherent reference entry (VerificateurIntegriteBioagresseurs);
// and *warns* (non-fatal) on editorial gaps: families without the Lot 4 notes,
// bioaggressors without a description or an EPPO code.
//
// The species ⟷ family integrity is intentionally left to the test suite
// (familles_reel_test.dart), which resolves species/variety inheritance.
//
// Usage:
//   dart run tool/verifier_referentiels.dart [--strict]
// Exit code 0 when no error (1 otherwise; with --strict, warnings also fail).

import 'dart:io';

import 'package:pot_a_gerer/domain/entities/bioagresseur.dart';
import 'package:pot_a_gerer/domain/entities/famille_botanique.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/bioagresseur_cache.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/bioagresseur_mapper.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/bioagresseur_validator.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/famille_botanique_mapper.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/famille_botanique_validator.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/verificateur_integrite_bioagresseurs.dart';
import 'package:yaml/yaml.dart';

/// Outcome of a reference-data check: fatal [erreurs] and non-fatal
/// [avertissements] (editorial gaps).
class RapportReferentiels {
  final List<String> erreurs;
  final List<String> avertissements;

  const RapportReferentiels(this.erreurs, this.avertissements);

  /// True when no fatal error was found.
  bool get ok => erreurs.isEmpty;
}

/// Reads and checks the family sheets and the bioaggressor reference, reusing
/// the app's pure validators/mappers/verifier. Pure (filesystem-only), so it is
/// unit-testable against either the real assets or a fixture directory.
Future<RapportReferentiels> verifierReferentiels({
  String famillesDir = 'assets/fiches_plantes/_familles',
  String bioagresseursFichier =
      'assets/fiches_plantes/_referentiels/bioagresseurs.yaml',
}) async {
  final erreurs = <String>[];
  final avertissements = <String>[];

  // 1. Families.
  const valFamille = FamilleBotaniqueValidator();
  const mapFamille = FamilleBotaniqueMapper();
  final familles = <FamilleBotanique>[];
  final dir = Directory(famillesDir);
  for (final f in dir.existsSync()
      ? dir.listSync().whereType<File>().where((f) =>
          f.path.endsWith('.yaml') &&
          !f.path.endsWith('familles_registry.yaml'))
      : <File>[]) {
    try {
      final doc = loadYaml(f.readAsStringSync());
      if (doc is! Map) throw 'the root must be a mapping';
      valFamille.valider(doc, source: f.path);
      final famille = mapFamille.versEntite(doc);
      familles.add(famille);
      // Editorial gaps (warnings).
      if (famille.pourquoiRotation('fr') == null) {
        avertissements.add('${famille.id}: pas de pourquoi_rotation (fr)');
      }
      if (famille.ennemisCommunsNote('fr') == null) {
        avertissements.add('${famille.id}: pas de ennemis_communs_note (fr)');
      }
      if (famille.associationsNote('fr') == null) {
        avertissements.add('${famille.id}: pas de associations_note (fr)');
      }
    } catch (e) {
      erreurs.add('${f.path}: $e');
    }
  }

  // 2. Bioaggressor reference.
  const valBio = BioagresseurValidator();
  const mapBio = BioagresseurMapper();
  final bioagresseurs = <Bioagresseur>[];
  try {
    final doc = loadYaml(File(bioagresseursFichier).readAsStringSync());
    if (doc is! Map || doc['bioagresseurs'] is! Map) {
      throw 'missing "bioagresseurs" mapping';
    }
    for (final e in (doc['bioagresseurs'] as Map).entries) {
      final slug = e.key.toString();
      try {
        final entry = e.value;
        if (entry is! Map) throw 'entry must be a mapping';
        valBio.valider(slug, entry, source: slug);
        final bio = mapBio.versEntite(slug, entry);
        bioagresseurs.add(bio);
        if (bio.descriptionLocalisee('fr') == null) {
          avertissements.add('bioagresseur $slug: pas de description (fr)');
        }
        if (bio.codeEppo == null) {
          avertissements.add('bioagresseur $slug: pas de code_eppo');
        }
      } catch (err) {
        erreurs.add('$bioagresseursFichier ($slug): $err');
      }
    }
  } catch (e) {
    erreurs.add('$bioagresseursFichier: $e');
  }

  // 3. Referential integrity: family slugs ⟶ reference.
  final problemes = const VerificateurIntegriteBioagresseurs()
      .verifier(familles, BioagresseurCache(bioagresseurs));
  erreurs.addAll(problemes.map((p) => p.toString()));

  return RapportReferentiels(erreurs, avertissements);
}

Future<void> main(List<String> args) async {
  final strict = args.contains('--strict');
  final rapport = await verifierReferentiels();

  for (final a in rapport.avertissements) {
    stdout.writeln('⚠️  $a');
  }
  for (final e in rapport.erreurs) {
    stderr.writeln('❌ $e');
  }

  final nbErr = rapport.erreurs.length;
  final nbWarn = rapport.avertissements.length;
  stdout.writeln('— $nbErr erreur(s), $nbWarn avertissement(s).');

  if (!rapport.ok || (strict && nbWarn > 0)) {
    exitCode = 1;
  }
}
