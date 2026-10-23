/// Contract for reading the privacy policy embedded in the app.
abstract class AbstractPolitiqueConfidentialiteSource {
  /// The policy's Markdown text for [codeLangue] (English for `en`, French
  /// otherwise).
  Future<String> lire(String codeLangue);
}
