import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

import '../application/providers/langue_provider.dart';
import '../application/providers/repository_providers.dart';
import '../application/providers/service_providers.dart';
import '../application/state/journal_erreurs_chargement.dart';
import '../infrastructure/api/nominatim_client.dart';
import '../infrastructure/api/open_meteo_client.dart';
import '../infrastructure/catalogue/bioagresseur_asset_source.dart';
import '../infrastructure/catalogue/bioagresseur_cache.dart';
import '../infrastructure/catalogue/bioagresseurs_loader.dart';
import '../infrastructure/catalogue/catalogue_loader.dart';
import '../infrastructure/catalogue/famille_asset_source.dart';
import '../infrastructure/catalogue/famille_botanique_cache.dart';
import '../infrastructure/catalogue/familles_loader.dart';
import '../infrastructure/catalogue/fiche_asset_source.dart';
import '../infrastructure/catalogue/fiche_plante_cache.dart';
import '../infrastructure/catalogue/fiches_personnelles_loader.dart';
import '../infrastructure/database/app_database.dart';
import '../infrastructure/repositories/bioagresseur_repository_impl.dart';
import '../infrastructure/repositories/equipement_repository_impl.dart';
import '../infrastructure/repositories/famille_botanique_repository_impl.dart';
import '../infrastructure/repositories/fiche_plante_personnelle_repository_impl.dart';
import '../infrastructure/repositories/fiche_plante_repository_impl.dart';
import '../infrastructure/repositories/meteo_service_impl.dart';
import '../infrastructure/repositories/observation_repository_impl.dart';
import '../infrastructure/repositories/parcelle_repository_impl.dart';
import '../infrastructure/repositories/plantation_repository_impl.dart';
import '../infrastructure/repositories/potager_repository_impl.dart';
import '../infrastructure/repositories/preferences_repository_impl.dart';
import '../infrastructure/repositories/rappel_repository_impl.dart';
import '../infrastructure/repositories/recolte_repository_impl.dart';
import '../infrastructure/repositories/tache_repository_impl.dart';
import '../infrastructure/services/geocodage_service_impl.dart';
import '../infrastructure/services/geolocalisation_service_impl.dart';
import '../infrastructure/services/info_application_service_impl.dart';
import '../infrastructure/services/notification_service_impl.dart';
import '../infrastructure/services/ouverture_lien_service_impl.dart';
import '../infrastructure/services/reinitialisation_service_impl.dart';
import '../infrastructure/services/sauvegarde_service_impl.dart';
import '../infrastructure/services/statistiques_donnees_service_impl.dart';
import 'textes_notifications_arb.dart';

/// Source of the embedded YAML plant sheets.
final ficheAssetSourceProvider =
    Provider<FicheAssetSource>((ref) => BundleFicheAssetSource());

/// Bundled plant sheets plus the user's own; personal sheets come last, so
/// they win on an id collision.
final fichePlanteCacheProvider = FutureProvider<FichePlanteCache>((ref) async {
  final embarquees = await CatalogueLoader(
    ref.watch(ficheAssetSourceProvider),
    ref.watch(journalErreursChargementProvider).signaler,
  ).charger();
  final personnelles =
      await ref.watch(fichesPersonnellesChargeesProvider.future);
  return FichePlanteCache([...embarquees.toutes(), ...personnelles]);
});

/// Botanical families loaded from the bundled assets.
final familleBotaniqueCacheProvider = FutureProvider<FamilleBotaniqueCache>(
  (ref) => FamillesLoader(
    BundleFamilleAssetSource(),
    ref.watch(journalErreursChargementProvider).signaler,
  ).charger(),
);

/// Bioaggressors loaded from the bundled reference.
final bioagresseurCacheProvider = FutureProvider<BioagresseurCache>(
  (ref) => BioagresseursLoader(
    BundleBioagresseurAssetSource(),
    ref.watch(journalErreursChargementProvider).signaler,
  ).charger(),
);

/// Composition root: binds every application port to its implementation.
class Composition {
  const Composition._();

  /// Overrides wiring the implementations on [base].
  static List<Override> surcharges(AppDatabase base) => [
        potagerRepositoryProvider
            .overrideWith((ref) => PotagerRepositoryImpl(base)),
        parcelleRepositoryProvider
            .overrideWith((ref) => ParcelleRepositoryImpl(base)),
        plantationRepositoryProvider
            .overrideWith((ref) => PlantationRepositoryImpl(base)),
        recolteRepositoryProvider
            .overrideWith((ref) => RecolteRepositoryImpl(base)),
        observationRepositoryProvider
            .overrideWith((ref) => ObservationRepositoryImpl(base)),
        equipementRepositoryProvider
            .overrideWith((ref) => EquipementRepositoryImpl(base)),
        tacheRepositoryProvider.overrideWith((ref) => TacheRepositoryImpl(base)),
        fichePlantePersonnelleRepositoryProvider
            .overrideWith((ref) => FichePlantePersonnelleRepositoryImpl(base)),
        rappelRepositoryProvider
            .overrideWith((ref) => RappelRepositoryImpl(base)),
        preferencesRepositoryProvider
            .overrideWith((ref) => PreferencesRepositoryImpl(base)),
        fichesPersonnellesChargeesProvider.overrideWith(
          (ref) => FichesPersonnellesLoader(
            ref.watch(fichePlantePersonnelleRepositoryProvider),
            ref.watch(journalErreursChargementProvider).signaler,
          ).charger(),
        ),
        fichePlanteRepositoryProvider.overrideWith((ref) async =>
            FichePlanteRepositoryImpl(
                await ref.watch(fichePlanteCacheProvider.future))),
        familleBotaniqueRepositoryProvider.overrideWith((ref) async =>
            FamilleBotaniqueRepositoryImpl(
                await ref.watch(familleBotaniqueCacheProvider.future))),
        bioagresseurRepositoryProvider.overrideWith((ref) async =>
            BioagresseurRepositoryImpl(
                await ref.watch(bioagresseurCacheProvider.future))),
        geocodageServiceProvider
            .overrideWith((ref) => GeocodageServiceImpl(NominatimClient())),
        meteoServiceProvider
            .overrideWith((ref) => MeteoServiceImpl(base, OpenMeteoClient())),
        notificationServiceProvider.overrideWith((ref) =>
            NotificationServiceImpl(FlutterLocalNotificationsPlugin())),
        textesNotificationsProvider.overrideWith(
            (ref) => TextesNotificationsArb(() => ref.read(codeLangueProvider))),
        geolocalisationServiceProvider
            .overrideWith((ref) => GeolocalisationServiceImpl()),
        sauvegardeServiceProvider
            .overrideWith((ref) => SauvegardeServiceImpl(base)),
        reinitialisationServiceProvider
            .overrideWith((ref) => ReinitialisationServiceImpl(base)),
        statistiquesDonneesServiceProvider
            .overrideWith((ref) => StatistiquesDonneesServiceImpl(base)),
        infoApplicationServiceProvider
            .overrideWith((ref) => InfoApplicationServiceImpl()),
        ouvertureLienServiceProvider
            .overrideWith((ref) => OuvertureLienServiceImpl()),
      ];
}
