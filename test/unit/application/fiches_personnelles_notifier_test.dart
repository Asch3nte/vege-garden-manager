import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/providers/database_providers.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/fiches_personnelles_notifier.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/qualite_sol.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/modele_fiche_personnelle.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:riverpod/riverpod.dart';

ModeleFichePersonnelle modele({
  String idFiche = 'perso_tomate',
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

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() {
      container.dispose();
      db.close();
    });
  });

  FichesPersonnellesNotifier notifier() =>
      container.read(fichesPersonnellesProvider.notifier);

  test('creer adds the sheet and surfaces it to the catalogue', () async {
    await container.read(fichesPersonnellesProvider.future); // initial build
    final fiche = await notifier().creer(modele());

    final liste = await container.read(fichesPersonnellesProvider.future);
    expect(liste.map((f) => f.id), [fiche.id]);

    // The catalogue-facing load reflects the new sheet after invalidation.
    final ids = await container.read(idsFichesPersonnellesProvider.future);
    expect(ids, {'perso_tomate'});
  });

  test('modifier updates the content in the list and the catalogue', () async {
    final origine = await notifier().creer(modele());
    await notifier().modifier(
      existante: origine,
      contenu: modele(nomCommunFr: 'Tomate cerise'),
    );

    final liste = await container.read(fichesPersonnellesProvider.future);
    expect(liste.single.contenu.nomCommunFr, 'Tomate cerise');
    // idFiche stayed stable → still one entry in the catalogue.
    final ids = await container.read(idsFichesPersonnellesProvider.future);
    expect(ids, {'perso_tomate'});
  });

  test('supprimer removes the sheet from the list and the catalogue', () async {
    final fiche = await notifier().creer(modele());
    await notifier().supprimer(fiche.id);

    expect(await container.read(fichesPersonnellesProvider.future), isEmpty);
    expect(await container.read(idsFichesPersonnellesProvider.future), isEmpty);
  });
}
