/// Contract for reading the running app's version at runtime.
///
/// Backed by `package_info_plus` in the infrastructure layer — reads the
/// platform's own package metadata, no network involved. See
/// `docs/15-elements-differes.md` §6 ("Version dynamique").
abstract class AbstractInfoApplicationService {
  /// The app's displayed version, mirroring `pubspec.yaml`'s `version:` field
  /// (`1.0.0`, or `1.0.0+1` when a build number is reported).
  Future<String> obtenirVersionAffichee();
}
