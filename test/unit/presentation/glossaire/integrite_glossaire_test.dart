import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/l10n/app_localizations_fr.dart';
import 'package:pot_a_gerer/presentation/glossaire/complement_terme.dart';
import 'package:pot_a_gerer/presentation/glossaire/couverture_glossaire.dart';
import 'package:pot_a_gerer/presentation/glossaire/illustrations_glossaire.dart';
import 'package:pot_a_gerer/presentation/glossaire/liens_glossaire.dart';
import 'package:pot_a_gerer/presentation/glossaire/registre_glossaire.dart';
import 'package:pot_a_gerer/presentation/glossaire/terme_glossaire.dart';

/// Glossary integrity test (ADR-0017, D6) — the "coverage is proved" guard:
///
///  1. every enum under `lib/domain/enums/` is **covered or consciously
///     excluded** (the exclusion list is the only escape hatch);
///  2. every covering id resolves to a real glossary term;
///  3. ids are unique, definitions non-empty;
///  4. every wiki link of every static text (definition, conseils, astuce)
///     resolves — never a dead link;
///  5. every `illustration` points to an existing asset file;
///  6. every literal glossary slug used anywhere in `lib/` resolves.
void main() {
  final l10n = AppLocalizationsFr();

  // The static glossary: notion/outil pages only. Family & bioaggressor pages
  // are YAML-derived and validated by `verifier_referentiels`; static texts
  // must therefore never link to `famille.*` / `bio.*` ids.
  final termes = construireGlossaire(
    l10n: l10n,
    familles: const [],
    bioagresseurs: const [],
  );
  final index = indexerParId(termes);

  Set<String> enumsDeclares() {
    final declarations = RegExp(r'^enum (\w+)', multiLine: true);
    final noms = <String>{};
    for (final fichier in Directory('lib/domain/enums')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      for (final m in declarations.allMatches(fichier.readAsStringSync())) {
        noms.add(m.group(1)!);
      }
    }
    return noms;
  }

  group('couverture des enums (D6)', () {
    test('chaque enum métier est couvert ou explicitement exclu', () {
      final declares = enumsDeclares();
      final classes = {...enumsCouverts.keys, ...enumsExclus};
      expect(
        declares.difference(classes),
        isEmpty,
        reason: 'enum(s) sans entrée de glossaire ni exclusion consciente — '
            'ajouter la page (couverture) ou justifier l\'exclusion',
      );
    });

    test('aucun enum classé à la fois couvert et exclu', () {
      expect(
        enumsCouverts.keys.toSet().intersection(enumsExclus),
        isEmpty,
      );
    });

    test('aucune entrée périmée (enum disparu) dans les deux listes', () {
      final declares = enumsDeclares();
      expect(enumsCouverts.keys.toSet().difference(declares), isEmpty,
          reason: 'entrée de couverture sans enum correspondant');
      expect(enumsExclus.difference(declares), isEmpty,
          reason: 'exclusion sans enum correspondant');
    });

    test('chaque id de couverture résout dans le glossaire', () {
      enumsCouverts.forEach((enumName, ids) {
        expect(ids, isNotEmpty, reason: '$enumName couvert sans aucun id');
        for (final id in ids) {
          expect(index, contains(id),
              reason: 'id "$id" (couverture de $enumName) sans terme');
        }
      });
    });
  });

  group('contenu statique (D6)', () {
    test('ids uniques et définitions non vides', () {
      // indexerParId throws on duplicates; assert sizes match for clarity.
      expect(index.length, termes.length);
      for (final terme in termes) {
        expect(terme.definition.trim(), isNotEmpty,
            reason: '${terme.id} sans définition');
      }
    });

    test('chaque lien wiki (définition, conseils, astuce, valeurs) résout', () {
      for (final terme in termes) {
        final textes = [
          terme.definition,
          ...terme.conseils,
          if (terme.astuce != null) terme.astuce!,
          // Enum-value descriptions are rendered with wiki links too (D2).
          for (final bloc in terme.complements.whereType<ComplementValeursEnum>())
            for (final valeur in bloc.valeurs)
              if (valeur.description != null) valeur.description!,
        ];
        for (final texte in textes) {
          for (final id in extraireIdsLiens(texte)) {
            expect(index, contains(id),
                reason: 'lien [[$id]] du terme ${terme.id} sans cible');
          }
        }
      }
    });

    test('chaque illustration pointe un asset existant', () {
      for (final terme in termes) {
        final illustration = terme.illustration;
        if (illustration != null) {
          expect(File(illustration).existsSync(), isTrue,
              reason: 'illustration manquante pour ${terme.id}: $illustration');
        }
      }
    });

    test('chaque id du registre d\'illustrations résout et a son fichier '
        '(D4/Lot 5)', () {
      for (final id in idsIllustres) {
        // YAML-derived pages (famille./bio.) are absent from the static
        // index built here; their resolution is covered by the widget tests
        // and the reference lint.
        if (id.startsWith('notion.') || id.startsWith('outil.')) {
          expect(index, contains(id),
              reason: 'illustration enregistrée pour un terme inconnu: $id');
        }
        expect(File(illustrationDe(id)!).existsSync(), isTrue,
            reason: 'fichier manquant pour l\'illustration $id');
      }
    });
  });

  group('slugs utilisés dans l\'app (D6)', () {
    test('chaque slug littéral idNotion/idOutil du code résout', () {
      final appels =
          RegExp(r"TermeGlossaire\.id(Notion|Outil)\('([a-z0-9-]+)'\)");
      final fichiers = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final fichier in fichiers) {
        for (final m in appels.allMatches(fichier.readAsStringSync())) {
          final id = m.group(1) == 'Notion'
              ? TermeGlossaire.idNotion(m.group(2)!)
              : TermeGlossaire.idOutil(m.group(2)!);
          expect(index, contains(id),
              reason: 'slug "$id" utilisé dans ${fichier.path} sans terme');
        }
      }
    });
  });
}
