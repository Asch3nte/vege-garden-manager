/// Base class for all typed business exceptions of the domain.
///
/// Every domain error is a subtype of [PotagerException]: the code never throws a
/// generic `Exception('...')`. The [message] is developer-facing and written in
/// English; user-facing messages are localised separately at the presentation
/// layer.
///
/// See `docs/05-modele-de-domaine.md` §8.
abstract class PotagerException implements Exception {
  /// Developer-facing description of the error (English).
  final String message;

  const PotagerException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}
