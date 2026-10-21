import 'dart:math' as math;

import 'package:riverpod/riverpod.dart';

import '../../core/constants/constantes_moteur.dart';
import '../../domain/value_objects/prevision_horaire.dart';
import '../../domain/value_objects/prevision_meteo.dart';
import '../engine/generateur_resume_meteo.dart';
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';
import 'jour_meteo_vue.dart';
import 'meteo_accueil_notifier.dart';
import 'meteo_detail_vue.dart';
import 'preferences_notifier.dart';

// ── Rich view-model provider (ADR-0016 Lot 3) ────────────────────────────────

/// Full weather detail view-model for [EcranMeteoDetail].
///
/// Fetches all five data sources in parallel, derives the watering verdict,
/// and pre-generates the French summary texts. Returns
/// [MeteoDetailVue.indisponible] — never throws — when no position is set, and
/// [MeteoDetailVue.desactivee] without any call when auto weather is opted out.
final meteoDetailProvider = FutureProvider<MeteoDetailVue>((ref) async {
  final potagerRepo = ref.watch(potagerRepositoryProvider);
  final meteo = ref.watch(meteoServiceProvider);
  final geocodage = ref.watch(geocodageServiceProvider);
  final prefs = await ref.watch(preferencesProvider.future);

  final potager = await potagerRepo.obtenirPotagerActif();

  if (!prefs.meteoAutoActive) {
    return MeteoDetailVue.desactivee(nomPotager: potager?.nom ?? '');
  }

  if (potager == null || !potager.localisation.estDefinie) {
    return MeteoDetailVue.indisponible(nomPotager: potager?.nom ?? '');
  }

  final loc = potager.localisation;

  // Start all five fetches concurrently.
  final nomVilleFuture = geocodage.obtenirNomLocalite(loc);
  final elevationFuture = meteo.obtenirElevation(loc);
  final actuelleFuture = meteo.obtenirMeteoActuelle(loc);
  final previsionsFuture = meteo.obtenirPrevisions(loc, 3);
  final horairesFuture = meteo.obtenirPrevisionsHoraires(loc, nbJours: 3);

  // Waits for all of them, so a second failure is not left unhandled.
  await Future.wait<Object?>([
    nomVilleFuture,
    elevationFuture,
    actuelleFuture,
    previsionsFuture,
    horairesFuture,
  ]);
  final nomVille = await nomVilleFuture;
  final elevation = await elevationFuture;
  final actuelle = await actuelleFuture;
  final previsions = await previsionsFuture;
  final horaires = await horairesFuture;

  final verdict = MeteoAccueilNotifier.deriverVerdict(actuelle, previsions);
  final jours = _construireJours(previsions, horaires);

  if (jours.isEmpty) {
    return MeteoDetailVue.indisponible(nomPotager: potager.nom);
  }

  const gen = GenerateurResumeMeteo();

  return MeteoDetailVue.disponible(
    nomPotager: potager.nom,
    nomStation: nomVille,
    elevation: elevation,
    derniereMaj: DateTime.now(),
    jours: jours,
    verdictArrosage: verdict,
    resumeAujourdhui: gen.resumeJour(jours.first),
    resumeDemain: jours.length > 1 ? gen.resumeDemain(jours[1]) : null,
    explicationTaches: gen.explicationTaches(verdict),
  );
});

// ── Private helpers ───────────────────────────────────────────────────────────

/// Groups hourly forecasts by calendar day and combines them with daily
/// [PrevisionMeteo] entries to produce [JourMeteoVue] items.
List<JourMeteoVue> _construireJours(
  List<PrevisionMeteo> previsions,
  List<PrevisionHoraire> horaires,
) {
  // Index hourly data by calendar day (year/month/day).
  final heuresParJour = <DateTime, List<PrevisionHoraire>>{};
  for (final h in horaires) {
    final jour = DateTime(h.heure.year, h.heure.month, h.heure.day);
    (heuresParJour[jour] ??= []).add(h);
  }

  return previsions.map((p) {
    final clef = DateTime(p.date.year, p.date.month, p.date.day);
    final heures = List<PrevisionHoraire>.unmodifiable(
      heuresParJour[clef] ?? const <PrevisionHoraire>[],
    );
    final ventMax = heures.isEmpty
        ? 0.0
        : heures.map((h) => h.ventKmh).reduce(math.max);

    return JourMeteoVue(
      date: p.date,
      tempMin: p.tempMin,
      tempMax: p.tempMax,
      precipitationsMm: p.precipitationsMm,
      probabilitePluie: p.probabilitePluie,
      weathercode: p.weathercode,
      risqueGel: p.tempMin <= SeuilsMeteo.gelC,
      risqueCanicule: p.tempMax >= SeuilsMeteo.caniculeC,
      ventMaxKmh: ventMax,
      heures: heures,
    );
  }).toList();
}
