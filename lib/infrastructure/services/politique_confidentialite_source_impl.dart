import 'package:flutter/services.dart';

import '../../domain/repositories/abstract_politique_confidentialite_source.dart';

/// Reads the policy from the `docs/` files bundled as assets.
class PolitiqueConfidentialiteSourceImpl
    implements AbstractPolitiqueConfidentialiteSource {
  final AssetBundle _bundle;

  PolitiqueConfidentialiteSourceImpl([AssetBundle? bundle])
      : _bundle = bundle ?? rootBundle;

  /// Asset path of the policy for [codeLangue].
  static String chemin(String codeLangue) =>
      'docs/politique-confidentialite${codeLangue == 'en' ? '.en' : ''}.md';

  @override
  Future<String> lire(String codeLangue) =>
      _bundle.loadString(chemin(codeLangue));
}
