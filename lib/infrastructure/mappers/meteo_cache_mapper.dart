import 'package:drift/drift.dart';

import '../../domain/enums/type_releve_meteo.dart';
import '../../domain/value_objects/donnees_meteo.dart';
import '../../domain/value_objects/prevision_meteo.dart';
import '../database/app_database.dart';

/// Maps weather DTOs to and from their drift cache row ([MeteoCacheRow]).
///
/// One cache row holds the weather of one day at one location, tagged by
/// [TypeReleveMeteo]: observed conditions ([DonneesMeteo], `observe`) or a
/// forecast ([PrevisionMeteo], `prevu`).
///
/// The row primary key is a **deterministic** id derived from
/// `(latitude, longitude, date, type)`, so it always coincides with the table's
/// `UNIQUE (latitude, longitude, date, type)` constraint. Writing with
/// `insertOnConflictUpdate` therefore upserts the matching day in place rather
/// than accumulating duplicates.
///
/// Every DTO field a forecast carries is persisted, including
/// [PrevisionMeteo.probabilitePluie], so a forecast rebuilt from the cache
/// (degraded offline fallback) keeps the rain probability and the watering
/// engine can still reason offline. (The columns `heures_ensoleillement` /
/// `vent_direction` exist in the schema but are not yet produced by the DTOs
/// and stay null.)
class MeteoCacheMapper {
  const MeteoCacheMapper();

  /// Builds the deterministic cache id for a day/location/type tuple.
  String cacheId(
    double latitude,
    double longitude,
    String date,
    TypeReleveMeteo type,
  ) =>
      '$latitude:$longitude:$date:${type.name}';

  /// Companion for an observed-weather row (`type = observe`).
  ///
  /// [date] is the `YYYY-MM-DD` day the data describes; [dateRecuperation] is
  /// the ISO-8601 UTC instant the data was fetched (used for freshness checks).
  MeteoCacheCompanion versCompanionObserve(
    DonneesMeteo d, {
    required double latitude,
    required double longitude,
    required String date,
    required String dateRecuperation,
  }) {
    return MeteoCacheCompanion(
      id: Value(cacheId(latitude, longitude, date, TypeReleveMeteo.observe)),
      latitude: Value(latitude),
      longitude: Value(longitude),
      date: Value(date),
      type: Value(TypeReleveMeteo.observe.name),
      tempMin: Value(d.tempMin),
      tempMax: Value(d.tempMax),
      tempMoyenne: Value(d.tempMoyenne),
      precipitationsMm: Value(d.precipitationsMm),
      ventVitesseMax: Value(d.ventVitesseMax),
      risqueGel: Value(d.risqueGel),
      risqueCanicule: Value(d.risqueCanicule),
      dateRecuperation: Value(dateRecuperation),
    );
  }

  /// Companion for a forecast row (`type = prevu`).
  MeteoCacheCompanion versCompanionPrevu(
    PrevisionMeteo p, {
    required double latitude,
    required double longitude,
    required String date,
    required String dateRecuperation,
  }) {
    return MeteoCacheCompanion(
      id: Value(cacheId(latitude, longitude, date, TypeReleveMeteo.prevu)),
      latitude: Value(latitude),
      longitude: Value(longitude),
      date: Value(date),
      type: Value(TypeReleveMeteo.prevu.name),
      tempMin: Value(p.tempMin),
      tempMax: Value(p.tempMax),
      precipitationsMm: Value(p.precipitationsMm),
      probabilitePluie: Value(p.probabilitePluie),
      dateRecuperation: Value(dateRecuperation),
    );
  }

  /// Rebuilds the observed-weather DTO from a cache row (`type = observe`).
  DonneesMeteo versDonneesMeteo(MeteoCacheRow r) {
    return DonneesMeteo(
      date: DateTime.parse(r.date),
      tempMin: r.tempMin ?? 0,
      tempMax: r.tempMax ?? 0,
      tempMoyenne: r.tempMoyenne ?? ((r.tempMin ?? 0) + (r.tempMax ?? 0)) / 2,
      precipitationsMm: r.precipitationsMm ?? 0,
      ventVitesseMax: r.ventVitesseMax ?? 0,
      risqueGel: r.risqueGel,
      risqueCanicule: r.risqueCanicule,
    );
  }

  /// Rebuilds the forecast DTO from a cache row (`type = prevu`).
  PrevisionMeteo versPrevisionMeteo(MeteoCacheRow r) {
    return PrevisionMeteo(
      date: DateTime.parse(r.date),
      tempMin: r.tempMin ?? 0,
      tempMax: r.tempMax ?? 0,
      precipitationsMm: r.precipitationsMm ?? 0,
      probabilitePluie: r.probabilitePluie ?? 0,
    );
  }
}
