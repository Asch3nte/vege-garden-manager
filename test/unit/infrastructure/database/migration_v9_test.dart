import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';

void main() {
  test('v8 → v9 creates the empty favourites table', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) => raw.execute('PRAGMA user_version = 8'),
      ),
    );
    addTearDown(db.close);

    expect(await db.select(db.favoris).get(), isEmpty);
  });
}
