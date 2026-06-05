import '../value_objects/appareil_decouvert.dart';

/// Contract for local-network (WiFi) synchronisation — discovery and pairing.
/// Implemented over sockets/mDNS in the infrastructure layer; opt-out and
/// disabled by default.
///
/// See `docs/05-modele-de-domaine.md` §7.
abstract class AbstractSyncService {
  /// Starts discovering devices on the local network.
  Future<void> demarrerDecouverte();

  /// Stops discovery.
  Future<void> arreter();

  /// Stream of devices discovered on the local network.
  Stream<AppareilDecouvert> get appareilsDecouverts;

  /// Synchronises with a discovered [appareil].
  Future<void> synchroniserAvec(AppareilDecouvert appareil);
}
