import 'package:drift/drift.dart';
import 'package:pot_a_gerer/domain/enums/etat_tache.dart';
import 'package:pot_a_gerer/domain/enums/statut_plantation.dart';
import 'package:pot_a_gerer/domain/enums/type_recurrence.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';

String _iso(DateTime d) => d.toUtc().toIso8601String();

/// Fills [db] with at least one row in every table except the weather cache,
/// covering every status, task type and recurrence, with creation dates
/// distinct from `updatedAt`.
Future<void> peuplerJeuRiche(
  AppDatabase db, {
  DateTime? horodatage,
  int nbTachesSupplementaires = 0,
}) async {
  final maj = horodatage ?? DateTime.utc(2026, 6, 15, 10, 30, 45);
  final creation = _iso(maj.subtract(const Duration(days: 40)));
  final creeLe = _iso(maj.subtract(const Duration(days: 39, hours: 3)));
  final modifie = _iso(maj);
  final jour = _iso(maj.subtract(const Duration(days: 20))).substring(0, 10);
  final jourPasse = _iso(
    maj.subtract(const Duration(days: 45)),
  ).substring(0, 10);
  final plusTard = _iso(maj.add(const Duration(days: 1)));

  await db.batch((b) {
    b.insertAll(db.potagers, [
      PotagersCompanion.insert(
        id: 'pot-1',
        nom: 'Jardin sud',
        emplacement: const Value('jardin'),
        localisationLatitude: const Value(50.8467),
        localisationLongitude: const Value(4.3525),
        localisationVille: const Value('Bruxelles'),
        localisationSource: const Value('gps'),
        climatType: 'oceanique',
        zoneRusticite: 'zone8',
        climatTempMoyAnnuelle: const Value(10.5),
        climatPluviometrieAnnuelle: const Value(820.25),
        climatSource: const Value('openMeteo'),
        dateCreation: creation,
        notes: const Value('Notes du potager'),
        createdAt: creeLe,
        updatedAt: modifie,
        syncVersion: const Value(3),
      ),
      PotagersCompanion.insert(
        id: 'pot-2',
        nom: 'Balcon',
        emplacement: const Value('balcon'),
        climatType: 'mediterraneen',
        zoneRusticite: 'zone10',
        dateCreation: creation,
        createdAt: creeLe,
        updatedAt: modifie,
      ),
    ]);
    b.insertAll(db.parcelles, [
      ParcellesCompanion.insert(
        id: 'parc-1',
        nom: 'Carré A',
        potagerId: 'pot-1',
        type: 'pleineTerre',
        surfaceValeur: 4.5,
        surfaceUnite: 'm2',
        exposition: 'pleinSoleil',
        longueurCm: const Value(300.0),
        largeurCm: const Value(150.0),
        besoinEau: const Value('moyen'),
        textureSol: const Value('limoneux'),
        phSol: const Value('neutre'),
        textureSolSource: const Value('deduitDeLocalisation'),
        techniquesSol: const Value('["paillage","lasagne"]'),
        cultureVerticale: const Value(true),
        positionOrdre: 0,
        couleurTeinte: const Value('vert'),
        positionX: const Value(10.5),
        positionY: const Value(20.25),
        positionLargeur: const Value(100.0),
        positionHauteur: const Value(60.0),
        positionRotation: const Value(45.5),
        dateCreation: creation,
        notes: const Value('Notes parcelle'),
        createdAt: creeLe,
        updatedAt: modifie,
        syncVersion: const Value(2),
      ),
      ParcellesCompanion.insert(
        id: 'parc-2',
        nom: 'Bac',
        potagerId: 'pot-1',
        type: 'bacSureleve',
        surfaceValeur: 8000.0,
        surfaceUnite: 'cm2',
        exposition: 'miOmbre',
        positionOrdre: 1,
        couleurRgb: const Value(0xFF8844),
        dateCreation: creation,
        createdAt: creeLe,
        updatedAt: modifie,
      ),
      ParcellesCompanion.insert(
        id: 'parc-3',
        nom: 'Pot',
        potagerId: 'pot-2',
        type: 'pot',
        surfaceValeur: 0.2,
        surfaceUnite: 'm2',
        exposition: 'ombre',
        positionOrdre: 0,
        dateCreation: creation,
        createdAt: creeLe,
        updatedAt: modifie,
      ),
    ]);
    var i = 0;
    for (final s in StatutPlantation.values) {
      b.insert(
        db.plantations,
        PlantationsCompanion.insert(
          id: 'plant-${s.name}',
          parcelleId: i.isEven ? 'parc-1' : 'parc-2',
          planteId: 'tomate-$i',
          dateMiseEnPlace: jour,
          methode: 'repiquage',
          surfaceOccupeeValeur: 0.5 + i,
          surfaceOccupeeUnite: const Value('m2'),
          nombrePieds: 2 + i,
          statut: Value(s.name),
          dateFinReelle: s.estTerminal
              ? Value(_iso(maj).substring(0, 10))
              : const Value.absent(),
          raisonFin: s.estTerminal
              ? Value('raison ${s.name}')
              : const Value.absent(),
          notesLibres: Value('libre $i'),
          createdAt: creeLe,
          updatedAt: modifie,
          syncVersion: Value(i + 1),
        ),
      );
      i++;
    }
    b.insertAll(db.recoltes, [
      RecoltesCompanion.insert(
        id: 'rec-1',
        plantationId: 'plant-recoltee',
        dateRecolte: jourPasse,
        quantite: 1.75,
        unite: 'kg',
        qualite: const Value('bonne'),
        destination: const Value('conservation'),
        dateCreation: creation,
        notes: const Value('Belle récolte'),
        createdAt: creeLe,
        updatedAt: modifie,
      ),
      RecoltesCompanion.insert(
        id: 'rec-2',
        plantationId: 'plant-enCours',
        dateRecolte: jourPasse,
        quantite: 12,
        unite: 'piece',
        dateCreation: creation,
        createdAt: creeLe,
        updatedAt: modifie,
      ),
    ]);
    b.insertAll(db.equipements, [
      EquipementsCompanion.insert(
        id: 'equip-1',
        nom: 'Oya',
        potagerId: 'pot-1',
        parcelleId: const Value('parc-1'),
        type: 'oya',
        etat: const Value('use'),
        marqueModele: const Value('Terra 5L'),
        dateInstallation: jour,
        dateRemplacementPrevue: const Value('2027-03-01'),
        dateRetrait: const Value('2027-04-01'),
        dateCreation: creation,
        notes: const Value('Notes équipement'),
        createdAt: creeLe,
        updatedAt: modifie,
      ),
      EquipementsCompanion.insert(
        id: 'equip-2',
        nom: 'Composteur',
        potagerId: 'pot-2',
        type: 'composteur',
        dateInstallation: jour,
        dateCreation: creation,
        createdAt: creeLe,
        updatedAt: modifie,
      ),
    ]);
    var t = 0;
    for (final type in TypeTache.values) {
      final etat = EtatTache.values[t % EtatTache.values.length];
      b.insert(
        db.taches,
        TachesCompanion.insert(
          id: 'tache-${type.name}',
          titre: Value('Tâche ${type.name}'),
          generee: Value(t.isOdd),
          description: Value('Description $t'),
          type: type.name,
          etat: Value(etat.name),
          priorite: const Value('haute'),
          potagerId: const Value('pot-1'),
          datePrevue: plusTard,
          dateRealisation: etat == EtatTache.terminee
              ? Value(modifie)
              : const Value.absent(),
          dureeReelleMinutes: Value(15 + t),
          rappelOrigineId: const Value('rappel-ponctuel'),
          dateCreation: creation,
          notes: Value('Notes tâche $t'),
          createdAt: creeLe,
          updatedAt: modifie,
          syncVersion: Value(t + 1),
        ),
      );
      t++;
    }
    b.insertAll(db.taches, [
      TachesCompanion.insert(
        id: 'tache-parcelle',
        type: 'arrosage',
        parcelleId: const Value('parc-2'),
        datePrevue: plusTard,
        dateCreation: creation,
        createdAt: creeLe,
        updatedAt: modifie,
      ),
      TachesCompanion.insert(
        id: 'tache-plantation',
        type: 'recolte',
        plantationId: const Value('plant-enCours'),
        datePrevue: plusTard,
        dateCreation: creation,
        createdAt: creeLe,
        updatedAt: modifie,
      ),
      TachesCompanion.insert(
        id: 'tache-equipement',
        type: 'entretienEquipement',
        equipementId: const Value('equip-1'),
        datePrevue: plusTard,
        dateCreation: creation,
        createdAt: creeLe,
        updatedAt: modifie,
      ),
    ]);
    for (final r in TypeRecurrence.values) {
      b.insert(
        db.rappels,
        RappelsCompanion.insert(
          id: 'rappel-${r.name}',
          titre: 'Rappel ${r.name}',
          description: Value('Description ${r.name}'),
          typeTacheGeneree: 'arrosage',
          priorite: const Value('urgente'),
          potagerId: const Value('pot-1'),
          dateDebut: jour,
          dateFin: const Value('2027-12-31'),
          typeRecurrence: r.name,
          intervalleJours: r == TypeRecurrence.personnalise
              ? const Value(3)
              : const Value.absent(),
          joursSemaine: r == TypeRecurrence.hebdomadaire
              ? const Value('["lundi","jeudi"]')
              : const Value.absent(),
          jourDuMois: r == TypeRecurrence.mensuel
              ? const Value(31)
              : const Value.absent(),
          etat: const Value('enPause'),
          genererXJoursAvance: const Value(14),
          dateCreation: creation,
          notes: const Value('Notes rappel'),
          createdAt: creeLe,
          updatedAt: modifie,
          syncVersion: const Value(2),
        ),
      );
    }
    b.insertAll(db.observations, [
      ObservationsCompanion.insert(
        id: 'obs-1',
        dateObservation: jourPasse,
        type: 'maladie',
        gravite: const Value('critique'),
        titre: 'Mildiou',
        description: const Value('Taches brunes'),
        plantationId: const Value('plant-enCours'),
        resolu: const Value(true),
        dateResolution: Value(modifie),
        actionsRealisees: const Value('Traitement bio'),
        dateCreation: creation,
        notes: const Value('Notes observation'),
        createdAt: creeLe,
        updatedAt: modifie,
      ),
      ObservationsCompanion.insert(
        id: 'obs-2',
        dateObservation: jourPasse,
        type: 'general',
        titre: 'Général',
        potagerId: const Value('pot-2'),
        dateCreation: creation,
        createdAt: creeLe,
        updatedAt: modifie,
      ),
    ]);
    b.insertAll(db.parametres, [
      ParametresCompanion.insert(
        cle: 'ui.densite',
        valeur: 'compacte',
        type: 'texte',
        description: const Value('Densité'),
        dateCreation: creation,
        dateModification: modifie,
      ),
      ParametresCompanion.insert(
        cle: 'meteo.seuil',
        valeur: '{"gel":-2.5}',
        type: 'json',
        dateCreation: creation,
        dateModification: modifie,
      ),
    ]);
    b.insertAll(db.fichesPlantesPersonnelles, [
      FichesPlantesPersonnellesCompanion.insert(
        id: 'fiche-1',
        idFiche: 'perso-radis',
        yamlContenu: 'id: perso-radis\nnom: "Radis é"\n',
        schemaVersion: 4,
        categorie: 'legume',
        sousType: const Value('racine'),
        usages: const Value('["alimentaire"]'),
        nomCommunFr: const Value('Radis'),
        nomCommunEn: const Value('Radish'),
        familleBotanique: const Value('Brassicaceae'),
        dateCreation: creation,
        createdAt: creeLe,
        updatedAt: modifie,
        syncVersion: const Value(5),
      ),
      FichesPlantesPersonnellesCompanion.insert(
        id: 'fiche-2',
        idFiche: 'perso-menthe',
        yamlContenu: 'id: perso-menthe\n',
        schemaVersion: 4,
        categorie: 'aromatique',
        dateCreation: creation,
        createdAt: creeLe,
        updatedAt: modifie,
      ),
    ]);
    b.insertAll(db.favoris, [
      FavorisCompanion.insert(
        ficheId: 'tomate',
        createdAt: creeLe,
        updatedAt: modifie,
      ),
      FavorisCompanion.insert(
        ficheId: 'perso-radis',
        createdAt: creeLe,
        updatedAt: modifie,
      ),
    ]);
  });

  await (db.update(
    db.preferences,
  )..where((p) => p.id.equals('singleton'))).write(
    PreferencesCompanion(
      langue: const Value('en'),
      theme: const Value('sombre'),
      systemeUnites: const Value('imperial'),
      uniteTemperature: const Value('imperial'),
      uniteLongueur: const Value('imperial'),
      uniteSurface: const Value('metrique'),
      uniteVolume: const Value('imperial'),
      uniteMasse: const Value('metrique'),
      sensSwipe: const Value('inverse'),
      confirmerSuppressions: const Value(false),
      niveauExperience: const Value('expert'),
      modeGeolocalisation: const Value('manuelle'),
      notificationsGlobalesActives: const Value(false),
      syncLocaleActive: const Value(true),
      meteoAutoActive: const Value(false),
      communauteOptIn: const Value(true),
      calendrierLunaireOptIn: const Value(true),
      aideContextuelleActive: const Value(false),
      aideDocCompleteActive: const Value(false),
      notificationsParCategorie: const Value('{"arrosage":false}'),
      ponderationAssociations: const Value('{"fixation":2}'),
      nePasDerangerDebut: const Value('22:00'),
      nePasDerangerFin: const Value('07:30'),
      onboardingTermine: const Value(true),
      schemaVersion: const Value(12),
      derniereModification: Value(modifie),
      potagerActifId: const Value('pot-2'),
    ),
  );

  if (nbTachesSupplementaires > 0) {
    await db.batch((b) {
      b.insertAll(db.taches, [
        for (var n = 0; n < nbTachesSupplementaires; n++)
          TachesCompanion.insert(
            id: 'tache-extra-$n',
            titre: Value('Extra $n'),
            type: TypeTache.values[n % TypeTache.values.length].name,
            parcelleId: const Value('parc-1'),
            datePrevue: _iso(maj.add(Duration(days: n % 365))),
            dateCreation: creation,
            createdAt: creeLe,
            updatedAt: modifie,
          ),
      ]);
    });
  }
}

/// Raw rows of every table except the weather cache, sorted by primary key.
Future<Map<String, List<Map<String, Object?>>>> instantane(
  AppDatabase db,
) async {
  final result = <String, List<Map<String, Object?>>>{};
  for (final table in db.allTables) {
    final nom = table.actualTableName;
    if (nom == 'meteo_cache') continue;
    final cle = table.$primaryKey.map((c) => '"${c.name}"').join(', ');
    final rows = await db
        .customSelect('SELECT * FROM "$nom" ORDER BY $cle')
        .get();
    result[nom] = [for (final r in rows) Map<String, Object?>.of(r.data)];
  }
  return result;
}
