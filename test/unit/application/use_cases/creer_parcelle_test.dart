import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/application/use_cases/creer_parcelle.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/teinte_zone.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/couleur_zone.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';

class _MockParcelles extends Mock implements AbstractParcelleRepository {}

class _FakeParcelle extends Fake implements Parcelle {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeParcelle()));

  late _MockParcelles parcelles;
  late CreerParcelle useCase;

  Parcelle existante(String id, CouleurZone couleur) => Parcelle(
    id: id,
    nom: id,
    potagerId: 'pot1',
    type: TypeParcelle.bacSureleve,
    surface: Surface.enMetresCarres(1),
    exposition: NiveauSoleil.pleinSoleil,
    couleur: couleur,
  );

  Future<Parcelle> creer({CouleurZone? couleur}) => useCase.executer(
    nom: 'Nouvelle',
    potagerId: 'pot1',
    type: TypeParcelle.pot,
    surface: Surface.enMetresCarres(1),
    exposition: NiveauSoleil.miOmbre,
    couleur: couleur,
  );

  setUp(() {
    parcelles = _MockParcelles();
    useCase = CreerParcelle(parcelles, genererId: () => 'neuve');
    when(() => parcelles.sauvegarder(any())).thenAnswer((_) async {});
  });

  test('a new zone gets the first tint unused in its garden', () async {
    when(() => parcelles.obtenirParPotager('pot1')).thenAnswer(
      (_) async => [
        existante('a', const CouleurZone.teinte(TeinteZone.vertProfond)),
        existante('b', const CouleurZone.teinte(TeinteZone.terracotta)),
      ],
    );

    final p = await creer();

    expect(p.couleur, const CouleurZone.teinte(TeinteZone.aubergine));
    verify(() => parcelles.sauvegarder(p)).called(1);
  });

  test('an explicit colour wins over the automatic one', () async {
    when(() => parcelles.obtenirParPotager('pot1')).thenAnswer((_) async => []);

    final p = await creer(couleur: CouleurZone.personnalisee(0x102030));

    expect(p.couleur, CouleurZone.personnalisee(0x102030));
  });
}
