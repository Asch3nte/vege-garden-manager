import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/main.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../../test/helpers/faux_services_natifs.dart';

/// Launches the whole app on [base] (in-memory by default) with fake native
/// services, and returns the database for later assertions.
Future<AppDatabase> lancerApp(
  WidgetTester tester, {
  AppDatabase? base,
  FauxNotificationService? notifications,
  FauxGeolocalisationService? geoloc,
  FauxGestionnaireSauvegardeFichier? fichiers,
  List<Override> surcharges = const [],
}) async {
  tzdata.initializeTimeZones();
  final db = base ?? AppDatabase(NativeDatabase.memory());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...surchargesDeTest(
          db,
          notifications: notifications,
          geoloc: geoloc,
          fichiers: fichiers,
        ).where((o) => !surcharges.any((s) => s.origin == o.origin)),
        ...surcharges,
      ],
      child: const PotAGererApp(),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}
