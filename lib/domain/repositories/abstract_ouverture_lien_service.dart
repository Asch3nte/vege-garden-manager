/// Contract for opening an external link in the platform's default handler
/// (browser, mail client…).
///
/// Backed by `url_launcher` in the infrastructure layer. Opening a link always
/// leaves the app — no data is sent by Pot'à Gérer itself. See
/// `docs/15-elements-differes.md` §6 ("Liens externes").
abstract class AbstractOuvertureLienService {
  /// Opens [url] externally. Returns `false` (rather than throwing) when no
  /// handler is available on the platform, so callers can show a fallback
  /// message instead of crashing.
  Future<bool> ouvrir(Uri url);
}
