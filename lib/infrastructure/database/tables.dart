import 'package:drift/drift.dart';

// Référence logique : docs/06-modele-de-donnees-sqlite.md.
// Conventions : id TEXT (UUID), dates en TEXT ISO 8601 UTC, enums en TEXT + CHECK,
// booléens via boolean() (INTEGER 0/1), FK en ON DELETE RESTRICT (cascade logique
// côté repositories). Les valeurs d'enum sont en camelCase (= noms Dart).

@DataClassName('PotagerRow')
class Potagers extends Table {
  TextColumn get id => text()();
  TextColumn get nom => text()();
  TextColumn get emplacement => text().withDefault(const Constant('jardin'))();
  RealColumn get localisationLatitude => real().nullable()();
  RealColumn get localisationLongitude => real().nullable()();
  TextColumn get localisationVille => text().nullable()();
  TextColumn get localisationSource =>
      text().withDefault(const Constant('nonDefinie'))();
  TextColumn get climatType => text()();
  TextColumn get zoneRusticite => text()();
  RealColumn get climatTempMoyAnnuelle => real().nullable()();
  RealColumn get climatPluviometrieAnnuelle => real().nullable()();
  TextColumn get climatSource =>
      text().withDefault(const Constant('manuelle'))();
  TextColumn get dateCreation => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'CHECK (localisation_latitude IS NULL OR (localisation_latitude BETWEEN -90 AND 90))',
        'CHECK (localisation_longitude IS NULL OR (localisation_longitude BETWEEN -180 AND 180))',
        "CHECK (emplacement IN ('jardin','balcon','terrasse','toit','cour','interieur','autre'))",
        "CHECK (localisation_source IN ('nonDefinie','manuelle','gps'))",
        "CHECK ((localisation_source = 'nonDefinie') = (localisation_latitude IS NULL AND localisation_longitude IS NULL))",
        "CHECK (climat_type IN ('tropical','subtropical','aride','semiAride','mediterraneen','oceanique','continental','montagnard','polaire'))",
        "CHECK (zone_rusticite IN ('zone1','zone2','zone3','zone4','zone5','zone6','zone7','zone8','zone9','zone10','zone11','zone12','zone13'))",
        "CHECK (climat_source IN ('manuelle','deduitDeLocalisation','openMeteo'))",
      ];
}

@DataClassName('ParcelleRow')
class Parcelles extends Table {
  TextColumn get id => text()();
  TextColumn get nom => text()();
  TextColumn get potagerId => text()();
  TextColumn get type => text()();
  RealColumn get surfaceValeur => real()();
  TextColumn get surfaceUnite => text()();
  TextColumn get exposition => text()();
  TextColumn get textureSol => text().nullable()();
  TextColumn get phSol => text().nullable()();
  TextColumn get textureSolSource =>
      text().withDefault(const Constant('manuelle'))();
  TextColumn get techniquesSol => text().nullable()(); // JSON
  BoolColumn get cultureVerticale =>
      boolean().withDefault(const Constant(false))();
  IntColumn get positionOrdre => integer()();
  RealColumn get positionX => real().nullable()();
  RealColumn get positionY => real().nullable()();
  RealColumn get positionLargeur => real().nullable()();
  RealColumn get positionHauteur => real().nullable()();
  RealColumn get positionRotation => real().nullable()();
  TextColumn get dateCreation => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (potager_id) REFERENCES potagers (id) ON DELETE RESTRICT',
        'CHECK (surface_valeur > 0)',
        "CHECK (surface_unite IN ('m2','cm2'))",
        "CHECK (exposition IN ('pleinSoleil','miOmbre','ombre'))",
        "CHECK (type IN ('pleineTerre','bacSureleve','jardiniere','pot','serre','butte','autre'))",
        "CHECK (texture_sol IS NULL OR texture_sol IN ('argileux','sableux','limoneux','calcaire','humifere','tourbeux','caillouteux'))",
        "CHECK (ph_sol IS NULL OR ph_sol IN ('acide','neutre','alcalin'))",
        "CHECK (texture_sol_source IN ('manuelle','deduitDeLocalisation','deduitDuClimat'))",
        'CHECK (position_x IS NULL OR position_x >= 0)',
        'CHECK (position_y IS NULL OR position_y >= 0)',
        'CHECK (position_rotation IS NULL OR (position_rotation >= 0 AND position_rotation < 360))',
      ];
}

@DataClassName('PlantationRow')
class Plantations extends Table {
  TextColumn get id => text()();
  TextColumn get parcelleId => text()();
  TextColumn get planteId => text()(); // réf. fiche YAML (pas de FK SQL)
  TextColumn get dateMiseEnPlace => text()();
  TextColumn get methode => text()();
  RealColumn get surfaceOccupeeValeur => real()();
  TextColumn get surfaceOccupeeUnite =>
      text().withDefault(const Constant('m2'))();
  IntColumn get nombrePieds => integer()();
  TextColumn get statut => text().withDefault(const Constant('enCours'))();
  TextColumn get dateFinReelle => text().nullable()();
  TextColumn get raisonFin => text().nullable()();
  TextColumn get notesLibres => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (parcelle_id) REFERENCES parcelles (id) ON DELETE RESTRICT',
        'CHECK (nombre_pieds > 0)',
        'CHECK (surface_occupee_valeur > 0)',
        "CHECK (surface_occupee_unite IN ('m2','cm2'))",
        "CHECK (methode IN ('semisDirect','semisInterieur','repiquage','plantAchete','bouture','division'))",
        "CHECK (statut IN ('enCours','recoltee','echouee','arrachee'))",
        "CHECK ((statut = 'enCours' AND date_fin_reelle IS NULL) OR (statut IN ('recoltee','echouee','arrachee') AND date_fin_reelle IS NOT NULL))",
        'CHECK (date_fin_reelle IS NULL OR date_fin_reelle >= date_mise_en_place)',
      ];
}

@DataClassName('RecolteRow')
class Recoltes extends Table {
  TextColumn get id => text()();
  TextColumn get plantationId => text()();
  TextColumn get dateRecolte => text()();
  RealColumn get quantite => real()();
  TextColumn get unite => text()();
  TextColumn get qualite => text().nullable()();
  TextColumn get destination =>
      text().withDefault(const Constant('consommationFraiche'))();
  TextColumn get dateCreation => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (plantation_id) REFERENCES plantations (id) ON DELETE RESTRICT',
        "CHECK (unite IN ('g','kg','piece','botte','litre','ml'))",
        "CHECK (qualite IS NULL OR qualite IN ('excellente','bonne','moyenne','mediocre'))",
        "CHECK (destination IN ('consommationFraiche','conservation','don','semences','compost','autre'))",
        'CHECK (quantite > 0)',
        'CHECK (date_recolte <= date_creation)',
      ];
}

@DataClassName('EquipementRow')
class Equipements extends Table {
  TextColumn get id => text()();
  TextColumn get nom => text()();
  TextColumn get potagerId => text()();
  TextColumn get parcelleId => text().nullable()();
  TextColumn get type => text()();
  TextColumn get etat => text().withDefault(const Constant('bon'))();
  TextColumn get marqueModele => text().nullable()();
  TextColumn get dateInstallation => text()();
  TextColumn get dateRemplacementPrevue => text().nullable()();
  TextColumn get dateRetrait => text().nullable()();
  TextColumn get dateCreation => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (potager_id) REFERENCES potagers (id) ON DELETE RESTRICT',
        'FOREIGN KEY (parcelle_id) REFERENCES parcelles (id) ON DELETE RESTRICT',
        "CHECK (type IN ('oya','gouttesAGoutte','tuteur','treillis','tunnel','serreSemis','chassis','cloche','voileHivernage','filetAntiInsecte','hotelInsectes','composteur','recuperateurEau','autre'))",
        "CHECK (etat IN ('neuf','bon','use','aRemplacer','horsService'))",
      ];
}

@DataClassName('TacheRow')
class Taches extends Table {
  TextColumn get id => text()();
  TextColumn get titre => text()();
  TextColumn get description => text().nullable()();
  TextColumn get type => text()();
  TextColumn get etat => text().withDefault(const Constant('aFaire'))();
  TextColumn get priorite => text().withDefault(const Constant('normale'))();
  TextColumn get potagerId => text().nullable()();
  TextColumn get parcelleId => text().nullable()();
  TextColumn get plantationId => text().nullable()();
  TextColumn get equipementId => text().nullable()();
  TextColumn get datePrevue => text()();
  TextColumn get dateRealisation => text().nullable()();
  IntColumn get dureeReelleMinutes => integer().nullable()();
  TextColumn get rappelOrigineId => text().nullable()();
  TextColumn get dateCreation => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (potager_id) REFERENCES potagers (id) ON DELETE RESTRICT',
        'FOREIGN KEY (parcelle_id) REFERENCES parcelles (id) ON DELETE RESTRICT',
        'FOREIGN KEY (plantation_id) REFERENCES plantations (id) ON DELETE RESTRICT',
        'FOREIGN KEY (equipement_id) REFERENCES equipements (id) ON DELETE RESTRICT',
        'CHECK ((CASE WHEN potager_id IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN parcelle_id IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN plantation_id IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN equipement_id IS NOT NULL THEN 1 ELSE 0 END) = 1)',
        "CHECK (etat IN ('aFaire','enCours','terminee','annulee'))",
        "CHECK (priorite IN ('basse','normale','haute','urgente'))",
        'CHECK (duree_reelle_minutes IS NULL OR duree_reelle_minutes > 0)',
        "CHECK ((etat = 'terminee' AND date_realisation IS NOT NULL) OR (etat != 'terminee'))",
        "CHECK (type IN ('arrosage','desherbage','paillage','taille','tuteurage','fertilisation','traitementBio','observation','semis','repiquage','recolte','preparationSol','installationEquipement','entretienEquipement','nettoyage','autre'))",
      ];
}

@DataClassName('RappelRow')
class Rappels extends Table {
  TextColumn get id => text()();
  TextColumn get titre => text()();
  TextColumn get description => text().nullable()();
  TextColumn get typeTacheGeneree => text()();
  TextColumn get priorite => text().withDefault(const Constant('normale'))();
  TextColumn get potagerId => text().nullable()();
  TextColumn get parcelleId => text().nullable()();
  TextColumn get plantationId => text().nullable()();
  TextColumn get equipementId => text().nullable()();
  TextColumn get dateDebut => text()();
  TextColumn get dateFin => text().nullable()();
  TextColumn get typeRecurrence => text()();
  IntColumn get intervalleJours => integer().nullable()();
  TextColumn get joursSemaine => text().nullable()(); // JSON
  IntColumn get jourDuMois => integer().nullable()();
  TextColumn get etat => text().withDefault(const Constant('actif'))();
  IntColumn get genererXJoursAvance =>
      integer().withDefault(const Constant(7))();
  TextColumn get dateCreation => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (potager_id) REFERENCES potagers (id) ON DELETE RESTRICT',
        'FOREIGN KEY (parcelle_id) REFERENCES parcelles (id) ON DELETE RESTRICT',
        'FOREIGN KEY (plantation_id) REFERENCES plantations (id) ON DELETE RESTRICT',
        'FOREIGN KEY (equipement_id) REFERENCES equipements (id) ON DELETE RESTRICT',
        'CHECK ((CASE WHEN potager_id IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN parcelle_id IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN plantation_id IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN equipement_id IS NOT NULL THEN 1 ELSE 0 END) = 1)',
        "CHECK (type_recurrence IN ('ponctuel','quotidien','hebdomadaire','mensuel','personnalise'))",
        "CHECK (etat IN ('actif','enPause','termine'))",
        "CHECK ((type_recurrence = 'personnalise' AND intervalle_jours IS NOT NULL AND intervalle_jours > 0) OR (type_recurrence = 'hebdomadaire' AND jours_semaine IS NOT NULL AND jours_semaine != '[]') OR (type_recurrence = 'mensuel' AND jour_du_mois IS NOT NULL AND jour_du_mois BETWEEN 1 AND 31) OR (type_recurrence IN ('ponctuel','quotidien')))",
        'CHECK (date_fin IS NULL OR date_fin >= date_debut)',
        'CHECK (generer_x_jours_avance BETWEEN 0 AND 365)',
      ];
}

@DataClassName('ObservationRow')
class Observations extends Table {
  TextColumn get id => text()();
  TextColumn get dateObservation => text()();
  TextColumn get type => text()();
  TextColumn get gravite => text().withDefault(const Constant('info'))();
  TextColumn get titre => text()();
  TextColumn get description => text().nullable()();
  TextColumn get potagerId => text().nullable()();
  TextColumn get parcelleId => text().nullable()();
  TextColumn get plantationId => text().nullable()();
  BoolColumn get resolu => boolean().withDefault(const Constant(false))();
  TextColumn get dateResolution => text().nullable()();
  TextColumn get actionsRealisees => text().nullable()();
  TextColumn get dateCreation => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (potager_id) REFERENCES potagers (id) ON DELETE RESTRICT',
        'FOREIGN KEY (parcelle_id) REFERENCES parcelles (id) ON DELETE RESTRICT',
        'FOREIGN KEY (plantation_id) REFERENCES plantations (id) ON DELETE RESTRICT',
        "CHECK (type IN ('maladie','ravageur','carence','meteo','croissance','floraison','fructification','general','autre'))",
        "CHECK (gravite IN ('info','faible','modere','eleve','critique'))",
        'CHECK ((CASE WHEN potager_id IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN parcelle_id IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN plantation_id IS NOT NULL THEN 1 ELSE 0 END) = 1)',
        '''CHECK ((resolu = 0 AND date_resolution IS NULL) OR (resolu = 1 AND date_resolution IS NOT NULL))''',
        'CHECK (date_observation <= date_creation)',
      ];
}

@DataClassName('MeteoCacheRow')
class MeteoCache extends Table {
  TextColumn get id => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get date => text()(); // YYYY-MM-DD
  TextColumn get type => text()();
  RealColumn get tempMin => real().nullable()();
  RealColumn get tempMax => real().nullable()();
  RealColumn get tempMoyenne => real().nullable()();
  RealColumn get precipitationsMm => real().nullable()();
  RealColumn get probabilitePluie => real().nullable()(); // forecast, 0..1
  RealColumn get evapotranspirationMm => real().nullable()(); // ET₀ FAO-56, mm/day
  IntColumn get heuresEnsoleillement => integer().nullable()();
  RealColumn get ventVitesseMax => real().nullable()();
  IntColumn get ventDirection => integer().nullable()();
  BoolColumn get risqueGel => boolean().withDefault(const Constant(false))();
  BoolColumn get risqueCanicule =>
      boolean().withDefault(const Constant(false))();
  TextColumn get dateRecuperation => text()();
  TextColumn get sourceApi =>
      text().withDefault(const Constant('open-meteo'))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        "CHECK (type IN ('observe','prevu'))",
        'CHECK (latitude BETWEEN -90 AND 90)',
        'CHECK (longitude BETWEEN -180 AND 180)',
        'CHECK (vent_direction IS NULL OR vent_direction BETWEEN 0 AND 360)',
        'CHECK (precipitations_mm IS NULL OR precipitations_mm >= 0)',
        'CHECK (probabilite_pluie IS NULL OR probabilite_pluie BETWEEN 0 AND 1)',
        'CHECK (evapotranspiration_mm IS NULL OR evapotranspiration_mm >= 0)',
        'CHECK (heures_ensoleillement IS NULL OR heures_ensoleillement BETWEEN 0 AND 24)',
        'UNIQUE (latitude, longitude, date, type)',
      ];
}

@DataClassName('ParametreRow')
class Parametres extends Table {
  TextColumn get cle => text()();
  TextColumn get valeur => text()();
  TextColumn get type => text()();
  TextColumn get description => text().nullable()();
  TextColumn get dateCreation => text()();
  TextColumn get dateModification => text()();

  @override
  Set<Column> get primaryKey => {cle};

  @override
  List<String> get customConstraints => [
        "CHECK (type IN ('booleen','entier','decimal','texte','json'))",
      ];
}

@DataClassName('FichePlantePersonnelleRow')
class FichesPlantesPersonnelles extends Table {
  TextColumn get id => text()();
  TextColumn get idFiche => text().unique()();
  TextColumn get yamlContenu => text()();
  IntColumn get schemaVersion => integer()();
  TextColumn get categorie => text()();
  TextColumn get sousType => text().nullable()();
  TextColumn get usages => text().withDefault(const Constant('[]'))(); // JSON
  TextColumn get nomCommunFr => text().nullable()();
  TextColumn get nomCommunEn => text().nullable()();
  TextColumn get familleBotanique => text().nullable()();
  TextColumn get dateCreation => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        "CHECK (categorie IN ('legume','aromatique','fruit','petit_fruit','fleur','cereale','engrais_vert'))",
      ];
}

@DataClassName('PreferencesRow')
class Preferences extends Table {
  TextColumn get id => text().withDefault(const Constant('singleton'))();
  TextColumn get langue => text().withDefault(const Constant('auto'))();
  TextColumn get theme => text().withDefault(const Constant('auto'))();
  TextColumn get systemeUnites =>
      text().withDefault(const Constant('metrique'))();
  TextColumn get sensSwipe => text().withDefault(const Constant('standard'))();
  TextColumn get niveauExperience =>
      text().withDefault(const Constant('debutant'))();
  TextColumn get modeGeolocalisation =>
      text().withDefault(const Constant('desactivee'))();
  BoolColumn get notificationsGlobalesActives =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get syncLocaleActive =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get communauteOptIn =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get calendrierLunaireOptIn =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get aideContextuelleActive =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get aideDocCompleteActive =>
      boolean().withDefault(const Constant(true))();
  TextColumn get notificationsParCategorie =>
      text().withDefault(const Constant('{}'))(); // JSON
  // ADR-0011 — association weighting profile, JSON {familleEffet: poids}.
  TextColumn get ponderationAssociations =>
      text().withDefault(const Constant('{}'))(); // JSON
  TextColumn get nePasDerangerDebut => text().nullable()();
  TextColumn get nePasDerangerFin => text().nullable()();
  BoolColumn get onboardingTermine =>
      boolean().withDefault(const Constant(false))();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  TextColumn get derniereModification => text()();
  // ADR-0009 — multi-garden active-selection (v4→v5); null = no explicit
  // choice yet, the repository falls back to the earliest-created garden.
  TextColumn get potagerActifId => text().nullable()();
  // Automatic weather fetching (v5→v6). When false, no coordinates leave the
  // device for Open-Meteo; a manual position still drives local season/climate
  // derivation and the watering engine still advises from plant needs alone.
  BoolColumn get meteoAutoActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        "CHECK (id = 'singleton')",
        "CHECK (langue IN ('auto','fr','en'))",
        "CHECK (theme IN ('auto','clair','sombre'))",
        "CHECK (systeme_unites IN ('metrique','imperial'))",
        "CHECK (sens_swipe IN ('standard','inverse'))",
        "CHECK (niveau_experience IN ('debutant','intermediaire','expert'))",
        "CHECK (mode_geolocalisation IN ('desactivee','manuelle','gps'))",
        '''CHECK ((ne_pas_deranger_debut IS NULL AND ne_pas_deranger_fin IS NULL) OR (ne_pas_deranger_debut IS NOT NULL AND ne_pas_deranger_fin IS NOT NULL))''',
      ];
}
