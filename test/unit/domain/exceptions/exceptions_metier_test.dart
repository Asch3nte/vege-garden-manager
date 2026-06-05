import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/exceptions/association_incompatible_exception.dart';
import 'package:pot_a_gerer/domain/exceptions/fiche_plante_introuvable_exception.dart';
import 'package:pot_a_gerer/domain/exceptions/periode_plantation_invalide_exception.dart';
import 'package:pot_a_gerer/domain/exceptions/potager_exception.dart';
import 'package:pot_a_gerer/domain/exceptions/zone_climatique_incompatible_exception.dart';

void main() {
  group('Domain exceptions', () {
    test('all are typed PotagerException / Exception', () {
      final exceptions = <PotagerException>[
        AssociationIncompatibleException('tomate', 'fenouil'),
        FichePlanteIntrouvableException('inconnue'),
        PeriodePlantationInvalideException('tomate', 1),
        ZoneClimatiqueIncompatibleException('bananier'),
      ];
      for (final e in exceptions) {
        expect(e, isA<Exception>());
        expect(e.message, isNotEmpty);
        expect(e.toString(), contains(e.message));
      }
    });

    test('carry their contextual data', () {
      final assoc = AssociationIncompatibleException('tomate', 'fenouil');
      expect(assoc.plante1Id, 'tomate');
      expect(assoc.plante2Id, 'fenouil');

      expect(FichePlanteIntrouvableException('x').planteId, 'x');

      final periode = PeriodePlantationInvalideException('tomate', 1);
      expect(periode.planteId, 'tomate');
      expect(periode.mois, 1);

      expect(
        ZoneClimatiqueIncompatibleException('bananier').planteId,
        'bananier',
      );
    });
  });
}
