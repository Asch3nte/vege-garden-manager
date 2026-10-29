// Ratchet over pedagogy gaps: unlinked glossary terms, empty plant-sheet
// sections and sheets without cultivation or harvest advice never regress.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/value_objects/preferences_unites.dart';
import 'package:pot_a_gerer/l10n/app_localizations_fr.dart';
import 'package:pot_a_gerer/presentation/glossaire/liens_glossaire.dart';
import 'package:pot_a_gerer/presentation/glossaire/registre_glossaire.dart';
import 'package:pot_a_gerer/presentation/glossaire/terme_glossaire.dart';
import 'package:yaml/yaml.dart';

const _fichierReference = 'test/fixtures/reference_pedagogie.json';

/// Pedagogical sections of a sheet, all under `i18n.fr` in the schema.
const _sections = [
  'description',
  'conseils_culture',
  'conseils_recolte',
  'erreurs_frequentes',
];

/// Advice fields: a sheet needs at least one of them filled.
const _champsConseil = ['conseils_culture', 'conseils_recolte'];

/// Names, not prose: never scanned for glossary terms.
const _champsNoms = {'nom_commun', 'noms_alternatifs'};

class MesuresPedagogie {
  final int termesNonLies;
  final int sectionsVides;
  final int fichesSansConseil;

  const MesuresPedagogie({
    required this.termesNonLies,
    required this.sectionsVides,
    required this.fichesSansConseil,
  });

  Map<String, int> toJson() => {
    'termesNonLies': termesNonLies,
    'sectionsVides': sectionsVides,
    'fichesSansConseil': fichesSansConseil,
  };

  @override
  String toString() => toJson().toString();
}

bool _vide(Object? valeur) => switch (valeur) {
  null => true,
  final String s => s.trim().isEmpty,
  final Iterable<Object?> l => l.every(_vide),
  _ => false,
};

Map<String, Object?> _fr(Map<Object?, Object?> fiche) {
  final i18n = fiche['i18n'];
  final fr = i18n is Map<Object?, Object?> ? i18n['fr'] : null;
  return fr is Map<Object?, Object?>
      ? Map<String, Object?>.from(fr)
      : <String, Object?>{};
}

/// Sheet with its `i18n.fr` completed from [mere] (a child only declares what
/// differs from its parent).
Map<String, Object?> _frEffectif(
  Map<Object?, Object?> fiche,
  Map<Object?, Object?>? mere,
) => {if (mere != null) ..._fr(mere), ..._fr(fiche)};

/// Free-text values of `i18n.fr` and of every `*_i18n.fr` field.
Iterable<String> _textes(Object? noeud, {bool dansFr = false}) sync* {
  switch (noeud) {
    case final String s when dansFr:
      yield s;
    case final List<Object?> l:
      for (final e in l) {
        yield* _textes(e, dansFr: dansFr);
      }
    case final Map<Object?, Object?> m:
      for (final entree in m.entries) {
        final cle = '${entree.key}';
        if (_champsNoms.contains(cle)) continue;
        if (dansFr) {
          yield* _textes(entree.value, dansFr: true);
        } else if (cle == 'i18n' || cle.endsWith('_i18n')) {
          final fr = entree.value is Map<Object?, Object?>
              ? (entree.value as Map<Object?, Object?>)['fr']
              : null;
          yield* _textes(fr, dansFr: true);
        } else {
          yield* _textes(entree.value);
        }
      }
  }
}

/// Measures pedagogy gaps.
///
/// - `termesNonLies`: whole-word, case-insensitive occurrences of a glossary
///   term title in the ARB `fr` values and in the `*_i18n.fr` texts of the
///   sheets, outside `[[…]]` links and outside the term's own page. An ARB
///   value equal to a term's definition, advice or tip belongs to that
///   term's page; one equal to a title is a label and is skipped.
/// - `sectionsVides`: [_sections] absent or empty, per sheet, once a child
///   sheet is completed from its parent.
/// - `fichesSansConseil`: sheets whose `conseils_culture` and
///   `conseils_recolte` are both absent or empty (after the same completion).
MesuresPedagogie mesurer({
  required List<TermeGlossaire> termes,
  required Map<String, String> arbFr,
  required List<Map<Object?, Object?>> fiches,
}) {
  final parId = {for (final f in fiches) '${f['id']}': f};

  var sectionsVides = 0;
  var fichesSansConseil = 0;
  for (final fiche in fiches) {
    final mere = parId['${fiche['parent_id']}'];
    final fr = _frEffectif(fiche, mere);
    sectionsVides += _sections.where((s) => _vide(fr[s])).length;
    if (_champsConseil.every((c) => _vide(fr[c]))) fichesSansConseil++;
  }

  final titres = termes.map((t) => t.titre.toLowerCase()).toSet();
  final proprietaire = <String, TermeGlossaire>{
    for (final t in termes) ...{
      t.definition: t,
      for (final c in t.conseils) c: t,
      if (t.astuce != null) t.astuce!: t,
    },
  };

  final regles = <String>[for (final t in termes) RegExp.escape(t.titre)]
    ..sort((a, b) => b.length.compareTo(a.length));
  final motif = regles.isEmpty
      ? null
      : RegExp(
          '(?<![\\p{L}\\p{N}])(?:${regles.join('|')})(?![\\p{L}\\p{N}])',
          caseSensitive: false,
          unicode: true,
        );
  final compte = <String, int>{};

  void scanner(String texte, {String? idPage}) {
    if (motif == null) return;
    for (final segment in analyserLiensGlossaire(texte)) {
      if (segment is! SegmentBrut) continue;
      for (final m in motif.allMatches(segment.texte)) {
        final trouve = m.group(0)!.toLowerCase();
        final propre =
            idPage != null &&
            termes.any(
              (t) => t.id == idPage && t.titre.toLowerCase() == trouve,
            );
        if (!propre) compte[trouve] = (compte[trouve] ?? 0) + 1;
      }
    }
  }

  for (final entree in arbFr.entries) {
    if (entree.key.startsWith('@')) continue;
    if (titres.contains(entree.value.toLowerCase())) continue;
    scanner(entree.value, idPage: proprietaire[entree.value]?.id);
  }
  for (final fiche in fiches) {
    _textes(fiche).forEach(scanner);
  }

  return MesuresPedagogie(
    termesNonLies: compte.values.fold(0, (a, b) => a + b),
    sectionsVides: sectionsVides,
    fichesSansConseil: fichesSansConseil,
  );
}

void main() {
  test('pedagogy metrics never regress', () {
    final termes = construireGlossaire(
      l10n: AppLocalizationsFr(),
      familles: const [],
      bioagresseurs: const [],
      unites: const PreferencesUnites(),
    );
    final arb =
        (jsonDecode(File('lib/l10n/app_fr.arb').readAsStringSync())
                as Map<String, dynamic>)
            .entries
            .where((e) => e.value is String)
            .map((e) => MapEntry(e.key, e.value as String));
    final fiches = <Map<Object?, Object?>>[
      for (final fichier
          in Directory('assets/fiches_plantes')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.yaml'))
              .where((f) => !f.path.contains('/_')))
        loadYaml(fichier.readAsStringSync()) as Map<Object?, Object?>,
    ];

    final mesures = mesurer(
      termes: termes,
      arbFr: Map.fromEntries(arb),
      fiches: fiches,
    );
    // ignore: avoid_print
    print('pedagogy measures: $mesures');

    if (Platform.environment['MAJ_REFERENCE'] == '1') {
      File(_fichierReference).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(mesures.toJson())}\n',
      );
    }
    final reference =
        (jsonDecode(File(_fichierReference).readAsStringSync())
                as Map<String, dynamic>)
            .cast<String, int>();

    mesures.toJson().forEach((nom, valeur) {
      expect(
        valeur,
        lessThanOrEqualTo(reference[nom]!),
        reason: '$nom regressed',
      );
      if (valeur < reference[nom]!) {
        // ignore: avoid_print
        print('$nom: $valeur < ${reference[nom]}, lower the reference.');
      }
    });
  });
}
