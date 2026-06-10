import 'package:drift/drift.dart';

import '../../domain/exceptions/meteo_indisponible_exception.dart';
import '../../domain/repositories/abstract_meteo_service.dart';
import '../../domain/value_objects/donnees_meteo.dart';
import '../../domain/value_objects/localisation.dart';
import '../../domain/value_objects/prevision_horaire.dart';
import '../../domain/value_objects/prevision_meteo.dart';
import '../api/open_meteo_client.dart';
import '../database/app_database.dart';
import '../mappers/meteo_cache_mapper.dart';

/// drift- and Open-Meteo-backed implementation of [AbstractMeteoService].
///
/// Strategy is **cache-aside with a degraded offline fallback**:
/// 1. fresh data in `meteo_cache` → served without any network call;
/// 2. otherwise the network is queried, and the result is written to the cache;
/// 3. if the network call fails but stale cache data exists → the stale data is
///    served (degraded mode — the app keeps working offline, see
///    `docs/12-internationalisation-et-donnees.md`);
/// 4. if nothing is cached and the network fails → [MeteoIndisponibleException].
///
/// Freshness is instant-based (timezone-agnostic). Past forecasts are purged
/// beyond [retentionPrevuJours] days. The clock is injectable for testing.
class MeteoServiceImpl implements AbstractMeteoService {
  /// Observed weather is considered fresh for this long after fetch.
  static const Duration fraicheurMeteoActuelle = Duration(hours: 1);

  /// A forecast is considered fresh for this long after fetch.
  static const Duration fraicheurPrevisions = Duration(hours: 3);

  /// Past forecast rows older than this many days are purged from the cache.
  static const int retentionPrevuJours = 7;

  final AppDatabase _db;
  final OpenMeteoClient _client;
  final MeteoCacheMapper _mapper = const MeteoCacheMapper();
  final DateTime Function() _clock;

  MeteoServiceImpl(
    this._db,
    this._client, {
    this._clock = DateTime.now,
  });

  @override
  Future<DonneesMeteo> obtenirMeteoActuelle(Localisation loc) async {
    if (!loc.estDefinie) {
      throw MeteoIndisponibleException(
        'Cannot fetch weather: location is undefined (geolocation opt-out).',
      );
    }
    final now = _clock();
    final dateJour = _dateStr(now);
    final cached = await _lireObserve(loc, dateJour);

    if (cached != null && _estFrais(cached.dateRecuperation, fraicheurMeteoActuelle)) {
      return _mapper.versDonneesMeteo(cached);
    }

    try {
      final meteo = await _client.obtenirMeteoActuelle(loc);
      await _db.into(_db.meteoCache).insert(
            _mapper.versCompanionObserve(
              meteo,
              latitude: loc.latitude!,
              longitude: loc.longitude!,
              date: dateJour,
              dateRecuperation: _nowIso(now),
            ),
            mode: InsertMode.insertOrReplace,
          );
      return meteo;
    } on MeteoIndisponibleException {
      // Degraded fallback: serve stale cache if we have any.
      if (cached != null) return _mapper.versDonneesMeteo(cached);
      rethrow;
    }
  }

  @override
  Future<List<PrevisionMeteo>> obtenirPrevisions(
    Localisation loc,
    int nbJours, {
    int joursPasses = 0,
  }) async {
    if (!loc.estDefinie) {
      throw MeteoIndisponibleException(
        'Cannot fetch weather: location is undefined (geolocation opt-out).',
      );
    }
    if (joursPasses > 0) {
      return _obtenirFenetre(loc, nbJours, joursPasses);
    }

    final now = _clock();
    final cached = await _lirePrevu(loc, _dateStr(now), nbJours);

    final cacheUtilisable = cached.length >= nbJours &&
        _estFrais(cached.first.dateRecuperation, fraicheurPrevisions);
    if (cacheUtilisable) {
      return cached.map(_mapper.versPrevisionMeteo).toList();
    }

    try {
      final previsions = await _client.obtenirPrevisions(loc, nbJours);
      await _cacherTout(loc, previsions, now);
      await _purgerCachePasse(now);
      return previsions;
    } on MeteoIndisponibleException {
      // Degraded fallback: serve whatever (possibly stale) forecast we cached.
      if (cached.isNotEmpty) {
        return cached.map(_mapper.versPrevisionMeteo).toList();
      }
      rethrow;
    }
  }

  @override
  Future<List<PrevisionHoraire>> obtenirPrevisionsHoraires(
    Localisation loc, {
    int nbJours = 3,
  }) {
    // Not cached: the detail view is opened on demand and wants live hourly data.
    return _client.obtenirPrevisionsHoraires(loc, nbJours: nbJours);
  }

  /// Window mode (`joursPasses > 0`): a single Open-Meteo call returns the past
  /// + forecast days. Always fetched fresh (the watering engine wants accurate
  /// recent precipitation); the result is cached best-effort, and on a network
  /// failure the matching cached window (any freshness) is served instead.
  Future<List<PrevisionMeteo>> _obtenirFenetre(
    Localisation loc,
    int nbJours,
    int joursPasses,
  ) async {
    final now = _clock();
    try {
      final fenetre =
          await _client.obtenirPrevisions(loc, nbJours, joursPasses: joursPasses);
      await _cacherTout(loc, fenetre, now);
      await _purgerCachePasse(now);
      return fenetre;
    } on MeteoIndisponibleException {
      final debut = _dateStr(DateTime(now.year, now.month, now.day - joursPasses));
      final fin = _dateStr(DateTime(now.year, now.month, now.day + nbJours - 1));
      final caches = await _lireFenetre(loc, debut, fin);
      if (caches.isNotEmpty) {
        return caches.map(_mapper.versPrevisionMeteo).toList();
      }
      rethrow;
    }
  }

  /// Upserts every [PrevisionMeteo] of a result (each tagged observe/prevu by
  /// its own type) into the cache.
  Future<void> _cacherTout(
    Localisation loc,
    List<PrevisionMeteo> previsions,
    DateTime now,
  ) {
    return _db.batch((b) {
      for (final p in previsions) {
        b.insert(
          _db.meteoCache,
          _mapper.versCompanionPrevu(
            p,
            latitude: loc.latitude!,
            longitude: loc.longitude!,
            date: _dateStr(p.date),
            dateRecuperation: _nowIso(now),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Reads the cached observed-weather row for [loc] on [dateJour], or `null`.
  Future<MeteoCacheRow?> _lireObserve(Localisation loc, String dateJour) {
    return (_db.select(_db.meteoCache)
          ..where((t) =>
              t.latitude.equals(loc.latitude!) &
              t.longitude.equals(loc.longitude!) &
              t.date.equals(dateJour) &
              t.type.equals('observe')))
        .getSingleOrNull();
  }

  /// Reads up to [nbJours] cached forecast rows for [loc] from [dateJour]
  /// onward, ordered by date ascending.
  Future<List<MeteoCacheRow>> _lirePrevu(
    Localisation loc,
    String dateJour,
    int nbJours,
  ) {
    return (_db.select(_db.meteoCache)
          ..where((t) =>
              t.latitude.equals(loc.latitude!) &
              t.longitude.equals(loc.longitude!) &
              t.type.equals('prevu') &
              t.date.isBiggerOrEqualValue(dateJour))
          ..orderBy([(t) => OrderingTerm.asc(t.date)])
          ..limit(nbJours))
        .get();
  }

  /// Reads cached rows (any type) for [loc] whose day is within `[debut, fin]`,
  /// ordered by date ascending.
  Future<List<MeteoCacheRow>> _lireFenetre(
    Localisation loc,
    String debut,
    String fin,
  ) {
    return (_db.select(_db.meteoCache)
          ..where((t) =>
              t.latitude.equals(loc.latitude!) &
              t.longitude.equals(loc.longitude!) &
              t.date.isBiggerOrEqualValue(debut) &
              t.date.isSmallerOrEqualValue(fin))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  /// Deletes any cached row (forecast or past observation) whose day is older
  /// than [retentionPrevuJours] days — bounds cache growth.
  Future<void> _purgerCachePasse(DateTime now) async {
    final limite = _dateStr(DateTime(
      now.year,
      now.month,
      now.day - retentionPrevuJours,
    ));
    await (_db.delete(_db.meteoCache)
          ..where((t) => t.date.isSmallerThanValue(limite)))
        .go();
  }

  /// Whether a recorded UTC fetch instant is within [ttl] of now.
  bool _estFrais(String dateRecuperationIso, Duration ttl) {
    final fetched = DateTime.parse(dateRecuperationIso);
    return _clock().toUtc().difference(fetched.toUtc()) < ttl;
  }

  String _nowIso(DateTime now) => now.toUtc().toIso8601String();

  /// Formats the local calendar date of [d] as `YYYY-MM-DD`.
  String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
