import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/favori_repository_impl.dart';

void main() {
  late AppDatabase db;
  late FavoriRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FavoriRepositoryImpl(db);
  });
  tearDown(() => db.close());

  test('starts empty', () async {
    expect(await repo.obtenirIds(), isEmpty);
  });

  test('adding is idempotent', () async {
    await repo.ajouter('tomate');
    await repo.ajouter('tomate');
    await repo.ajouter('basilic');
    expect(await repo.obtenirIds(), {'tomate', 'basilic'});
  });

  test('removing soft-deletes, re-adding restores', () async {
    await repo.ajouter('tomate');
    await repo.retirer('tomate');
    expect(await repo.obtenirIds(), isEmpty);
    final lignes = await db.select(db.favoris).get();
    expect(lignes.single.deletedAt, isNotNull);

    await repo.ajouter('tomate');
    expect(await repo.obtenirIds(), {'tomate'});
  });

  test('removing an unknown id is a no-op', () async {
    await repo.retirer('inconnu');
    expect(await repo.obtenirIds(), isEmpty);
  });
}
