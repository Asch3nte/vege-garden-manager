import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/charge_tuteur.dart';
import 'package:pot_a_gerer/domain/enums/groupe_cultural.dart';
import 'package:pot_a_gerer/domain/enums/hemisphere.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/exceptions/invariant_domaine_exception.dart';
import 'package:pot_a_gerer/domain/value_objects/association_benefique.dart';
import 'package:pot_a_gerer/domain/value_objects/association_conflit.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/periode.dart';
import 'package:pot_a_gerer/domain/value_objects/periodes_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/precedent_cultural.dart';

BesoinsCulture _besoins() => BesoinsCulture(
      eau: BesoinEau.eleve,
      soleil: NiveauSoleil.pleinSoleil,
      phMin: 6.0,
      phMax: 7.0,
    );

FichePlante _fiche({
  String id = 'tomate',
  String? rotationFamille,
  String? parentId,
  Set<UsagePlante>? usages,
  Map<String, String>? noms,
  int espacementCm = 60,
  int dureeMin = 70,
  int dureeMax = 90,
  int? etalementMin,
  int? etalementMax,
  Map<Hemisphere, Map<TypeClimat, PeriodesCulture>>? periodes,
  Set<String>? benefiques,
  Set<String>? negatives,
  Set<String>? repulsifContre,
  Set<String>? piegeA,
  ChargeTuteur? chargeTuteur,
  Set<PrecedentCultural>? precedentsFavorables,
  Set<PrecedentCultural>? precedentsDefavorables,
}) =>
    FichePlante(
      id: id,
      parentId: parentId,
      nomScientifique: 'Solanum lycopersicum',
      familleBotanique: 'Solanaceae',
      rotationFamille: rotationFamille,
      categorie: CategoriePlante.legume,
      usages: usages ?? {UsagePlante.alimentaire},
      nomsLocalises: noms ?? {'fr': 'Tomate', 'en': 'Tomato'},
      besoins: _besoins(),
      espacementCm: espacementCm,
      etalementAdulteCmMin: etalementMin,
      etalementAdulteCmMax: etalementMax,
      dureeAvantRecolteJoursMin: dureeMin,
      dureeAvantRecolteJoursMax: dureeMax,
      periodes: periodes,
      associationsBenefiques: benefiques == null
          ? null
          : [for (final id in benefiques) AssociationBenefique(cibleId: id)],
      associationsNegatives: negatives == null
          ? null
          : [for (final id in negatives) AssociationConflit(cibleId: id)],
      repulsifContre: repulsifContre,
      piegeA: piegeA,
      chargeTuteur: chargeTuteur,
      precedentsFavorables: precedentsFavorables,
      precedentsDefavorables: precedentsDefavorables,
    );

void main() {
  group('FichePlante — construction & invariants', () {
    test('exposes its fields', () {
      final f = _fiche();
      expect(f.id, 'tomate');
      expect(f.categorie, CategoriePlante.legume);
      expect(f.usages, {UsagePlante.alimentaire});
      expect(f.sousType, isNull);
    });

    test('requires at least one usage', () {
      expect(() => _fiche(usages: {}), throwsA(isA<InvariantDomaineException>()));
    });

    test('requires a French name', () {
      expect(
        () => _fiche(noms: {'en': 'Tomato'}),
        throwsA(isA<InvariantDomaineException>()),
      );
    });

    test('rejects invalid spacing or duration range', () {
      expect(() => _fiche(espacementCm: 0), throwsA(isA<InvariantDomaineException>()));
      expect(
        () => _fiche(dureeMin: 90, dureeMax: 70),
        throwsA(isA<InvariantDomaineException>()),
      );
    });

    test('rejects an inverted or non-positive spread', () {
      expect(() => _fiche(etalementMin: 50, etalementMax: 20),
          throwsA(isA<InvariantDomaineException>()));
      expect(() => _fiche(etalementMin: 0, etalementMax: 20),
          throwsA(isA<InvariantDomaineException>()));
      expect(_fiche(etalementMin: 20, etalementMax: 40).etalementAdulteCmMax,
          40);
    });
  });

  group('FichePlante — species/variety hierarchy', () {
    test('a sheet without parentId is a mother sheet', () {
      final f = _fiche();
      expect(f.parentId, isNull);
      expect(f.estMere, isTrue);
      expect(f.estVariete, isFalse);
    });

    test('a sheet with parentId is a variety', () {
      final f = _fiche(id: 'LEG-001-V001', parentId: 'LEG-001');
      expect(f.parentId, 'LEG-001');
      expect(f.estVariete, isTrue);
      expect(f.estMere, isFalse);
    });

    test('a variety cannot be its own parent', () {
      expect(
        () => _fiche(id: 'LEG-001', parentId: 'LEG-001'),
        throwsA(isA<InvariantDomaineException>()),
      );
    });
  });

  group('FichePlante — localized names', () {
    test('returns the requested locale', () {
      expect(_fiche().nomLocalise('en'), 'Tomato');
    });

    test('falls back to French for an unknown locale', () {
      expect(_fiche().nomLocalise('es'), 'Tomate');
    });
  });

  group('FichePlante — planting periods', () {
    final periodes = {
      Hemisphere.nord: {
        TypeClimat.oceanique: const PeriodesCulture(
          plantation: Periode(5, 6),
          recolte: Periode(7, 10),
        ),
      },
    };

    test('plantable inside the plant-out window', () {
      final f = _fiche(periodes: periodes);
      expect(
        f.estPlantableEn(DateTime(2026, 5, 15), Hemisphere.nord,
            TypeClimat.oceanique),
        isTrue,
      );
    });

    test('not plantable outside the window', () {
      final f = _fiche(periodes: periodes);
      expect(
        f.estPlantableEn(DateTime(2026, 8, 1), Hemisphere.nord,
            TypeClimat.oceanique),
        isFalse,
      );
    });

    test('not plantable when no data for the hemisphere/climate', () {
      final f = _fiche(periodes: periodes);
      expect(
        f.estPlantableEn(DateTime(2026, 5, 15), Hemisphere.sud,
            TypeClimat.oceanique),
        isFalse,
      );
      expect(
        f.estPlantableEn(DateTime(2026, 5, 15), Hemisphere.nord,
            TypeClimat.mediterraneen),
        isFalse,
      );
    });
  });

  group('FichePlante — associations & usages', () {
    test('benefits and conflicts are looked up by id', () {
      final f = _fiche(benefiques: {'basilic'}, negatives: {'fenouil'});
      expect(f.sAssocieBienAvec('basilic'), isTrue);
      expect(f.sAssocieBienAvec('fenouil'), isFalse);
      expect(f.entreEnConflitAvec('fenouil'), isTrue);
    });

    test('aUsage checks the usage set', () {
      final f = _fiche(usages: {UsagePlante.alimentaire, UsagePlante.compagnonnage});
      expect(f.aUsage(UsagePlante.compagnonnage), isTrue);
      expect(f.aUsage(UsagePlante.medicinale), isFalse);
    });
  });

  group('FichePlante — défense ciblée & charge tuteur', () {
    test('exposes repels / traps slugs and the support load', () {
      final f = _fiche(
        repulsifContre: {'nematode'},
        piegeA: {'puceron'},
        chargeTuteur: ChargeTuteur.legere,
      );
      expect(f.repousse('nematode'), isTrue);
      expect(f.repousse('puceron'), isFalse);
      expect(f.piege('puceron'), isTrue);
      expect(f.chargeTuteur, ChargeTuteur.legere);
    });

    test('defaults: empty sets, null load, immutable sets', () {
      final f = _fiche();
      expect(f.repulsifContre, isEmpty);
      expect(f.piegeA, isEmpty);
      expect(f.chargeTuteur, isNull);
      expect(() => f.repulsifContre.add('x'), throwsUnsupportedError);
      expect(() => f.piegeA.add('x'), throwsUnsupportedError);
    });
  });

  group('FichePlante — précédents culturaux', () {
    test('carries favorable and unfavorable precedents', () {
      final f = _fiche(
        precedentsFavorables: {
          const PrecedentCultural.groupe(GroupeCultural.legumineuses),
          PrecedentCultural.famille('cucurbitaceae'),
        },
        precedentsDefavorables: {PrecedentCultural.famille('solanaceae')},
      );
      expect(f.precedentsFavorables, hasLength(2));
      expect(f.precedentsFavorables,
          contains(const PrecedentCultural.groupe(GroupeCultural.legumineuses)));
      expect(f.precedentsDefavorables,
          equals({PrecedentCultural.famille('solanaceae')}));
    });

    test('defaults: empty, immutable sets', () {
      final f = _fiche();
      expect(f.precedentsFavorables, isEmpty);
      expect(f.precedentsDefavorables, isEmpty);
      expect(
        () => f.precedentsFavorables.add(PrecedentCultural.famille('x')),
        throwsUnsupportedError,
      );
      expect(
        () => f.precedentsDefavorables.add(PrecedentCultural.famille('x')),
        throwsUnsupportedError,
      );
    });
  });

  group('FichePlante — immutability & identity', () {
    test('exposed collections are unmodifiable', () {
      final f = _fiche();
      expect(() => f.usages.add(UsagePlante.medicinale), throwsUnsupportedError);
      expect(() => f.nomsLocalises['de'] = 'Tomate', throwsUnsupportedError);
    });

    test('equality is by id', () {
      expect(_fiche(id: 'tomate') == _fiche(id: 'tomate'), isTrue);
      expect(_fiche(id: 'tomate') == _fiche(id: 'basilic'), isFalse);
    });
  });

  test('cleFamilleRotation normalizes the rotation family, else the family', () {
    expect(_fiche().cleFamilleRotation, 'solanaceae');
    expect(_fiche(rotationFamille: 'Brassicacées').cleFamilleRotation,
        'brassicacees');
  });
}
