import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/source_localisation.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_emplacement.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';

Potager _potager({List<Parcelle>? parcelles}) => Potager(
      id: 'pot1',
      nom: 'Jardin maison',
      zoneClimatique:
          const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
      dateCreation: DateTime(2026, 3, 1),
      parcelles: parcelles,
    );

Parcelle _parcelle(String id, double surfaceM2, {List<Plantation>? plants}) =>
    Parcelle(
      id: id,
      nom: 'P-$id',
      potagerId: 'pot1',
      type: TypeParcelle.bacSureleve,
      surface: Surface.enMetresCarres(surfaceM2),
      exposition: NiveauSoleil.pleinSoleil,
      plantations: plants,
    );

Plantation _plant(String id, double surfaceM2, {String parcelleId = 'a'}) =>
    Plantation(
      id: id,
      planteId: 'tomate',
      parcelleId: parcelleId,
      dateMiseEnPlace: DateTime(2026, 5, 1),
      methode: MethodeMiseEnPlace.repiquage,
      surfaceOccupee: Surface.enMetresCarres(surfaceM2),
      nombrePieds: 1,
    );

void main() {
  group('Potager — construction & defaults', () {
    test('defaults: jardin emplacement, undefined location, no parcelles', () {
      final p = _potager();
      expect(p.emplacement, TypeEmplacement.jardin);
      expect(p.localisation.source, SourceLocalisation.nonDefinie);
      expect(p.parcelles, isEmpty);
    });

    test('rejects empty id or nom', () {
      expect(
        () => Potager(
          id: '',
          nom: 'X',
          zoneClimatique:
              const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
          dateCreation: DateTime(2026, 1, 1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Potager — surface aggregation', () {
    test('surfaceTotale sums parcelle surfaces', () {
      final p = _potager(parcelles: [_parcelle('a', 3), _parcelle('b', 2)]);
      expect(p.surfaceTotale(), Surface.enMetresCarres(5));
    });

    test('surfaceDisponible sums free surfaces', () {
      final a = _parcelle('a', 3, plants: [_plant('x', 1, parcelleId: 'a')]);
      final p = _potager(parcelles: [a, _parcelle('b', 2)]);
      // a: 3 - 1 = 2 free ; b: 2 free -> 4
      expect(p.surfaceDisponible(), Surface.enMetresCarres(4));
    });
  });

  group('Potager — active plantations across parcelles', () {
    test('collects active plantations from every parcelle', () {
      final a = _parcelle('a', 3, plants: [_plant('x', 1, parcelleId: 'a')]);
      final b = _parcelle('b', 3, plants: [_plant('y', 1, parcelleId: 'b')]);
      final p = _potager(parcelles: [a, b]);
      expect(p.plantationsActives().map((pl) => pl.id), containsAll(['x', 'y']));
    });
  });

  group('Potager — parcelle management', () {
    test('ajouterParcelle requires a matching potagerId', () {
      final p = _potager();
      final foreign = Parcelle(
        id: 'z',
        nom: 'Z',
        potagerId: 'autre',
        type: TypeParcelle.pot,
        surface: Surface.enMetresCarres(1),
        exposition: NiveauSoleil.ombre,
      );
      expect(() => p.ajouterParcelle(foreign), throwsA(isA<AssertionError>()));
    });

    test('add then remove a parcelle', () {
      final p = _potager();
      p.ajouterParcelle(_parcelle('a', 2));
      expect(p.parcelles, hasLength(1));
      p.supprimerParcelle('a');
      expect(p.parcelles, isEmpty);
    });

    test('exposed parcelle list is unmodifiable', () {
      final p = _potager();
      expect(() => p.parcelles.add(_parcelle('a', 1)), throwsUnsupportedError);
    });
  });

  group('Potager — mutators & identity', () {
    test('emplacement and notes can change', () {
      final p = _potager();
      p.modifierEmplacement(TypeEmplacement.balcon);
      p.modifierNotes('plein sud');
      expect(p.emplacement, TypeEmplacement.balcon);
      expect(p.notes, 'plein sud');
    });

    test('equality is by id', () {
      expect(_potager() == (_potager()..renommer('Autre')), isTrue);
    });
  });
}
