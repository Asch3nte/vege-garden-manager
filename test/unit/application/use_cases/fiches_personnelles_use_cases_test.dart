import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/use_cases/creer_fiche_personnelle.dart';
import 'package:pot_a_gerer/application/use_cases/dupliquer_fiche_en_modele.dart';
import 'package:pot_a_gerer/application/use_cases/modifier_fiche_personnelle.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/qualite_sol.dart';
import 'package:pot_a_gerer/domain/enums/sous_type_legume.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/modele_fiche_personnelle.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiche_plante_mapper.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiche_plante_validator.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/serialiseur_fiche_personnelle.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/fiche_plante_personnelle_repository_impl.dart';
import 'package:yaml/yaml.dart';

ModeleFichePersonnelle modele({
  String idFiche = 'perso_tomate',
  String nomCommunFr = 'Tomate',
}) =>
    ModeleFichePersonnelle(
      idFiche: idFiche,
      categorie: CategoriePlante.legume,
      sousType: SousTypeLegume.legumeFruit,
      usages: {UsagePlante.alimentaire, UsagePlante.compagnonnage},
      nomScientifique: 'Solanum lycopersicum',
      familleBotanique: 'solanaceae',
      nomCommunFr: nomCommunFr,
      nomCommunEn: 'Tomato',
      descriptionFr: 'Une bonne tomate.',
      ensoleillement: NiveauSoleil.pleinSoleil,
      arrosage: BesoinEau.modere,
      qualitesSol: {QualiteSol.riche, QualiteSol.bienDraine},
      phMin: 6,
      phMax: 7,
      espacementCm: 40,
      dureeAvantRecolteJoursMin: 60,
      dureeAvantRecolteJoursMax: 90,
      difficulte: 2,
    );

void main() {
  late AppDatabase db;
  late FichePlantePersonnelleRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FichePlantePersonnelleRepositoryImpl(db);
  });
  tearDown(() => db.close());

  group('CreerFichePersonnelle', () {
    test('assigns the storage UUID and creation date', () async {
      final uc = CreerFichePersonnelle(repo,
          genererId: () => 'row-1',
          maintenant: () => DateTime.utc(2026, 7, 1));
      final fiche = await uc.executer(contenu: modele());
      expect(fiche.id, 'row-1');
      expect(fiche.idFiche, 'perso_tomate');
      expect(fiche.dateCreation, DateTime.utc(2026, 7, 1));
      expect(fiche.dateModification, DateTime.utc(2026, 7, 1));
      expect(await repo.obtenirParId('row-1'), isNotNull);
    });

    test('suffixes the logical id on collision with another sheet', () async {
      var n = 0;
      final uc = CreerFichePersonnelle(repo, genererId: () => 'row-${n++}');
      final first = await uc.executer(contenu: modele(idFiche: 'perso_tomate'));
      final second = await uc.executer(contenu: modele(idFiche: 'perso_tomate'));
      expect(first.idFiche, 'perso_tomate');
      expect(second.idFiche, 'perso_tomate_2');
    });
  });

  group('ModifierFichePersonnelle', () {
    test('updates content, preserves idFiche, stamps modification', () async {
      final creer = CreerFichePersonnelle(repo,
          genererId: () => 'row-1',
          maintenant: () => DateTime.utc(2026, 7, 1));
      final origine = await creer.executer(contenu: modele());

      final modifier =
          ModifierFichePersonnelle(repo, maintenant: () => DateTime.utc(2026, 8, 1));
      // The incoming content carries a different idFiche — it must be ignored.
      final maj = await modifier.executer(
        existante: origine,
        contenu: modele(idFiche: 'autre_id', nomCommunFr: 'Tomate cerise'),
      );

      expect(maj.id, 'row-1');
      expect(maj.idFiche, 'perso_tomate'); // preserved
      expect(maj.contenu.nomCommunFr, 'Tomate cerise');
      expect(maj.dateCreation, DateTime.utc(2026, 7, 1)); // unchanged
      expect(maj.dateModification, DateTime.utc(2026, 8, 1));
      // Persisted, still a single row.
      expect((await repo.obtenirToutes()), hasLength(1));
    });
  });

  group('DupliquerFicheEnModele', () {
    test('projects a catalogue sheet onto an editable draft with a fresh id',
        () {
      const serialiseur = SerialiseurFichePersonnelle();
      final map = loadYaml(serialiseur.versYaml(
              modele(idFiche: 'perso_source', nomCommunFr: 'Tomate de mémé')))
          as YamlMap;
      const FichePlanteValidator(validerFormatId: false)
          .valider(map, source: 'test');
      final source = const FichePlanteMapper().versEntite(map);

      final draft = const DupliquerFicheEnModele().executer(source);
      expect(draft.idFiche, 'perso_tomate_de_meme'); // derived from the name
      expect(draft.nomCommunFr, 'Tomate de mémé');
      expect(draft.nomCommunEn, 'Tomato');
      expect(draft.categorie, CategoriePlante.legume);
      expect(draft.sousType, SousTypeLegume.legumeFruit);
      expect(draft.usages,
          {UsagePlante.alimentaire, UsagePlante.compagnonnage});
      expect(draft.qualitesSol, {QualiteSol.riche, QualiteSol.bienDraine});
      expect(draft.phMin, 6);
      expect(draft.espacementCm, 40);
      expect(draft.difficulte, 2);
    });
  });
}
