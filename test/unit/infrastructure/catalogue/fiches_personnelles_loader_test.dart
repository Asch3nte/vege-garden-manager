import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante_personnelle.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/qualite_sol.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/modele_fiche_personnelle.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiche_plante_cache.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiche_plante_mapper.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiche_plante_validator.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiches_personnelles_loader.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/serialiseur_fiche_personnelle.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/fiche_plante_personnelle_repository_impl.dart';
import 'package:yaml/yaml.dart';

ModeleFichePersonnelle modele({
  required String idFiche,
  String nomCommunFr = 'Tomate',
}) =>
    ModeleFichePersonnelle(
      idFiche: idFiche,
      categorie: CategoriePlante.legume,
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

/// Builds a catalogue [FichePlante] straight from a model, through the same
/// pipeline the loader uses.
FichePlante ficheDepuis(ModeleFichePersonnelle m) {
  const s = SerialiseurFichePersonnelle();
  final map = loadYaml(s.versYaml(m)) as YamlMap;
  const FichePlanteValidator(validerFormatId: false)
      .valider(map, source: 'test');
  return const FichePlanteMapper().versEntite(map);
}

void main() {
  late AppDatabase db;
  late FichePlantePersonnelleRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FichePlantePersonnelleRepositoryImpl(db);
  });
  tearDown(() => db.close());

  FichePlantePersonnelle fiche(String id, String idFiche, String nom) =>
      FichePlantePersonnelle(
        id: id,
        contenu: modele(idFiche: idFiche, nomCommunFr: nom),
        dateCreation: DateTime.utc(2026, 5, 1),
      );

  test('loads stored personal sheets as catalogue entities', () async {
    await repo.sauvegarder(fiche('r1', 'perso_a', 'Tomate A'));
    await repo.sauvegarder(fiche('r2', 'perso_b', 'Tomate B'));
    final fiches = await FichesPersonnellesLoader(repo).charger();
    expect(fiches.map((f) => f.id).toSet(), {'perso_a', 'perso_b'});
    expect(
      fiches.firstWhere((f) => f.id == 'perso_a').nomsLocalises['fr'],
      'Tomate A',
    );
  });

  test('skips and reports a corrupt sheet without crashing the load', () async {
    await repo.sauvegarder(fiche('r1', 'perso_ok', 'Bonne'));
    // Tamper: insert a row whose YAML fails validation (missing fields).
    final now = DateTime.utc(2026, 5, 1).toIso8601String();
    await db.into(db.fichesPlantesPersonnelles).insert(
          FichesPlantesPersonnellesCompanion.insert(
            id: 'r2',
            idFiche: 'perso_ko',
            yamlContenu: 'id: perso_ko',
            schemaVersion: 1,
            categorie: 'legume',
            dateCreation: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
    final erreurs = <String>[];
    final fiches = await FichesPersonnellesLoader(
      repo,
      (source, e) => erreurs.add(source),
    ).charger();
    expect(fiches.map((f) => f.id), ['perso_ok']);
    expect(erreurs, hasLength(1));
  });

  test('a personal sheet overrides a built-in one on id collision (ADR-0002 A6)',
      () {
    final builtin = ficheDepuis(modele(idFiche: 'tomate', nomCommunFr: 'Officielle'));
    final perso = ficheDepuis(modele(idFiche: 'tomate', nomCommunFr: 'Ma tomate'));
    // Personal sheets are appended after the built-ins → last wins.
    final cache = FichePlanteCache([builtin, perso]);
    expect(cache.nombre, 1);
    expect(cache.parId('tomate')!.nomsLocalises['fr'], 'Ma tomate');
  });
}
