import 'package:pot_a_gerer/app/composition.dart';
import 'package:pot_a_gerer/application/providers/service_providers.dart';
import 'package:pot_a_gerer/domain/enums/permission_localisation.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_geolocalisation_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_info_application_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_notification_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_ouverture_lien_service.dart';
import 'package:pot_a_gerer/domain/exceptions/geolocalisation_indisponible_exception.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/notification_locale.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/presentation/services/gestionnaire_sauvegarde_fichier.dart';
import 'package:riverpod/misc.dart';

/// Records the scheduled notifications instead of talking to the OS.
class FauxNotificationService implements AbstractNotificationService {
  final List<NotificationLocale> _programmees = [];

  List<NotificationLocale> get programmees => List.unmodifiable(_programmees);

  @override
  Future<void> programmer(NotificationLocale notif) async {
    _programmees.removeWhere((n) => n.id == notif.id);
    _programmees.add(notif);
  }

  @override
  Future<void> annuler(String id) async =>
      _programmees.removeWhere((n) => n.id == id);

  @override
  Future<bool> sontAutorisees() async => true;
}

/// Fixed position, or a refusal.
class FauxGeolocalisationService implements AbstractGeolocalisationService {
  final Localisation? _position;

  /// Grants permission and returns [position].
  FauxGeolocalisationService(Localisation position) : _position = position;

  /// Denies permission; reading the position fails.
  FauxGeolocalisationService.refus() : _position = null;

  @override
  Future<bool> serviceActif() async => _position != null;

  @override
  Future<PermissionLocalisation> permission() async => _position != null
      ? PermissionLocalisation.accordee
      : PermissionLocalisation.refusee;

  @override
  Future<PermissionLocalisation> demanderPermission() => permission();

  @override
  Future<Localisation> positionActuelle() async =>
      _position ??
      (throw GeolocalisationIndisponibleException('Permission denied.'));
}

/// In-memory stand-in for the share sheet and the file picker.
class FauxGestionnaireSauvegardeFichier
    implements AbstractGestionnaireSauvegardeFichier {
  /// Content of the last shared document.
  String? dernierPartage;

  /// Name of the last shared document.
  String? dernierNomFichier;

  /// Content returned by [choisirEtLire]; `null` simulates a cancel.
  String? aLire;

  @override
  Future<void> partager(String contenu, String nomFichier) async {
    dernierPartage = contenu;
    dernierNomFichier = nomFichier;
  }

  @override
  Future<String?> choisirEtLire() async => aLire;
}

class _FauxInfoApplicationService implements AbstractInfoApplicationService {
  @override
  Future<String> obtenirVersionAffichee() async => '0.0.0-test';
}

class _FauxOuvertureLienService implements AbstractOuvertureLienService {
  @override
  Future<bool> ouvrir(Uri url) async => true;
}

final Set<Object> _natifs = {
  notificationServiceProvider,
  geolocalisationServiceProvider,
  gestionnaireSauvegardeFichierProvider,
  infoApplicationServiceProvider,
  ouvertureLienServiceProvider,
};

/// Overrides wiring the real implementations on [base] and replacing every
/// platform-bound service with a fake.
List<Override> surchargesDeTest(
  AppDatabase base, {
  FauxNotificationService? notifications,
  FauxGeolocalisationService? geoloc,
  FauxGestionnaireSauvegardeFichier? fichiers,
}) => [
  ...Composition.surcharges(base).where((o) => !_natifs.contains(o.origin)),
  notificationServiceProvider.overrideWithValue(
    notifications ?? FauxNotificationService(),
  ),
  geolocalisationServiceProvider.overrideWithValue(
    geoloc ?? FauxGeolocalisationService.refus(),
  ),
  gestionnaireSauvegardeFichierProvider.overrideWithValue(
    fichiers ?? FauxGestionnaireSauvegardeFichier(),
  ),
  infoApplicationServiceProvider.overrideWithValue(
    _FauxInfoApplicationService(),
  ),
  ouvertureLienServiceProvider.overrideWithValue(_FauxOuvertureLienService()),
];
