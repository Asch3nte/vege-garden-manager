import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante_personnelle.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/qualite_sol.dart';
import 'package:pot_a_gerer/domain/enums/sous_type_legume.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/modele_fiche_personnelle.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/fiche_plante_personnelle_repository_impl.dart';

ModeleFichePersonnelle contenu({
  String idFiche = 'perso_tomate',
  String nomCommunFr = 'Tomate de mémé',
}) =>
    ModeleFichePersonnelle(
      idFiche: idFiche,
      categorie: CategoriePlante.legume,
      sousType: SousTypeLegume.legumeFruit,
      usages: {UsagePlante.alimentaire},
      nomScientifique: 'Solanum lycopersicum',
      familleBotanique: 'solanaceae',
      nomCommunFr: nomCommunFr,
      ensoleillement: NiveauSoleil.pleinSoleil,
      arrosage: BesoinEau.modere,
      qualitesSol: {QualiteSol.riche},
      phMin: 6,
      phMax: 7,
      espacementCm: 40,
      dureeAvantRecolteJoursMin: 60,
      dureeAvantRecolteJoursMax: 90,
    );

FichePlantePersonnelle fiche({
  String id = 'row1',
  String idFiche = 'perso_tomate',
  String nomCommunFr = 'Tomate de mémé',
  DateTime? dateModification,
}) =>
    FichePlantePersonnelle(
      id: id,
      contenu: contenu(idFiche: idFiche, nomCommunFr: nomCommunFr),
      dateCreation: DateTime.utc(2026, 5, 1),
      dateModification: dateModification,
    );

void main() {
  late AppDatabase db;
  late FichePlantePersonnelleRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FichePlantePersonnelleRepositoryImpl(db);
  });
  tearDown(() => db.close());

  test('round-trips a personal sheet through the YAML source of truth', () async {
    await repo.sauvegarder(fiche());
    final f = (await repo.obtenirParId('row1'))!;
    expect(f.idFiche, 'perso_tomate');
    expect(f.contenu.nomCommunFr, 'Tomate de mémé');
    expect(f.contenu.categorie, CategoriePlante.legume);
    expect(f.contenu.sousType, SousTypeLegume.legumeFruit);
    expect(f.contenu.qualitesSol, {QualiteSol.riche});
    // Dates come back in local time (see `DateIso`) — compare instants.
    expect(f.dateCreation.isAtSameMomentAs(DateTime.utc(2026, 5, 1)), isTrue);
  });

  test('denormalizes columns for querying without parsing YAML', () async {
    await repo.sauvegarder(fiche());
    final row = await db.select(db.fichesPlantesPersonnelles).getSingle();
    expect(row.categorie, 'legume');
    expect(row.sousType, 'legume_fruit');
    expect(row.nomCommunFr, 'Tomate de mémé');
    expect(row.familleBotanique, 'solanaceae');
    expect(row.usages, contains('alimentaire'));
  });

  test('obtenirParIdFiche resolves by the logical id', () async {
    await repo.sauvegarder(fiche());
    expect((await repo.obtenirParIdFiche('perso_tomate'))!.id, 'row1');
    expect(await repo.obtenirParIdFiche('inconnu'), isNull);
  });

  test('sauvegarder upserts an existing sheet', () async {
    await repo.sauvegarder(fiche());
    await repo.sauvegarder(fiche(
        nomCommunFr: 'Tomate cerise',
        dateModification: DateTime.utc(2026, 6, 1)));
    final all = await repo.obtenirToutes();
    expect(all, hasLength(1));
    expect(all.single.contenu.nomCommunFr, 'Tomate cerise');
    expect(
        all.single.dateModification.isAtSameMomentAs(DateTime.utc(2026, 6, 1)),
        isTrue);
  });

  test('obtenirToutes orders by most recently modified first', () async {
    await repo.sauvegarder(fiche(
        id: 'a', idFiche: 'perso_a', dateModification: DateTime.utc(2026, 5, 2)));
    await repo.sauvegarder(fiche(
        id: 'b', idFiche: 'perso_b', dateModification: DateTime.utc(2026, 6, 2)));
    final all = await repo.obtenirToutes();
    expect(all.map((f) => f.id), ['b', 'a']);
  });

  test('supprimer soft-deletes (hidden from reads)', () async {
    await repo.sauvegarder(fiche());
    await repo.supprimer('row1');
    expect(await repo.obtenirParId('row1'), isNull);
    expect(await repo.obtenirToutes(), isEmpty);
    expect(await repo.obtenirParIdFiche('perso_tomate'), isNull);
  });
}
