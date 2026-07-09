import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../domain/value_objects/inventaire_donnees.dart';

/// Loads the local-data inventory on demand for the transparency section.
///
/// Auto-disposed so it is re-counted each time the panel is opened (the figures
/// must reflect the live database, e.g. after an import or a reset).
final inventaireDonneesProvider =
    FutureProvider.autoDispose<InventaireDonnees>(
  (ref) => ref.watch(inventaireDonneesServiceProvider).obtenir(),
);
