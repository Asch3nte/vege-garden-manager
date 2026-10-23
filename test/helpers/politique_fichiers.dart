import 'dart:io';

import 'package:pot_a_gerer/domain/repositories/abstract_politique_confidentialite_source.dart';
import 'package:pot_a_gerer/infrastructure/services/politique_confidentialite_source_impl.dart';

/// Reads the policy files synchronously: the asset bundle's real I/O never
/// completes under the widget-test clock.
class PolitiqueDepuisFichiers implements AbstractPolitiqueConfidentialiteSource {
  @override
  Future<String> lire(String codeLangue) async =>
      File(PolitiqueConfidentialiteSourceImpl.chemin(codeLangue))
          .readAsStringSync();
}
