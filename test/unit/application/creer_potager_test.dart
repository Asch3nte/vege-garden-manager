import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/application/use_cases/creer_potager.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_emplacement.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';

class MockPotagerRepository extends Mock implements AbstractPotagerRepository {}

void main() {
  const zone = ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8);

  setUpAll(() {
    registerFallbackValue(Potager(
      id: 'fallback',
      nom: 'x',
      zoneClimatique: zone,
      dateCreation: DateTime.utc(2026),
    ));
  });

  late MockPotagerRepository repo;
  late CreerPotager useCase;

  setUp(() {
    repo = MockPotagerRepository();
    when(() => repo.sauvegarder(any())).thenAnswer((_) async {});
    useCase = CreerPotager(repo, genererId: () => 'fixed-id');
  });

  test('generates the id, builds the entity and persists it', () async {
    final potager = await useCase.executer(
      nom: 'Balcon',
      zoneClimatique: zone,
      emplacement: TypeEmplacement.balcon,
      notes: 'plein sud',
    );

    expect(potager.id, 'fixed-id');
    expect(potager.nom, 'Balcon');
    expect(potager.emplacement, TypeEmplacement.balcon);
    expect(potager.notes, 'plein sud');

    final saved = verify(() => repo.sauvegarder(captureAny())).captured.single
        as Potager;
    expect(saved.id, 'fixed-id');
    expect(saved.nom, 'Balcon');
  });
}
