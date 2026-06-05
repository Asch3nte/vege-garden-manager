import '../value_objects/surface.dart';
import 'potager_exception.dart';

/// Thrown when an active plantation would need more room than a parcelle still
/// has free.
///
/// See `docs/05-modele-de-domaine.md` §8.
class SurfaceInsuffisanteException extends PotagerException {
  /// Surface the operation requires.
  final Surface requise;

  /// Surface still available on the parcelle.
  final Surface disponible;

  SurfaceInsuffisanteException(this.requise, this.disponible)
      : super(
          'Required surface ($requise) exceeds the available surface '
          '($disponible).',
        );
}
