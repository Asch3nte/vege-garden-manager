import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/equipement.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/source_type_sol.dart';
import 'package:pot_a_gerer/domain/enums/statut_plantation.dart';
import 'package:pot_a_gerer/domain/enums/technique_sol.dart';
import 'package:pot_a_gerer/domain/enums/texture_sol.dart';
import 'package:pot_a_gerer/domain/enums/type_equipement.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/exceptions/surface_insuffisante_exception.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';

Parcelle _parcelle({double surfaceM2 = 4}) => Parcelle(
      id: 'par1',
      nom: 'Planche Nord',
      potagerId: 'pot1',
      type: TypeParcelle.bacSureleve,
      surface: Surface.enMetresCarres(surfaceM2),
      exposition: NiveauSoleil.pleinSoleil,
    );

Plantation _plantation(
  String id,
  double surfaceM2, {
  String parcelleId = 'par1',
  bool active = true,
}) =>
    Plantation(
      id: id,
      planteId: 'tomate',
      parcelleId: parcelleId,
      dateMiseEnPlace: DateTime(2026, 5, 1),
      methode: MethodeMiseEnPlace.repiquage,
      surfaceOccupee: Surface.enMetresCarres(surfaceM2),
      nombrePieds: 2,
      statut: active ? StatutPlantation.enCours : StatutPlantation.arrachee,
      dateFinReelle: active ? null : DateTime(2026, 8, 1),
    );

Equipement _equip(String id, {String? parcelleId = 'par1'}) => Equipement(
      id: id,
      nom: 'Oya',
      potagerId: 'pot1',
      parcelleId: parcelleId,
      type: TypeEquipement.oya,
      dateInstallation: DateTime(2026, 4, 1),
    );

void main() {
  group('Parcelle — construction & defaults', () {
    test('starts empty with unknown soil', () {
      final p = _parcelle();
      expect(p.texture, isNull);
      expect(p.textureSource, SourceTypeSol.manuelle);
      expect(p.cultureVerticale, isFalse);
      expect(p.techniquesSol, isEmpty);
      expect(p.plantations, isEmpty);
      expect(p.equipements, isEmpty);
    });

    test('rejects empty id/nom/potagerId and non-positive surface', () {
      expect(
        () => Parcelle(
          id: '',
          nom: 'X',
          potagerId: 'pot1',
          type: TypeParcelle.pot,
          surface: Surface.enMetresCarres(1),
          exposition: NiveauSoleil.ombre,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Parcelle(
          id: 'p',
          nom: 'X',
          potagerId: 'pot1',
          type: TypeParcelle.pot,
          surface: Surface.zero,
          exposition: NiveauSoleil.ombre,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Parcelle — surface accounting', () {
    test('only active plantations occupy surface', () {
      final p = _parcelle(surfaceM2: 4);
      p.ajouterPlantation(_plantation('a', 1.5));
      p.ajouterPlantation(_plantation('b', 1.0, active: false));
      expect(p.surfaceOccupee(), Surface.enMetresCarres(1.5));
      expect(p.surfaceLibre(), Surface.enMetresCarres(2.5));
      expect(p.plantesActuelles(), hasLength(1));
    });

    test('surfaceLibre is clamped at zero', () {
      final p = _parcelle(surfaceM2: 2);
      p.ajouterPlantation(_plantation('a', 2));
      expect(p.surfaceLibre(), Surface.zero);
    });
  });

  group('Parcelle — adding plantations', () {
    test('rejects a plantation that exceeds the free surface', () {
      final p = _parcelle(surfaceM2: 2);
      p.ajouterPlantation(_plantation('a', 1.5));
      expect(
        () => p.ajouterPlantation(_plantation('b', 1.0)),
        throwsA(isA<SurfaceInsuffisanteException>()),
      );
    });

    test('the exception reports required and available surfaces', () {
      final p = _parcelle(surfaceM2: 2);
      p.ajouterPlantation(_plantation('a', 1.5));
      try {
        p.ajouterPlantation(_plantation('b', 1.0));
        fail('expected SurfaceInsuffisanteException');
      } on SurfaceInsuffisanteException catch (e) {
        expect(e.requise, Surface.enMetresCarres(1.0));
        expect(e.disponible, Surface.enMetresCarres(0.5));
      }
    });

    test('a terminated plantation bypasses the surface check', () {
      final p = _parcelle(surfaceM2: 2);
      p.ajouterPlantation(_plantation('a', 2));
      // No room left, but a historical (terminated) plantation can still be added.
      p.ajouterPlantation(_plantation('b', 5, active: false));
      expect(p.plantations, hasLength(2));
    });

    test('rejects a plantation referencing another parcelle', () {
      final p = _parcelle();
      expect(
        () => p.ajouterPlantation(_plantation('a', 1, parcelleId: 'other')),
        throwsA(isA<AssertionError>()),
      );
    });

    test('retirerPlantation removes by id', () {
      final p = _parcelle();
      p.ajouterPlantation(_plantation('a', 1));
      p.retirerPlantation('a');
      expect(p.plantations, isEmpty);
    });
  });

  group('Parcelle — equipment', () {
    test('adds and removes equipment', () {
      final p = _parcelle();
      p.ajouterEquipement(_equip('e1'));
      expect(p.equipements, hasLength(1));
      p.retirerEquipement('e1');
      expect(p.equipements, isEmpty);
    });

    test('rejects equipment referencing another parcelle', () {
      final p = _parcelle();
      expect(
        () => p.ajouterEquipement(_equip('e1', parcelleId: 'other')),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Parcelle — soil & techniques', () {
    test('definirTexture sets texture and source', () {
      final p = _parcelle();
      p.definirTexture(TextureSol.argileux,
          source: SourceTypeSol.deduitDuClimat);
      expect(p.texture, TextureSol.argileux);
      expect(p.textureSource, SourceTypeSol.deduitDuClimat);
    });

    test('techniques can be added and removed', () {
      final p = _parcelle();
      p.ajouterTechnique(TechniqueSol.noDig);
      p.ajouterTechnique(TechniqueSol.hugelkultur);
      expect(p.techniquesSol, {TechniqueSol.noDig, TechniqueSol.hugelkultur});
      p.retirerTechnique(TechniqueSol.noDig);
      expect(p.techniquesSol, {TechniqueSol.hugelkultur});
    });

    test('the exposed technique set is unmodifiable', () {
      final p = _parcelle();
      expect(
        () => p.techniquesSol.add(TechniqueSol.paillage),
        throwsUnsupportedError,
      );
    });

    test('cultureVerticale toggles', () {
      final p = _parcelle();
      p.basculerCultureVerticale();
      expect(p.cultureVerticale, isTrue);
    });
  });

  group('Parcelle — mutators & identity', () {
    test('renommer rejects an empty name', () {
      final p = _parcelle();
      expect(() => p.renommer(''), throwsA(isA<AssertionError>()));
      p.renommer('Planche Sud');
      expect(p.nom, 'Planche Sud');
    });

    test('exposed plantation list is unmodifiable', () {
      final p = _parcelle();
      expect(() => p.plantations.add(_plantation('z', 1)),
          throwsUnsupportedError);
    });

    test('equality is by id (state differences are ignored)', () {
      final a = _parcelle();
      final b = _parcelle()..renommer('Autre nom');
      expect(a, b); // same id 'par1'
    });
  });
}
