// Pure-Dart demo runner for the Pot'à Gérer engine.
//
// Runs the real dependency-injection container against a real (in-memory)
// SQLite database and the real YAML catalogue (read from the filesystem, since
// `rootBundle` is Flutter-only). It seeds a realistic garden via the actual
// use cases, then exercises every engine use case and prints the result.
//
// This is NOT a test: it is a manual "see the engine run on real data" script.
//
// Run it with:  flutter test tool/run_demo.dart
//
// (It goes through the Flutter test toolchain rather than `dart run`, because
// the latter's JIT FFI transformer crashes on drift/sqlite3's native bindings
// on this SDK — `flutter test` compiles them cleanly, as the 390 unit tests do.
// The runnable entrypoint is `tool/run_demo.dart`, which calls [runDemo].)
//
// Weather is fetched live from Open-Meteo when the network is available; when it
// is not, the engine degrades honestly (no alerts, demand-only watering advice)
// and the demo says so rather than failing.
import 'package:drift/native.dart';
import 'package:riverpod/riverpod.dart';

import 'package:pot_a_gerer/application/providers/database_providers.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/use_cases/calculer_besoin_arrosage.dart';
import 'package:pot_a_gerer/application/use_cases/creer_equipement.dart';
import 'package:pot_a_gerer/application/use_cases/creer_parcelle.dart';
import 'package:pot_a_gerer/application/use_cases/creer_plantation.dart';
import 'package:pot_a_gerer/application/use_cases/creer_potager.dart';
import 'package:pot_a_gerer/application/use_cases/detecter_alertes_meteo.dart';
import 'package:pot_a_gerer/application/use_cases/estimer_recolte.dart';
import 'package:pot_a_gerer/application/use_cases/recommander_plantes.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/technique_sol.dart';
import 'package:pot_a_gerer/domain/enums/texture_sol.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_equipement.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/catalogue_loader.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/filesystem_fiche_asset_source.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';

/// Entrypoint for `dart run bin/demo.dart` (works once the SDK FFI bug is fixed;
/// today, use `flutter test tool/run_demo.dart`).
Future<void> main() => runDemo();

/// Runs the full engine demo against an in-memory database and the real YAML
/// catalogue, printing each step. Callable from a Flutter-toolchain entrypoint.
Future<void> runDemo() async {
  final db = AppDatabase(NativeDatabase.memory());

  // The real DI graph, with two bootstrap concerns overridden:
  //  - the database (a platform connection) -> in-memory SQLite;
  //  - the catalogue source (rootBundle is Flutter-only) -> the filesystem.
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      catalogueLoaderProvider.overrideWithValue(
        CatalogueLoader(
          FilesystemFicheAssetSource(),
          (source, erreur) => _print('  ⚠️  fiche ignorée ($source): $erreur'),
        ),
      ),
    ],
  );

  try {
    await _executerDemo(container);
  } finally {
    container.dispose();
    await db.close();
  }
}

Future<void> _executerDemo(ProviderContainer c) async {
  _titre('1. Catalogue YAML (chargé depuis le disque, vrais fichiers)');
  final catalogue = await c.read(fichePlanteRepositoryProvider.future);
  final fiches = await catalogue.obtenirToutes();
  _print('  ${fiches.length} fiche(s) chargée(s) :');
  for (final f in fiches) {
    _print('    • ${f.nomLocalise('fr')} '
        '(${f.id}, ${f.familleBotanique}, eau=${f.besoins.eau.name})');
  }

  // --- Scénario : un potager océanique à Lyon, en juin ----------------------
  final lyon =
      Localisation.manuelle(ville: 'Lyon', latitude: 45.75, longitude: 4.85);
  const zone = ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8);

  _titre('2. Création du potager + parcelle (vraies écritures SQLite)');
  final potager = await c.read(creerPotagerProvider).executer(
        nom: 'Potager de démo',
        zoneClimatique: zone,
        localisation: lyon,
      );
  _print('  Potager « ${potager.nom} » créé (${potager.id}).');

  // A sandy, mulched bed in full sun: light + well-drained + fresh soil.
  final parcelle = await c.read(creerParcelleProvider).executer(
        nom: 'Planche sud',
        potagerId: potager.id,
        type: TypeParcelle.pleineTerre,
        surface: Surface.enMetresCarres(6),
        exposition: NiveauSoleil.pleinSoleil,
        texture: TextureSol.sableux,
        techniquesSol: {TechniqueSol.paillage, TechniqueSol.compostEnTrou},
      );
  _print('  Parcelle « ${parcelle.nom} » : ${parcelle.surface} m², '
      'sol ${parcelle.texture?.name}, '
      'techniques ${parcelle.techniquesSol.map((t) => t.name).join(', ')}.');

  // An oya on the bed: water-retention equipment that lowers watering need.
  await c.read(creerEquipementProvider).executer(
        nom: 'Oya 5L',
        potagerId: potager.id,
        parcelleId: parcelle.id,
        type: TypeEquipement.oya,
        dateInstallation: DateTime.now(),
      );
  _print('  Équipement : Oya installée sur la parcelle.');

  _titre('3. Plantation d\'un pied de tomate (mis en place le 1er mai)');
  final tomate = await c.read(creerPlantationProvider).executer(
        planteId: 'tomate',
        parcelleId: parcelle.id,
        dateMiseEnPlace: DateTime(DateTime.now().year, 5, 1),
        methode: MethodeMiseEnPlace.repiquage,
        surfaceOccupee: Surface.enMetresCarres(0.5),
        nombrePieds: 1,
      );
  _print('  Tomate plantée (${tomate.id}).');

  // --- Engine: harvest estimate ---------------------------------------------
  _titre('4. EstimerRecolte (moteur — dates de culture)');
  final estimation = await (await c.read(estimerRecolteProvider.future))
      .executer(tomate);
  if (estimation == null) {
    _print('  Pas d\'estimation (fiche absente).');
  } else {
    _print('  Récolte estimée entre le ${_d(estimation.dateMin)} '
        'et le ${_d(estimation.dateMax)}.');
  }

  // --- Engine: watering advice ----------------------------------------------
  _titre('5. CalculerBesoinArrosage (moteur — bilan hydrique + météo live)');
  final conseil = await (await c.read(calculerBesoinArrosageProvider.future))
      .executer(plantation: tomate, localisation: lyon);
  if (conseil == null) {
    _print('  Pas de conseil (fiche absente).');
  } else {
    _print('  Urgence : ${conseil.urgence.name} '
        '(indice de besoin ${conseil.indiceBesoin.toStringAsFixed(2)}).');
    _print('  Pluie récente : ${_oui(conseil.pluieRecente)} · '
        'pluie prévue : ${_oui(conseil.pluiePrevue)} · '
        'rétention renforcée (paillage/oya) : '
        '${_oui(conseil.retentionRenforcee)}.');
    if (conseil.joursAvantArrosage != null) {
      _print('  Prochain arrosage dans ~${conseil.joursAvantArrosage} jour(s).');
    }
    if (!conseil.pluieRecente && !conseil.pluiePrevue) {
      _print('  (météo non intégrée — hors ligne ou position absente : '
          'conseil basé sur plante + sol + équipement seuls.)');
    }
  }

  // --- Engine: weather alerts -----------------------------------------------
  _titre('6. DetecterAlertesMeteo (moteur — gel / canicule / forte pluie)');
  final alertes = await c.read(detecterAlertesMeteoProvider).executer(
        localisation: lyon,
        plantationsActives: <Plantation>[tomate],
      );
  if (alertes.isEmpty) {
    _print('  Aucune alerte sur l\'horizon (ou météo indisponible hors ligne).');
  } else {
    for (final a in alertes) {
      _print('  ⚠️  ${a.type.name} le ${_d(a.date)} '
          '(valeur déclenchante : ${a.valeurDeclenchante}).');
    }
  }

  // --- Engine: recommendations ----------------------------------------------
  _titre('7. RecommanderPlantes (moteur — saison + place + sol + asso + rotation)');
  final resultat = await (await c.read(recommanderPlantesProvider.future))
      .executer(
    parcelle: parcelle,
    zoneClimatique: zone,
    localisation: lyon,
  );
  _print('  Saison non vérifiée : ${_oui(resultat.saisonNonVerifiee)} '
      '(tomate déjà en place → exclue des recommandations).');
  if (resultat.recommandations.isEmpty) {
    _print('  Aucune plante recommandée pour cette parcelle aujourd\'hui.');
  } else {
    for (final r in resultat.recommandations) {
      final fiche = fiches.firstWhere((f) => f.id == r.planteId);
      _print('  • ${fiche.nomLocalise('fr')} '
          '— score ${r.score.toStringAsFixed(2)} '
          '— ${r.raisons.map((x) => x.name).join(', ')}');
    }
  }

  _titre('Fin de la démo');
  _print('  Tout est passé par la vraie DI, la vraie base SQLite et le vrai '
      'catalogue YAML.');
}

// --- tiny console helpers ---------------------------------------------------

void _titre(String t) {
  _print('');
  _print('── $t ${'─' * (74 - t.length).clamp(0, 74)}');
}

String _oui(bool b) => b ? 'oui' : 'non';

String _d(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// Indirection so the linter doesn't flag print at every call site; this is a
// console script and printing is the whole point.
void _print(String s) {
  // ignore: avoid_print
  print(s);
}
