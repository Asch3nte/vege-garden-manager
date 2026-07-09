import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/presentation/providers/tache_detail_provider.dart';

class _MockTaches extends Mock implements AbstractTacheRepository {}

class _MockParcelles extends Mock implements AbstractParcelleRepository {}

void main() {
  late _MockTaches taches;
  late _MockParcelles parcelles;

  setUp(() {
    taches = _MockTaches();
    parcelles = _MockParcelles();
  });

  ProviderContainer conteneur() {
    final c = ProviderContainer(overrides: [
      tacheRepositoryProvider.overrideWithValue(taches),
      parcelleRepositoryProvider.overrideWithValue(parcelles),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Tache uneTache() => Tache(
        id: 't-1',
        titre: 'Arroser',
        type: TypeTache.arrosage,
        cible: CibleTache.parcelle,
        cibleId: 'z-1',
        datePrevue: DateTime(2026, 6, 9),
      );

  test('resolves the parcelle target name', () async {
    when(() => taches.obtenirParId('t-1')).thenAnswer((_) async => uneTache());
    when(() => parcelles.obtenirParId('z-1')).thenAnswer(
      (_) async => Parcelle(
        id: 'z-1',
        nom: 'Carré nord',
        potagerId: 'pot-1',
        type: TypeParcelle.bacSureleve,
        surface: Surface.enMetresCarres(1),
        exposition: NiveauSoleil.pleinSoleil,
      ),
    );

    final vue = await conteneur().read(tacheDetailProvider('t-1').future);

    expect(vue, isNotNull);
    expect(vue!.tache.titre, 'Arroser');
    expect(vue.cibleNom, 'Carré nord');
  });

  test('returns null when the task no longer exists', () async {
    when(() => taches.obtenirParId('gone')).thenAnswer((_) async => null);

    final vue = await conteneur().read(tacheDetailProvider('gone').future);

    expect(vue, isNull);
  });
}
