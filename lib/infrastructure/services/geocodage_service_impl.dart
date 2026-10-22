import '../../domain/repositories/abstract_geocodage_service.dart';
import '../../domain/value_objects/lieu_trouve.dart';
import '../../domain/value_objects/localisation.dart';
import '../api/nominatim_client.dart';

/// Nominatim-backed implementation of [AbstractGeocodageService].
///
/// Delegates entirely to [NominatimClient]; no cache at this layer (the
/// Riverpod provider that wraps this service caches the result for the
/// session lifetime, which is appropriate — a garden's locality never changes
/// during a session).
class GeocodageServiceImpl implements AbstractGeocodageService {
  final NominatimClient _client;

  const GeocodageServiceImpl(this._client);

  @override
  Future<String?> obtenirNomLocalite(Localisation loc) =>
      _client.obtenirNomLocalite(loc);

  @override
  Future<LieuTrouve?> identifierLieu(double latitude, double longitude) =>
      _client.identifierLieu(latitude, longitude);

  @override
  Future<List<LieuTrouve>> rechercherLieux(String texte) =>
      _client.rechercherLieux(texte);
}
